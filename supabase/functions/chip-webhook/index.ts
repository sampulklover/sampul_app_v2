// CHIP Webhook Handler
// Updates payment status in trust_payments or hibah_payments table
// Similar pattern to stripe-webhook and didit-webhook
//
// This function should be deployed with --no-verify-jwt flag
// Configure webhook URL in CHIP dashboard to point to this function

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

Deno.serve(async (req) => {
  console.log("🟢 [CHIP WEBHOOK] Function invoked");
  console.log("🟢 [CHIP WEBHOOK] Method:", req.method);
  console.log("🟢 [CHIP WEBHOOK] URL:", req.url);
  
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    console.log("🟡 [CHIP WEBHOOK] CORS preflight request");
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
      },
    });
  }

  // Only allow POST requests
  if (req.method !== "POST") {
    console.log("🔴 [CHIP WEBHOOK] Method not allowed:", req.method);
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json" } }
    );
  }

  try {
    console.log("🟢 [CHIP WEBHOOK] Reading request body...");
    // Get request body
    const bodyText = await req.text();
    console.log("🟢 [CHIP WEBHOOK] Body text length:", bodyText.length);
    console.log("🟢 [CHIP WEBHOOK] Body text (first 500 chars):", bodyText.substring(0, 500));
    
    let event: any;
    
    try {
      event = JSON.parse(bodyText);
      console.log("🟢 [CHIP WEBHOOK] Parsed JSON successfully");
      console.log("🟢 [CHIP WEBHOOK] Event ID:", event.id);
      console.log("🟢 [CHIP WEBHOOK] Event status:", event.status);
      console.log("🟢 [CHIP WEBHOOK] Full event:", JSON.stringify(event, null, 2));
    } catch (e) {
      console.error("🔴 [CHIP WEBHOOK] JSON parse error:", e);
      console.error("🔴 [CHIP WEBHOOK] Body text that failed to parse:", bodyText);
      return new Response(
        JSON.stringify({ error: "Invalid JSON payload" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Get Supabase credentials
    console.log("🟢 [CHIP WEBHOOK] Getting Supabase credentials...");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    console.log("🟡 [CHIP WEBHOOK] SUPABASE_URL exists:", !!supabaseUrl);
    console.log("🟡 [CHIP WEBHOOK] SUPABASE_URL value:", supabaseUrl ? `${supabaseUrl.substring(0, 30)}...` : "missing");
    console.log("🟡 [CHIP WEBHOOK] SUPABASE_SERVICE_ROLE_KEY exists:", !!supabaseServiceKey);
    console.log("🟡 [CHIP WEBHOOK] SUPABASE_SERVICE_ROLE_KEY length:", supabaseServiceKey ? supabaseServiceKey.length : 0);

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error("🔴 [CHIP WEBHOOK] Missing Supabase credentials");
      return new Response(
        JSON.stringify({ 
          error: "Server configuration error",
          details: {
            has_url: !!supabaseUrl,
            has_service_key: !!supabaseServiceKey,
          }
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log("🟢 [CHIP WEBHOOK] Creating Supabase client...");
    const supabase = createClient(
      supabaseUrl,
      supabaseServiceKey, // service role for bypassing RLS
    );

    const chipPaymentId = event.id;
    const status = event.status;

    console.log("🟢 [CHIP WEBHOOK] Extracted payment ID:", chipPaymentId);
    console.log("🟢 [CHIP WEBHOOK] Extracted status:", status);

    if (!chipPaymentId) {
      console.error("🔴 [CHIP WEBHOOK] Missing payment ID in webhook event");
      console.error("🔴 [CHIP WEBHOOK] Event object:", JSON.stringify(event, null, 2));
      return new Response(
        JSON.stringify({ error: "Missing payment ID in webhook" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Check which table contains the payment record
    // First check trust_payments
    console.log("🟢 [CHIP WEBHOOK] Checking trust_payments table for chip_payment_id:", chipPaymentId);
    const { data: trustPayment, error: trustLookupError } = await supabase
      .from("trust_payments")
      .select("id")
      .eq("chip_payment_id", chipPaymentId)
      .maybeSingle();

    if (trustLookupError) {
      console.error("🔴 [CHIP WEBHOOK] Error looking up trust_payment:", trustLookupError);
    } else {
      console.log("🟡 [CHIP WEBHOOK] Trust payment lookup result:", trustPayment ? `Found ID: ${trustPayment.id}` : "Not found");
    }

    if (trustPayment) {
      console.log("🟢 [CHIP WEBHOOK] Found trust payment, updating status to:", status);
      // Update trust_payments table
      const { error: trustError } = await supabase
        .from("trust_payments")
        .update({
          status: status,
          updated_at: new Date().toISOString(),
        })
        .eq("chip_payment_id", chipPaymentId);

      if (trustError) {
        console.error("🔴 [CHIP WEBHOOK] Error updating trust_payments:", trustError);
        console.error("🔴 [CHIP WEBHOOK] Error details:", JSON.stringify(trustError, null, 2));
        return new Response(
          JSON.stringify({ error: "Failed to update trust payment" }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        );
      }

      console.log("🟢 [CHIP WEBHOOK] Successfully updated trust payment");
      return new Response(
        JSON.stringify({ 
          message: "Webhook processed successfully",
          type: "trust_payment",
          status: status,
        }),
        { 
          status: 200,
          headers: { "Content-Type": "application/json" }
        }
      );
    }

    // Check hibah_payments table
    console.log("🟢 [CHIP WEBHOOK] Checking hibah_payments table for chip_payment_id:", chipPaymentId);
    const { data: hibahPayment, error: hibahLookupError } = await supabase
      .from("hibah_payments")
      .select("id")
      .eq("chip_payment_id", chipPaymentId)
      .maybeSingle();

    if (hibahLookupError) {
      console.error("🔴 [CHIP WEBHOOK] Error looking up hibah_payment:", hibahLookupError);
    } else {
      console.log("🟡 [CHIP WEBHOOK] Hibah payment lookup result:", hibahPayment ? `Found ID: ${hibahPayment.id}` : "Not found");
    }

    if (hibahPayment) {
      console.log("🟢 [CHIP WEBHOOK] Found hibah payment, updating status to:", status);
      // Update hibah_payments table
      const { error: hibahError } = await supabase
        .from("hibah_payments")
        .update({
          status: status,
          updated_at: new Date().toISOString(),
        })
        .eq("chip_payment_id", chipPaymentId);

      if (hibahError) {
        console.error("🔴 [CHIP WEBHOOK] Error updating hibah_payments:", hibahError);
        console.error("🔴 [CHIP WEBHOOK] Error details:", JSON.stringify(hibahError, null, 2));
        return new Response(
          JSON.stringify({ error: "Failed to update hibah payment" }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        );
      }

      console.log("🟢 [CHIP WEBHOOK] Successfully updated hibah payment");
      return new Response(
        JSON.stringify({ 
          message: "Webhook processed successfully",
          type: "hibah_payment",
          status: status,
        }),
        { 
          status: 200,
          headers: { "Content-Type": "application/json" }
        }
      );
    }

    // Payment not found in either table
    console.error("🔴 [CHIP WEBHOOK] Payment not found in either trust_payments or hibah_payments");
    console.error("🔴 [CHIP WEBHOOK] chip_payment_id:", chipPaymentId);
    console.error("🔴 [CHIP WEBHOOK] Full event:", JSON.stringify(event, null, 2));
    
    return new Response(
      JSON.stringify({ 
        error: "Payment record not found",
        chip_payment_id: chipPaymentId,
      }),
      { status: 404, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("🔴 [CHIP WEBHOOK] Unhandled error:", error);
    console.error("🔴 [CHIP WEBHOOK] Error stack:", error instanceof Error ? error.stack : "No stack trace");
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ error: `Webhook Error: ${errorMessage}` }),
      { 
        status: 500,
        headers: { "Content-Type": "application/json" }
      }
    );
  }
});
