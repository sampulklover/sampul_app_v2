// CHIP Create Client Edge Function
// Get or create CHIP customer ID for the user
//
// Request: POST { "email": "user@example.com" }
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
    const { email } = body;
    console.log("🟢 [CHIP-CREATE-CLIENT] Request body:", { email, userId });

    if (!email) {
      console.log("🔴 [CHIP-CREATE-CLIENT] Email is required");
      return new Response(JSON.stringify({ error: "Email is required" }), {
        status: 400,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      });
    }

    // Check if user already has chip_customer_id in accounts table
    console.log("🟢 [CHIP-CREATE-CLIENT] Checking existing account for userId:", userId);
    const { data: account, error: accountError } = await supabaseAdmin
      .from("accounts")
      .select("chip_customer_id")
      .eq("uuid", userId)
      .maybeSingle();

    if (accountError && accountError.code !== "PGRST116") {
      // PGRST116 = no rows returned, which is OK
      console.error("🔴 [CHIP-CREATE-CLIENT] Error checking account:", accountError);
    }

    console.log("🟢 [CHIP-CREATE-CLIENT] Account data:", account);

    // If user already has chip_customer_id, return it
    if (account?.chip_customer_id) {
      console.log("🟢 [CHIP-CREATE-CLIENT] Found existing chip_customer_id:", account.chip_customer_id);
      return new Response(
        JSON.stringify({ data: { id: account.chip_customer_id } }),
        {
          status: 200,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    console.log("🟢 [CHIP-CREATE-CLIENT] No existing client ID, creating new one");

    // Create new CHIP client
    const CHIP_SECRET_KEY = Deno.env.get("CHIP_SECRET_KEY");
    if (!CHIP_SECRET_KEY) {
      console.log("🔴 [CHIP-CREATE-CLIENT] CHIP_SECRET_KEY not configured");
      return new Response(
        JSON.stringify({ error: "CHIP_SECRET_KEY not configured" }),
        {
          status: 500,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    console.log("🟢 [CHIP-CREATE-CLIENT] CHIP_SECRET_KEY found");
    console.log("🟢 [CHIP-CREATE-CLIENT] CHIP_SECRET_KEY length:", CHIP_SECRET_KEY.length);
    console.log("🟢 [CHIP-CREATE-CLIENT] CHIP_SECRET_KEY starts with:", CHIP_SECRET_KEY.substring(0, 10) + "...");

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

    // Store chip_customer_id in accounts table
    console.log("🟢 [CHIP-CREATE-CLIENT] Storing chip_customer_id in accounts table");
    const { error: upsertError } = await supabaseAdmin
      .from("accounts")
      .upsert(
        {
          uuid: userId,
          chip_customer_id: chipClientId,
        },
        { onConflict: "uuid" },
      );

    if (upsertError) {
      console.error("🔴 [CHIP-CREATE-CLIENT] Error storing chip_customer_id:", upsertError);
      // Still return the client ID even if storage fails
    } else {
      console.log("🟢 [CHIP-CREATE-CLIENT] Successfully stored chip_customer_id");
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
