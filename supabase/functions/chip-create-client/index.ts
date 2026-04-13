// CHIP Create Client Edge Function
// Get or create CHIP customer ID for the user
//
// Request: POST { "email": "user@example.com", "chipAccount"?: "main" | "trust" }
// - main (default): CHIP_SECRET_KEY → accounts.chip_customer_id (Hibah, Wasiat)
// - trust: CHIP_TRUST_SECRET_KEY → accounts.chip_trust_customer_id
// Auth: Authorization: Bearer <user_jwt>
//
// Response: { data: { id: "chip_customer_id" } }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

function corsHeaders(extra: Record<string, string> = {}) {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    ...extra,
  };
}

Deno.serve(async (req) => {
  console.log("🟢 [CHIP-CREATE-CLIENT] Request received:", req.method);
  
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    console.log("🟢 [CHIP-CREATE-CLIENT] CORS preflight");
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (req.method !== "POST") {
    console.log("🔴 [CHIP-CREATE-CLIENT] Method not allowed:", req.method);
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  try {
    console.log("🟢 [CHIP-CREATE-CLIENT] Processing POST request");
    // Get Supabase credentials
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

    // Get authenticated user
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

    // Get request body
    const body = await req.json();
    const { email, chipAccount: chipAccountRaw } = body;
    const chipAccount: "main" | "trust" = chipAccountRaw === "trust" ? "trust" : "main";
    console.log("🟢 [CHIP-CREATE-CLIENT] Request body:", { email, userId, chipAccount });

    if (!email) {
      console.log("🔴 [CHIP-CREATE-CLIENT] Email is required");
      return new Response(JSON.stringify({ error: "Email is required" }), {
        status: 400,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      });
    }

    const idColumn = chipAccount === "trust" ? "chip_trust_customer_id" : "chip_customer_id";

    // Check if user already has CHIP client for this merchant
    console.log("🟢 [CHIP-CREATE-CLIENT] Checking existing account for userId:", userId);
    const { data: account, error: accountError } = await supabaseAdmin
      .from("accounts")
      .select("chip_customer_id, chip_trust_customer_id")
      .eq("uuid", userId)
      .maybeSingle();

    if (accountError && accountError.code !== "PGRST116") {
      // PGRST116 = no rows returned, which is OK
      console.error("🔴 [CHIP-CREATE-CLIENT] Error checking account:", accountError);
    }

    console.log("🟢 [CHIP-CREATE-CLIENT] Account data:", account);

    const existingId = chipAccount === "trust"
      ? account?.chip_trust_customer_id as string | undefined
      : account?.chip_customer_id as string | undefined;

    if (existingId) {
      console.log(`🟢 [CHIP-CREATE-CLIENT] Found existing ${idColumn}:`, existingId);
      return new Response(
        JSON.stringify({ data: { id: existingId } }),
        {
          status: 200,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    console.log("🟢 [CHIP-CREATE-CLIENT] No existing client ID, creating new one");

    const CHIP_SECRET_KEY = chipAccount === "trust"
      ? Deno.env.get("CHIP_TRUST_SECRET_KEY")
      : Deno.env.get("CHIP_SECRET_KEY");
    const secretLabel = chipAccount === "trust" ? "CHIP_TRUST_SECRET_KEY" : "CHIP_SECRET_KEY";

    if (!CHIP_SECRET_KEY) {
      console.log(`🔴 [CHIP-CREATE-CLIENT] ${secretLabel} not configured`);
      return new Response(
        JSON.stringify({ error: `${secretLabel} not configured` }),
        {
          status: 500,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    console.log(`🟢 [CHIP-CREATE-CLIENT] ${secretLabel} found`);
    console.log(`🟢 [CHIP-CREATE-CLIENT] ${secretLabel} length:`, CHIP_SECRET_KEY.length);
    console.log(`🟢 [CHIP-CREATE-CLIENT] ${secretLabel} starts with:`, CHIP_SECRET_KEY.substring(0, 10) + "...");

    console.log("🟢 [CHIP-CREATE-CLIENT] Calling CHIP API to create client");
    const chipResponse = await fetch("https://gate.chip-in.asia/api/v1/clients/", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${CHIP_SECRET_KEY}`,
      },
      body: JSON.stringify({ email }),
    });

    console.log("🟢 [CHIP-CREATE-CLIENT] CHIP API response status:", chipResponse.status);

    if (!chipResponse.ok) {
      const errorText = await chipResponse.text();
      console.error("🔴 [CHIP-CREATE-CLIENT] CHIP API error:", errorText);
      return new Response(
        JSON.stringify({ error: "Failed to create CHIP client", details: errorText }),
        {
          status: chipResponse.status,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    const chipData = await chipResponse.json();
    console.log("🟢 [CHIP-CREATE-CLIENT] CHIP API response data:", chipData);
    const chipClientId = chipData.id;

    if (!chipClientId) {
      console.log("🔴 [CHIP-CREATE-CLIENT] No client ID in CHIP response");
      return new Response(
        JSON.stringify({ error: "No client ID in CHIP response" }),
        {
          status: 500,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    console.log("🟢 [CHIP-CREATE-CLIENT] Created CHIP client ID:", chipClientId);

    console.log(`🟢 [CHIP-CREATE-CLIENT] Storing ${idColumn} in accounts table`);
    const upsertPayload: Record<string, string> = { uuid: userId };
    upsertPayload[idColumn] = chipClientId;

    const { error: upsertError } = await supabaseAdmin
      .from("accounts")
      .upsert(upsertPayload, { onConflict: "uuid" });

    if (upsertError) {
      console.error(`🔴 [CHIP-CREATE-CLIENT] Error storing ${idColumn}:`, upsertError);
      // Still return the client ID even if storage fails
    } else {
      console.log(`🟢 [CHIP-CREATE-CLIENT] Successfully stored ${idColumn}`);
    }

    console.log("🟢 [CHIP-CREATE-CLIENT] Returning success response");
    return new Response(
      JSON.stringify({ data: { id: chipClientId } }),
      {
        status: 200,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      },
    );
  } catch (error) {
    console.error("🔴 [CHIP-CREATE-CLIENT] Create client error:", error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ error: errorMessage }),
      {
        status: 500,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      },
    );
  }
});
