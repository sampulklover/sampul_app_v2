// @ts-nocheck
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import * as XLSX from "npm:xlsx@0.18.5";

function corsHeaders(extra: Record<string, string> = {}) {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    ...extra,
  };
}

function jsonResponse(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders({ "Content-Type": "application/json" }),
  });
}

type ImportRequest = {
  storageBucket: string; // e.g. 'attachments'
  storagePath: string; // path inside bucket
  name: string; // source name
  product?: string; // hibah/wasiat/executor/trust/general
  language?: string; // en/bm
  version?: string; // v1/v2
  replace?: boolean; // if true, replaces entries for this source
  dryRun?: boolean; // if true, only preview parsed rows (no DB writes)
  previewLimit?: number; // number of rows to return in preview
};

function parseQaFromContent(raw: string): { question?: string; answer: string } | null {
  const s = raw.replace(/\r\n/g, "\n").trim();
  if (!s) return null;

  // Expected pattern from your sheets:
  // Q: ...
  // A: ...
  const qMatch = s.match(/^\s*Q:\s*([\s\S]*?)(?:\n|$)/i);
  const aMatch = s.match(/\n\s*A:\s*([\s\S]*)$/i) ?? s.match(/^\s*A:\s*([\s\S]*)$/i);

  if (qMatch && aMatch) {
    return {
      question: qMatch[1].trim(),
      answer: aMatch[1].trim(),
    };
  }

  // If not clearly Q/A, treat everything as answer text.
  return { answer: s };
}

