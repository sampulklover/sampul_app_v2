// Claim referral code (Affiliate marketing)
// Called by mobile app and future website.
//
// Request: POST { code: string }
// Auth: Authorization: Bearer <user_jwt>
//
// Uses service role to:
// - validate code exists
// - prevent self-referral
// - insert referral once per referred user

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

function corsHeaders(extra: Record<string, string> = {}) {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    ...extra,
  };
}

function normalizeCode(raw: string | null | undefined): string | null {
  const v = (raw ?? "").trim();
  if (!v) return null;
  return v.replace(/\s+/g, "").toUpperCase();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (req.method !== "POST") {
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

  let body: any;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: "Invalid JSON payload" }), {
      status: 400,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  const code = normalizeCode(body?.code);
  if (!code) {
    return new Response(JSON.stringify({ error: "invalid_code" }), {
      status: 400,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  // Lookup code owner
  const { data: codeRow, error: codeError } = await supabaseAdmin
    .from("affiliate_codes")
    .select("code, owner_id")
    .eq("code", code)
    .maybeSingle();

  if (codeError) {
    return new Response(JSON.stringify({ error: "db_error", details: codeError.message }), {
      status: 500,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  if (!codeRow) {
    return new Response(JSON.stringify({ error: "code_not_found" }), {
      status: 404,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  if (codeRow.owner_id === userId) {
    return new Response(JSON.stringify({ error: "cannot_refer_self" }), {
      status: 400,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  // Insert referral (one per referred user)
  const { error: insertError } = await supabaseAdmin
    .from("affiliate_referrals")
    .insert({
      code: codeRow.code,
      referrer_id: codeRow.owner_id,
      referred_id: userId,
    });

  // Unique violation -> already has a referrer; treat as idempotent.
  if (insertError) {
    // Postgrest error codes vary; we keep it simple and return a 200-style response for duplicates.
    // If you want strict behavior, check insertError.code === '23505' (unique_violation).
    return new Response(JSON.stringify({ claimed: false, reason: "already_referred" }), {
      status: 200,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  return new Response(JSON.stringify({ claimed: true, code: codeRow.code }), {
    status: 200,
    headers: corsHeaders({ "Content-Type": "application/json" }),
  });
});

