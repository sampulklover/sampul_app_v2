// CHIP Webhook Handler
// Updates payment status in trust_payments or hibah_payments table
// Similar pattern to stripe-webhook and didit-webhook
//
// This function should be deployed with --no-verify-jwt flag
// Configure webhook URL in CHIP dashboard to point to this function

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const CHIP_SUCCESS_STATUSES = ["paid", "settled", "cleared"];

function isChipSuccessStatus(status: string | undefined): boolean {
  const s = status?.toLowerCase() ?? "";
  return CHIP_SUCCESS_STATUSES.includes(s);
}

async function extendWasiatSubscription(
  supabase: ReturnType<typeof createClient>,
  userId: string,
) {
  const { data: account, error: accErr } = await supabase
    .from("accounts")
    .select("wasiat_subscription_period_start, wasiat_subscription_period_end")
    .eq("uuid", userId)
    .maybeSingle();

  if (accErr) {
    console.error("🔴 [CHIP WEBHOOK] accounts lookup for wasiat:", accErr);
    return;
  }

  const now = new Date();
  const paidAt = now;
  let periodStart: Date;
  let periodEnd: Date;

  const oldEndRaw = account?.wasiat_subscription_period_end as string | null | undefined;
  const oldStartRaw = account?.wasiat_subscription_period_start as string | null | undefined;
  const oldEnd = oldEndRaw ? new Date(oldEndRaw) : null;
  const oldStart = oldStartRaw ? new Date(oldStartRaw) : null;

  if (!oldEnd || oldEnd.getTime() <= now.getTime()) {
    periodStart = paidAt;
    periodEnd = new Date(paidAt);
    periodEnd.setFullYear(periodEnd.getFullYear() + 1);
  } else {
    periodStart = oldStart ?? paidAt;
    periodEnd = new Date(oldEnd);
    periodEnd.setFullYear(periodEnd.getFullYear() + 1);
  }

  const { error: updErr } = await supabase
    .from("accounts")
    .update({
      is_subscribed: true,
      wasiat_subscription_period_start: periodStart.toISOString(),
      wasiat_subscription_period_end: periodEnd.toISOString(),
    })
    .eq("uuid", userId);

  if (updErr) {
    console.error("🔴 [CHIP WEBHOOK] Failed to update accounts for wasiat:", updErr);
  } else {
    console.log("🟢 [CHIP WEBHOOK] Wasiat subscription extended for user:", userId);
  }
}

async function markCouponUsedForPayment(
  supabase: ReturnType<typeof createClient>,
  userCouponId: string | null | undefined,
  paymentKind: "hibah" | "wasiat",
  paymentRowId: string,
) {
  if (!userCouponId) return;
  const { error } = await supabase.from("user_coupons").update({
    status: "used",
    used_at: new Date().toISOString(),
    used_payment_kind: paymentKind,
    used_payment_id: paymentRowId,
  }).eq("id", userCouponId).eq("status", "active");
  if (error) {
    console.error("🔴 [CHIP WEBHOOK] markCouponUsedForPayment:", error);
  }
}