function parseSourceUri(sourceUri: string): { bucket: string; path: string } | null {
  const s = sourceUri.trim();
  if (!s) return null;
  const idx = s.indexOf("/");
  if (idx <= 0 || idx === s.length - 1) return null;
  return { bucket: s.slice(0, idx), path: s.slice(idx + 1) };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders() });
  if (req.method !== "POST") {
    return jsonResponse(405, { error: { message: "Method Not Allowed. Only POST is supported." } });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse(500, {
      error: { message: "Server configuration error", details: { has_url: !!supabaseUrl, has_service_key: !!serviceKey } },
    });
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceKey);

  // Authenticate user via Bearer token (must be logged in)
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice("Bearer ".length) : "";
  if (!token) return jsonResponse(401, { error: { message: "Missing bearer token" } });

  const { data: userData, error: userErr } = await supabaseAdmin.auth.getUser(token);
  if (userErr || !userData?.user) {
    return jsonResponse(401, { error: { message: "Invalid token", details: userErr?.message } });
  }

  // Basic admin check: must have a row in public.roles with role admin/marketing
  const { data: roleRow, error: roleErr } = await supabaseAdmin
    .from("roles")
    .select("role")
    .eq("uuid", userData.user.id)
    .maybeSingle();
  if (roleErr) return jsonResponse(500, { error: { message: "Role check failed", details: roleErr.message } });
  const role = (roleRow?.role ?? "").toString().trim().toLowerCase();
  if (role !== "admin" && role !== "marketing") {
    return jsonResponse(403, { error: { message: "Forbidden" } });
  }

  let payload: ImportRequest;
  try {
    payload = (await req.json()) as ImportRequest;
  } catch {
    return jsonResponse(400, { error: { message: "Invalid JSON body" } });
  }

  const storageBucket = (payload.storageBucket ?? "").trim();
  const storagePath = (payload.storagePath ?? "").trim();
  const name = (payload.name ?? "").trim();
  if (!storageBucket || !storagePath || !name) {
    return jsonResponse(400, { error: { message: "Missing required fields: storageBucket, storagePath, name" } });
  }

  const replace = payload.replace === true;
  const dryRun = payload.dryRun === true;
  const previewLimit = Math.max(1, Math.min(50, Number(payload.previewLimit ?? 10)));
  const product = payload.product?.trim() || null;
  const language = payload.language?.trim() || null;
  const version = payload.version?.trim() || null;

  // Download file from storage
  const { data: fileData, error: dlErr } = await supabaseAdmin.storage.from(storageBucket).download(storagePath);
  if (dlErr || !fileData) return jsonResponse(400, { error: { message: "Failed to download file", details: dlErr?.message } });

  const arr = new Uint8Array(await fileData.arrayBuffer());

  // Parse workbook
  // - For .xlsx: read as array
  // - For .csv: decode as text and read as string (more reliable on Edge)
  const isCsv = storagePath.toLowerCase().endsWith(".csv");
  let workbook: XLSX.WorkBook;
  try {
    if (isCsv) {
      const text = new TextDecoder().decode(arr);
      workbook = XLSX.read(text, { type: "string" });
    } else {
      workbook = XLSX.read(arr, { type: "array" });
    }
  } catch (e) {
    return jsonResponse(400, {
      error: { message: "Failed to parse file. Please upload a valid .xlsx or .csv template.", details: String(e) },
    });
  }

  // Preview accumulator (also used to count on import)
  const preview: Array<{
    sheet: string;
    row: number;
    category: string | null;
    product: string | null;
    language: string | null;
    question: string | null;
    answer: string;
  }> = [];

  let parsedEntries = 0;
  let parsedChunks = 0;
  let sourceId: string | null = null;
  let reusedSource = false;

  // For each sheet, expect columns: content | category | product | language
  for (const sheetName of workbook.SheetNames) {
    const sheet = workbook.Sheets[sheetName];
    if (!sheet) continue;

    const rows = XLSX.utils.sheet_to_json<Record<string, unknown>>(sheet, { defval: "" });
    if (!rows.length) continue;

    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];

      const content = (r["content"] ?? r["Content"] ?? "").toString();
      const categoryCell = (r["category"] ?? r["Category"] ?? "").toString().trim().toLowerCase() || null;
      const productCell = (r["product"] ?? r["Product"] ?? "").toString().trim().toLowerCase() || product;
      const languageCell = (r["language"] ?? r["Language"] ?? "").toString().trim().toLowerCase() || language;

      const parsed = parseQaFromContent(content);
      if (!parsed) continue;

      const question = parsed.question ?? null;
      const answer = parsed.answer;
      if (!answer.trim()) continue;

      parsedEntries++;
      parsedChunks++;

      const searchText = `${question ?? ""}\n${answer}`.trim();

      if (preview.length < previewLimit) {
        preview.push({
          sheet: sheetName,
          row: i + 1,
          category: categoryCell,
          product: productCell,
          language: languageCell,
          question,
          answer,
        });
      }

      // No DB writes during dry run
      if (dryRun) continue;

      // Create or reuse source once per request (only on real import)
      if (!sourceId) {
        if (replace) {
          // Replace means: reuse existing source row (same name+product+language+version) if it exists.
          let q = supabaseAdmin.from("ai_kb_sources").select("id, source_uri").eq("name", name).limit(1);
          q = product ? q.eq("product", product) : q.is("product", null);
          q = language ? q.eq("language", language) : q.is("language", null);
          q = version ? q.eq("version", version) : q.is("version", null);

          const { data: existing, error: exErr } = await q.maybeSingle();
          if (exErr) {
            return jsonResponse(500, { error: { message: "Failed to check existing source", details: exErr.message } });
          }

          if (existing?.id) {
            sourceId = existing.id as string;
            reusedSource = true;

            // Best-effort: remove old storage object if present and different
            const oldUri = (existing.source_uri ?? "").toString();
            const newUri = `${storageBucket}/${storagePath}`;
            if (oldUri && oldUri !== newUri) {
              const parsedOld = parseSourceUri(oldUri);
              if (parsedOld) {
                await supabaseAdmin.storage.from(parsedOld.bucket).remove([parsedOld.path]);
              }
            }

            // Update source to point to the newly uploaded file
            const { error: upErr } = await supabaseAdmin
              .from("ai_kb_sources")
              .update({
                source_type: "file",
                source_uri: newUri,
                is_active: true,
                updated_at: new Date().toISOString(),
                updated_by: userData.user.id,
              })
              .eq("id", sourceId);
            if (upErr) {
              return jsonResponse(500, { error: { message: "Failed to update KB source", details: upErr.message } });
            }

            // Clear existing entries for this source (chunks cascade)
            const { error: delErr } = await supabaseAdmin.from("ai_kb_entries").delete().eq("source_id", sourceId);
            if (delErr) {
              return jsonResponse(500, { error: { message: "Failed to clear existing entries", details: delErr.message } });
            }
          }
        }

        // If we didn't reuse an existing source, create a new one
        if (!sourceId) {
          const { data: sourceRow, error: sourceErr } = await supabaseAdmin
            .from("ai_kb_sources")
            .insert({
              name,
              source_type: "file",
              source_uri: `${storageBucket}/${storagePath}`,
              product,
              language,
              version,
              is_active: true,
              created_by: userData.user.id,
              updated_by: userData.user.id,
            })
            .select("id")
            .single();

          if (sourceErr || !sourceRow?.id) {
            return jsonResponse(500, { error: { message: "Failed to create KB source", details: sourceErr?.message } });
          }

          sourceId = sourceRow.id as string;
        }
      }

      const { data: entryRow, error: entryErr } = await supabaseAdmin
        .from("ai_kb_entries")
        .insert({
          source_id: sourceId,
          category: categoryCell,
          product: productCell,
          language: languageCell,
          question,
          answer,
          tags: [],
          is_active: true,
          priority: sheetName.toLowerCase().includes("priority") ? 10 : 0,
          raw_content: content,
          metadata: { sheet: sheetName, row: i + 1 },
          search_text: searchText,
          created_by: userData.user.id,
          updated_by: userData.user.id,
        })
        .select("id")
        .single();

      if (entryErr || !entryRow?.id) continue;

      const entryId = entryRow.id as string;
      const chunkText = question ? `Q: ${question}\nA: ${answer}` : answer;
      await supabaseAdmin.from("ai_kb_chunks").insert({
        entry_id: entryId,
        chunk_index: 0,
        content: chunkText,
        is_active: true,
      });
    }
  }

  if (dryRun) {
    return jsonResponse(200, {
      ok: true,
      dryRun: true,
      parsedEntries,
      parsedChunks,
      preview,
    });
  }

  return jsonResponse(200, {
    ok: true,
    dryRun: false,
    sourceId: sourceId ?? "",
    reusedSource,
    insertedEntries: parsedEntries,
    insertedChunks: parsedChunks,
  });
});

