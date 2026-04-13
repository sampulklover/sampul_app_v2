// CHIP Create Payment Edge Function
// Create a payment session with CHIP gateway
//
// Request: POST {
//   "paymentType": "trust" | "hibah" | "wasiat",
//   "trustId": "123",
//   "trustCode": "TRUST-001",
//   "hibahId": "uuid",
//   "certificateId": "CERT-2026-123456789",
//   "userId": "user-uuid",
//   "clientId": "chip_customer_id",
//   "amount": 1000000,
//   "description": "Payment description",
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

const TERMINAL_PAYMENT_STATUSES = new Set([
  "failed",
  "error",
  "expired",
  "cancelled",
  "paid",
  "settled",
  "cleared",
]);

const COUPON_LOCK_TTL_MS = 30 * 60 * 1000; // 30 minutes

async function couponBlockedByOpenCheckout(
  supabase: ReturnType<typeof createClient>,
  couponId: string,
): Promise<boolean> {
  for (const table of ["hibah_payments", "wasiat_subscription_payments"] as const) {
    const { data, error } = await supabase.from(table).select("id, status, created_at").eq(
      "user_coupon_id",
      couponId,
    );
    if (error || !data?.length) continue;
    for (const row of data) {
      const r = row as { id?: string; status?: string; created_at?: string };
      const s = String(r.status ?? "").toLowerCase();
      if (TERMINAL_PAYMENT_STATUSES.has(s)) continue;

      // If a checkout was abandoned/cancelled and we never received webhook updates,
      // let the coupon be reused after a short TTL.
      const createdAt = r.created_at ? new Date(r.created_at).getTime() : 0;
      const ageOk = createdAt > 0 && Date.now() - createdAt > COUPON_LOCK_TTL_MS;
      if (ageOk && r.id) {
        await supabase.from(table).update({
          status: "cancelled",
          updated_at: new Date().toISOString(),
        }).eq("id", r.id).eq("user_coupon_id", couponId);
        continue;
      }

      return true;
    }
  }
  return false;
}