async function grantReferrerRewardIfEligible(
  supabase: ReturnType<typeof createClient>,
  referredUserId: string,
  appliesTo: "hibah" | "wasiat",
) {
  const { data: ref, error } = await supabase.from("affiliate_referrals").select("id, referrer_id").eq(
    "referred_id",
    referredUserId,
  ).maybeSingle();
  if (error || !ref) return;

  const source = appliesTo === "hibah" ? "referrer_reward_hibah" : "referrer_reward_wasiat";
  const { data: existing } = await supabase.from("user_coupons").select("id").eq("referral_id", ref.id).eq(
    "source",
    source,
  ).maybeSingle();
  if (existing) return;

  const expiresAt = new Date();
  expiresAt.setFullYear(expiresAt.getFullYear() + 1);

  const { error: insErr } = await supabase.from("user_coupons").insert({
    user_id: ref.referrer_id,
    applies_to: appliesTo,
    discount_percent: 5,
    status: "active",
    source,
    expires_at: expiresAt.toISOString(),
    referral_id: ref.id,
  });
  if (insErr) {
    console.error("🔴 [CHIP WEBHOOK] grantReferrerRewardIfEligible:", insErr);
  }
}

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
      .select("id, user_id, user_coupon_id, status")
      .eq("chip_payment_id", chipPaymentId)
      .maybeSingle();

    if (hibahLookupError) {
      console.error("🔴 [CHIP WEBHOOK] Error looking up hibah_payment:", hibahLookupError);
    } else {
      console.log("🟡 [CHIP WEBHOOK] Hibah payment lookup result:", hibahPayment ? `Found ID: ${hibahPayment.id}` : "Not found");
    }

    if (hibahPayment) {
      const prevHibahStatus = (hibahPayment.status as string | null | undefined)?.toLowerCase() ?? "";
      const prevHibahSuccess = isChipSuccessStatus(prevHibahStatus);
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

      const newHibahSuccess = isChipSuccessStatus(status);
      const hibahRowId = hibahPayment.id as string;
      const hibahUserId = hibahPayment.user_id as string;
      if (newHibahSuccess && !prevHibahSuccess) {
        await markCouponUsedForPayment(
          supabase,
          hibahPayment.user_coupon_id as string | null | undefined,
          "hibah",
          hibahRowId,
        );
        if (hibahUserId) {
          await grantReferrerRewardIfEligible(supabase, hibahUserId, "hibah");
        }
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

    // Check wasiat_subscription_payments
    console.log("🟢 [CHIP WEBHOOK] Checking wasiat_subscription_payments for chip_payment_id:", chipPaymentId);
    const { data: wasiatPayment, error: wasiatLookupError } = await supabase
      .from("wasiat_subscription_payments")
      .select("id, user_id, user_coupon_id, status")
      .eq("chip_payment_id", chipPaymentId)
      .maybeSingle();

    if (wasiatLookupError) {
      console.error("🔴 [CHIP WEBHOOK] Error looking up wasiat_subscription_payment:", wasiatLookupError);
    } else {
      console.log("🟡 [CHIP WEBHOOK] Wasiat payment lookup:", wasiatPayment ? `Found ID: ${wasiatPayment.id}` : "Not found");
    }

    if (wasiatPayment) {
      const prevStatus = (wasiatPayment.status as string | null)?.toLowerCase() ?? "";
      const prevSuccess = CHIP_SUCCESS_STATUSES.includes(prevStatus);

      console.log("🟢 [CHIP WEBHOOK] Found wasiat payment, updating status to:", status);
      const { error: wasiatError } = await supabase
        .from("wasiat_subscription_payments")
        .update({
          status: status,
          updated_at: new Date().toISOString(),
        })
        .eq("chip_payment_id", chipPaymentId);

      if (wasiatError) {
        console.error("🔴 [CHIP WEBHOOK] Error updating wasiat_subscription_payments:", wasiatError);
        return new Response(
          JSON.stringify({ error: "Failed to update wasiat subscription payment" }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        );
      }

      const newSuccess = isChipSuccessStatus(status);
      const userId = wasiatPayment.user_id as string;
      const wasiatRowId = wasiatPayment.id as string;
      if (newSuccess && !prevSuccess && userId) {
        await extendWasiatSubscription(supabase, userId);
        await markCouponUsedForPayment(
          supabase,
          wasiatPayment.user_coupon_id as string | null | undefined,
          "wasiat",
          wasiatRowId,
        );
        await grantReferrerRewardIfEligible(supabase, userId, "wasiat");
      }

      console.log("🟢 [CHIP WEBHOOK] Successfully updated wasiat payment");
      return new Response(
        JSON.stringify({
          message: "Webhook processed successfully",
          type: "wasiat_subscription_payment",
          status: status,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // Payment not found in either table
    console.error("🔴 [CHIP WEBHOOK] Payment not found in trust_payments, hibah_payments, or wasiat_subscription_payments");
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
