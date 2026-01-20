// Get or create the current user's affiliate/referral code.
//
// Request: POST {} (or GET/POST)
// Auth: Authorization: Bearer <user_jwt>
//
// Response: { code: string }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

function corsHeaders(extra: Record<string, string> = {}) {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    ...extra,
  };
}

function makeCode(): string {
  // 10 chars hex-like, uppercase.
  const bytes = crypto.getRandomValues(new Uint8Array(5));
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
    .slice(0, 10)
    .toUpperCase();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (req.method !== "POST" && req.method !== "GET") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceKey) {
    return new Response(
      JSON.stringify({
        error: "Server configuration error",
        details: { has_url: !!supabaseUrl, has_service_key: !!serviceKey },
      }),
      { status: 500, headers: corsHeaders({ "Content-Type": "application/json" }) },
    );
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceKey);

  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice("Bearer ".length) : "";

  if (!token) {
    return new Response(JSON.stringify({ error: "Missing bearer token" }), {
      status: 401,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  const { data: userData, error: userError } = await supabaseAdmin.auth.getUser(token);
  const userId = userData?.user?.id ?? null;
  if (userError || !userId) {
    return new Response(JSON.stringify({ error: "Invalid token" }), {
      status: 401,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  // Return existing code if present
  const { data: existing, error: existingError } = await supabaseAdmin
    .from("affiliate_codes")
    .select("code")
    .eq("owner_id", userId)
    .maybeSingle();

  if (existingError) {
    return new Response(JSON.stringify({ error: "db_error", details: existingError.message }), {
      status: 500,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  if (existing?.code) {
    return new Response(JSON.stringify({ code: existing.code }), {
      status: 200,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  // Create a new code (retry a few times if collision)
  let createdCode: string | null = null;
  for (let i = 0; i < 5; i++) {
    const candidate = makeCode();
    const { error: insertError } = await supabaseAdmin.from("affiliate_codes").insert({
      code: candidate,
      owner_id: userId,
    });
    if (!insertError) {
      createdCode = candidate;
      break;
    }
  }

  if (!createdCode) {
    // Fallback: re-check
    const { data: fallback } = await supabaseAdmin
      .from("affiliate_codes")
      .select("code")
      .eq("owner_id", userId)
      .maybeSingle();
    if (fallback?.code) {
      createdCode = fallback.code;
    }
  }

  if (!createdCode) {
    return new Response(JSON.stringify({ error: "could_not_create_code" }), {
      status: 500,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  return new Response(JSON.stringify({ code: createdCode }), {
    status: 200,
    headers: corsHeaders({ "Content-Type": "application/json" }),
  });
});