async function validateUserCoupon(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  couponId: string,
  appliesTo: "hibah" | "wasiat",
): Promise<{ ok: true; discountPercent: number } | { ok: false; message: string }> {
  const { data: c, error } = await supabase.from("user_coupons").select(
    "id, user_id, applies_to, discount_percent, status, expires_at",
  ).eq("id", couponId).maybeSingle();
  if (error || !c) return { ok: false, message: "Invalid coupon" };
  if ((c as { user_id: string }).user_id !== userId) {
    return { ok: false, message: "Coupon does not belong to this account" };
  }
  if ((c as { applies_to: string }).applies_to !== appliesTo) {
    return { ok: false, message: "Coupon does not apply to this product" };
  }
  if ((c as { status: string }).status !== "active") {
    return { ok: false, message: "Coupon is no longer active" };
  }
  if (new Date((c as { expires_at: string }).expires_at).getTime() < Date.now()) {
    await supabase.from("user_coupons").update({ status: "expired" }).eq("id", couponId);
    return { ok: false, message: "Coupon has expired" };
  }
  if (await couponBlockedByOpenCheckout(supabase, couponId)) {
    return { ok: false, message: "This coupon is already linked to a checkout in progress" };
  }
  const pct = (c as { discount_percent: number }).discount_percent;
  return { ok: true, discountPercent: pct };
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
    
    const {
      paymentType,
      trustId,
      trustCode,
      hibahId,
      certificateId,
      userId: bodyUserId,
      clientId,
      amount,
      description,
      successUrl,
      failureUrl,
      userCouponId,
      user_coupon_id,
    } = body;
    const resolvedUserCouponId: string | null =
      typeof userCouponId === "string" && userCouponId.length > 0
        ? userCouponId
        : typeof user_coupon_id === "string" && user_coupon_id.length > 0
          ? user_coupon_id
          : null;
    const resolvedPaymentType: "trust" | "hibah" | "wasiat" =
      paymentType === "hibah"
        ? "hibah"
        : paymentType === "wasiat"
          ? "wasiat"
          : "trust";

    // CHIP API requires HTTP/HTTPS URLs, not deep links
    // Construct web URLs that can redirect to deep links if needed

    // Validate required fields
    const hasRequiredTrustFields = Boolean(trustId && trustCode);
    const hasRequiredHibahFields = Boolean(hibahId && certificateId);
    const isMissingRequiredFields =
      !clientId ||
      !amount ||
      (resolvedPaymentType === "trust" && !hasRequiredTrustFields) ||
      (resolvedPaymentType === "hibah" && !hasRequiredHibahFields);

    if (isMissingRequiredFields) {
      console.log("🔴 [CHIP-CREATE-PAYMENT] Missing required fields:", {
        paymentType: resolvedPaymentType,
        trustId,
        trustCode,
        hibahId,
        certificateId,
        clientId,
        amount,
      });
      const errMsg =
        resolvedPaymentType === "hibah"
          ? "Missing required fields: hibahId, certificateId, clientId, amount"
          : resolvedPaymentType === "wasiat"
            ? "Missing required fields: clientId, amount"
            : "Missing required fields: trustId, trustCode, clientId, amount";
      return new Response(JSON.stringify({ error: errMsg }), {
        status: 400,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      });
    }

    console.log("🟢 [CHIP-CREATE-PAYMENT] Validated fields:", {
      paymentType: resolvedPaymentType,
      trustId,
      trustCode,
      hibahId,
      certificateId,
      clientId,
      amount,
    });

    const expectedWasiatCents = parseInt(
      Deno.env.get("WASIAT_ANNUAL_AMOUNT_CENTS") ?? "18000",
      10,
    );

    if (resolvedPaymentType === "trust" && resolvedUserCouponId) {
      return new Response(JSON.stringify({ error: "Coupons are not available for trust payments" }), {
        status: 400,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      });
    }

    let baseAmountCents: number;
    if (resolvedPaymentType === "wasiat") {
      baseAmountCents = expectedWasiatCents;
    } else {
      baseAmountCents = parseInt(String(amount), 10);
    }

    let finalAmountCents = baseAmountCents;
    let appliedDiscountPercent: number | null = null;

    if (resolvedUserCouponId) {
      const appliesTo: "hibah" | "wasiat" = resolvedPaymentType === "hibah"
        ? "hibah"
        : "wasiat";
      const v = await validateUserCoupon(supabaseAdmin, userId, resolvedUserCouponId, appliesTo);
      if (!v.ok) {
        return new Response(JSON.stringify({ error: v.message }), {
          status: 400,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        });
      }
      appliedDiscountPercent = v.discountPercent;
      finalAmountCents = Math.floor(baseAmountCents * (100 - v.discountPercent) / 100);
      if (finalAmountCents < 1) {
        return new Response(JSON.stringify({ error: "Discounted amount is too small" }), {
          status: 400,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        });
      }
    } else if (resolvedPaymentType === "wasiat") {
      const got = parseInt(String(amount), 10);
      if (got !== expectedWasiatCents) {
        return new Response(
          JSON.stringify({
            error: "Invalid amount for Wasiat annual plan",
            expected_cents: expectedWasiatCents,
          }),
          { status: 400, headers: corsHeaders({ "Content-Type": "application/json" }) },
        );
      }
    }

    // Verify userId matches authenticated user
    if (bodyUserId && bodyUserId !== userId) {
      return new Response(JSON.stringify({ error: "User ID mismatch" }), {
        status: 403,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      });
    }

    // Create payment record in the correct table first
    console.log("🟢 [CHIP-CREATE-PAYMENT] Creating payment record in database");
    const sessionInsert =
      resolvedPaymentType === "hibah"
        ? {
            hibah_id: hibahId,
            user_id: userId,
            amount: finalAmountCents,
            original_amount: baseAmountCents / 100,
            discount_amount: resolvedUserCouponId
              ? (baseAmountCents - finalAmountCents) / 100
              : 0,
            status: "initiated",
            chip_client_id: clientId,
            ...(resolvedUserCouponId ? { user_coupon_id: resolvedUserCouponId } : {}),
            created_at: new Date().toISOString(),
          }
        : resolvedPaymentType === "wasiat"
          ? {
              user_id: userId,
              amount: finalAmountCents,
              ...(resolvedUserCouponId
                ? {
                  user_coupon_id: resolvedUserCouponId,
                  original_amount_cents: baseAmountCents,
                }
                : {}),
              status: "initiated",
              chip_client_id: clientId,
              created_at: new Date().toISOString(),
            }
          : {
              trust_id: parseInt(trustId, 10),
              uuid: userId,
              amount: parseInt(amount, 10),
              status: "initiated",
              chip_client_id: clientId,
              created_at: new Date().toISOString(),
            };

    const sessionTable =
      resolvedPaymentType === "hibah"
        ? "hibah_payments"
        : resolvedPaymentType === "wasiat"
          ? "wasiat_subscription_payments"
          : "trust_payments";

    const { data: sessionData, error: sessionError } = await supabaseAdmin
      .from(sessionTable)
      .insert(sessionInsert)
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

    // Trust uses a separate CHIP merchant (keys + brand) from Hibah/Wasiat.
    const useTrustMerchant = resolvedPaymentType === "trust";
    const CHIP_SECRET_KEY = useTrustMerchant
      ? Deno.env.get("CHIP_TRUST_SECRET_KEY")
      : Deno.env.get("CHIP_SECRET_KEY");
    const CHIP_BRAND_ID = useTrustMerchant
      ? Deno.env.get("CHIP_TRUST_BRAND_ID")
      : Deno.env.get("CHIP_BRAND_ID");

    if (!CHIP_SECRET_KEY || !CHIP_BRAND_ID) {
      const main = Deno.env.get("CHIP_SECRET_KEY") && Deno.env.get("CHIP_BRAND_ID");
      const trust = Deno.env.get("CHIP_TRUST_SECRET_KEY") && Deno.env.get("CHIP_TRUST_BRAND_ID");
      console.log("🔴 [CHIP-CREATE-PAYMENT] CHIP credentials not configured for", useTrustMerchant ? "trust" : "main");
      console.log("🔴 [CHIP-CREATE-PAYMENT] main merchant complete:", !!main);
      console.log("🔴 [CHIP-CREATE-PAYMENT] trust merchant complete:", !!trust);
      return new Response(
        JSON.stringify({
          error: useTrustMerchant
            ? "Trust CHIP credentials not configured (CHIP_TRUST_SECRET_KEY, CHIP_TRUST_BRAND_ID)"
            : "CHIP credentials not configured (CHIP_SECRET_KEY, CHIP_BRAND_ID)",
        }),
        {
          status: 500,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    console.log("🟢 [CHIP-CREATE-PAYMENT] CHIP credentials found for", useTrustMerchant ? "trust" : "main");
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
    const chipPurchaseAmount = resolvedPaymentType === "trust"
      ? parseInt(String(amount), 10)
      : finalAmountCents;

    const chipPayload = {
      brand_id: CHIP_BRAND_ID,
      client_id: clientId,
      success_callback: successCallback,
      success_redirect: finalSuccessUrl,
      failure_redirect: finalFailureUrl,
      send_receipt: true,
      purchase: {
        amount: chipPurchaseAmount,
        products: [
          {
            name:
              description ||
              (resolvedPaymentType === "hibah"
                ? `Payment for Hibah ${certificateId}`
                : resolvedPaymentType === "wasiat"
                  ? "Wasiat — annual access"
                  : `Payment for Trust ${trustCode}`),
            price: chipPurchaseAmount,
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
        .from(sessionTable)
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
      .from(sessionTable)
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
