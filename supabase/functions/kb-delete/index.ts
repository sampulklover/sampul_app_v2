import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

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

type DeleteRequest = {
  sourceId: string;
};

function parseSourceUri(sourceUri: string): { bucket: string; path: string } | null {
  const s = sourceUri.trim();
  if (!s) return null;
  const idx = s.indexOf("/");
  if (idx <= 0 || idx === s.length - 1) return null;
  const bucket = s.slice(0, idx);
  const path = s.slice(idx + 1);
  return { bucket, path };
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

  // Basic staff check: must have a row in public.roles with role admin/marketing
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

  let payload: DeleteRequest;
  try {
    payload = (await req.json()) as DeleteRequest;
  } catch {
    return jsonResponse(400, { error: { message: "Invalid JSON body" } });
  }

  const sourceId = (payload.sourceId ?? "").trim();
  if (!sourceId) return jsonResponse(400, { error: { message: "Missing sourceId" } });

  // Load source row
  const { data: source, error: srcErr } = await supabaseAdmin
    .from("ai_kb_sources")
    .select("id, source_uri")
    .eq("id", sourceId)
    .maybeSingle();

  if (srcErr) return jsonResponse(500, { error: { message: "Failed to load source", details: srcErr.message } });
  if (!source) return jsonResponse(404, { error: { message: "Source not found" } });

  const sourceUri = (source.source_uri ?? "").toString();
  const parsed = parseSourceUri(sourceUri);

  // Delete storage object first (best effort)
  let storageDeleted = false;
  if (parsed) {
    const { error: rmErr } = await supabaseAdmin.storage.from(parsed.bucket).remove([parsed.path]);
    if (!rmErr) storageDeleted = true;
  }

  // Delete DB rows (entries + chunks cascade)
  const { error: delErr } = await supabaseAdmin.from("ai_kb_sources").delete().eq("id", sourceId);
  if (delErr) return jsonResponse(500, { error: { message: "Failed to delete source", details: delErr.message } });

  return jsonResponse(200, { ok: true, sourceId, storageDeleted });
});

