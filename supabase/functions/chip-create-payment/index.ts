// CHIP Create Payment Edge Function
// Create a payment session with CHIP gateway
//
// Request: POST {
//   "trustId": "123",
//   "trustCode": "TRUST-001",
//   "userId": "user-uuid",
//   "clientId": "chip_customer_id",
//   "amount": 1000000,
//   "description": "Payment for Trust TRUST-001",
//   "successUrl": "sampul://trust?payment=success",
//   "failureUrl": "sampul://trust?payment=failed"
// }
// Auth: Authorization: Bearer <user_jwt>
//
// Response: { data: { id, checkout_url, status, client_id } }

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
  console.log("🟢 [CHIP-CREATE-PAYMENT] Request received:", req.method);
  
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    console.log("🟢 [CHIP-CREATE-PAYMENT] CORS preflight");
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (req.method !== "POST") {
    console.log("🔴 [CHIP-CREATE-PAYMENT] Method not allowed:", req.method);
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }

  try {
    console.log("🟢 [CHIP-CREATE-PAYMENT] Processing POST request");
    
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
    console.log("🟢 [CHIP-CREATE-PAYMENT] Request body:", body);
    
    const { trustId, trustCode, userId: bodyUserId, clientId, amount, description, successUrl, failureUrl } = body;
    
    // CHIP API requires HTTP/HTTPS URLs, not deep links
    // Construct web URLs that can redirect to deep links if needed

    // Validate required fields
    if (!trustId || !trustCode || !clientId || !amount) {
      console.log("🔴 [CHIP-CREATE-PAYMENT] Missing required fields:", { trustId, trustCode, clientId, amount });
      return new Response(
        JSON.stringify({ error: "Missing required fields: trustId, trustCode, clientId, amount" }),
        {
          status: 400,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    console.log("🟢 [CHIP-CREATE-PAYMENT] Validated fields:", { trustId, trustCode, clientId, amount });

    // Verify userId matches authenticated user
    if (bodyUserId && bodyUserId !== userId) {
      return new Response(JSON.stringify({ error: "User ID mismatch" }), {
        status: 403,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      });
    }

    // Create payment record in trust_payments table first
    console.log("🟢 [CHIP-CREATE-PAYMENT] Creating payment record in database");
    const { data: sessionData, error: sessionError } = await supabaseAdmin
      .from("trust_payments")
      .insert({
        trust_id: parseInt(trustId, 10),
        uuid: userId,
        amount: parseInt(amount, 10),
        status: "initiated",
        chip_client_id: clientId,
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (sessionError) {
      console.error("🔴 [CHIP-CREATE-PAYMENT] Error creating payment session:", sessionError);
      return new Response(
        JSON.stringify({ error: "Failed to create payment session", details: sessionError.message }),
        {
          status: 500,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    console.log("🟢 [CHIP-CREATE-PAYMENT] Payment record created:", sessionData.id);

    // Get CHIP API credentials
    const CHIP_SECRET_KEY = Deno.env.get("CHIP_SECRET_KEY");
    const CHIP_BRAND_ID = Deno.env.get("CHIP_BRAND_ID");

    if (!CHIP_SECRET_KEY || !CHIP_BRAND_ID) {
      console.log("🔴 [CHIP-CREATE-PAYMENT] CHIP credentials not configured");
      console.log("🔴 [CHIP-CREATE-PAYMENT] CHIP_SECRET_KEY exists:", !!CHIP_SECRET_KEY);
      console.log("🔴 [CHIP-CREATE-PAYMENT] CHIP_BRAND_ID exists:", !!CHIP_BRAND_ID);
      return new Response(
        JSON.stringify({ error: "CHIP credentials not configured" }),
        {
          status: 500,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    console.log("🟢 [CHIP-CREATE-PAYMENT] CHIP credentials found");
    console.log("🟢 [CHIP-CREATE-PAYMENT] CHIP_SECRET_KEY length:", CHIP_SECRET_KEY.length);
    console.log("🟢 [CHIP-CREATE-PAYMENT] CHIP_SECRET_KEY starts with:", CHIP_SECRET_KEY.substring(0, 10) + "...");
    console.log("🟢 [CHIP-CREATE-PAYMENT] CHIP_BRAND_ID:", CHIP_BRAND_ID);

    // CHIP API requires HTTP/HTTPS URLs for validation, but we don't actually need to serve pages
    // We handle all status updates via webhooks, so we can use Supabase URL as a placeholder
    // supabaseUrl is already declared above, so we reuse it here
    if (!supabaseUrl || !supabaseUrl.startsWith("http")) {
      console.log("🔴 [CHIP-CREATE-PAYMENT] SUPABASE_URL not configured or invalid:", supabaseUrl);
      return new Response(
        JSON.stringify({ error: "SUPABASE_URL not configured" }),
        {
          status: 500,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }
    
    // CHIP API requires success_callback, but we handle all status updates via webhook
    // Point it to webhook to avoid needing a separate dummy endpoint
    const successCallback = `${supabaseUrl}/functions/v1/chip-webhook`;
    
    // Use redirect function that serves HTML pages which redirect to deep links
    // This is the mobile-first approach: HTTP URLs for CHIP validation, deep links for app
    const finalSuccessUrl = successUrl && successUrl.startsWith("http") 
      ? successUrl 
      : `${supabaseUrl}/functions/v1/chip-payment-redirect?status=success`;
    const finalFailureUrl = failureUrl && failureUrl.startsWith("http")
      ? failureUrl
      : `${supabaseUrl}/functions/v1/chip-payment-redirect?status=failed`;

    console.log("🟢 [CHIP-CREATE-PAYMENT] Using Supabase URL as placeholder:", supabaseUrl);
    console.log("🟢 [CHIP-CREATE-PAYMENT] Callback URLs (placeholders - status handled via webhook):", { successCallback, finalSuccessUrl, finalFailureUrl });

    // Create CHIP purchase
    const chipPayload = {
      brand_id: CHIP_BRAND_ID,
      client_id: clientId,
      success_callback: successCallback,
      success_redirect: finalSuccessUrl,
      failure_redirect: finalFailureUrl,
      send_receipt: true,
      purchase: {
        amount: parseInt(amount, 10),
        products: [
          {
            name: description || `Payment for Trust ${trustCode}`,
            price: parseInt(amount, 10),
          },
        ],
      },
    };

    console.log("🟢 [CHIP-CREATE-PAYMENT] Calling CHIP API with payload:", JSON.stringify(chipPayload, null, 2));
    
    const chipResponse = await fetch("https://gate.chip-in.asia/api/v1/purchases/", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${CHIP_SECRET_KEY}`,
      },
      body: JSON.stringify(chipPayload),
    });

    console.log("🟢 [CHIP-CREATE-PAYMENT] CHIP API response status:", chipResponse.status);

    if (!chipResponse.ok) {
      const errorText = await chipResponse.text();
      console.error("🔴 [CHIP-CREATE-PAYMENT] CHIP API error:", errorText);
      
      // Update payment status to failed
      await supabaseAdmin
        .from("trust_payments")
        .update({ status: "failed" })
        .eq("id", sessionData.id);

      return new Response(
        JSON.stringify({ error: "Failed to create CHIP payment", details: errorText }),
        {
          status: chipResponse.status,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    const chipData = await chipResponse.json();
    console.log("🟢 [CHIP-CREATE-PAYMENT] CHIP API response data:", chipData);
    console.log("🟢 [CHIP-CREATE-PAYMENT] Checkout URL:", chipData.checkout_url);

    // Update payment record with CHIP payment ID and status
    console.log("🟢 [CHIP-CREATE-PAYMENT] Updating payment record with CHIP data");
    const { error: updateError } = await supabaseAdmin
      .from("trust_payments")
      .update({
        chip_payment_id: chipData.id,
        status: chipData.status || "pending_charge",
        chip_client_id: chipData.client_id || clientId,
        updated_at: new Date().toISOString(),
      })
      .eq("id", sessionData.id);

    if (updateError) {
      console.error("🔴 [CHIP-CREATE-PAYMENT] Error updating payment:", updateError);
      // Still return the CHIP response even if update fails
    } else {
      console.log("🟢 [CHIP-CREATE-PAYMENT] Payment record updated successfully");
    }

    console.log("🟢 [CHIP-CREATE-PAYMENT] Returning success response");
    return new Response(
      JSON.stringify({ data: chipData }),
      {
        status: 200,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      },
    );
  } catch (error) {
    console.error("🔴 [CHIP-CREATE-PAYMENT] Create payment error:", error);
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
