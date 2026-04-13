// CHIP Payment Redirect Handler
// Redirects CHIP HTTP return URLs into deep links, and (best-effort) marks
// cancelled flows in our DB so coupons are not left "locked" to a pending checkout.
//
// Usage:
// - Success: https://xxx.supabase.co/functions/v1/chip-payment-redirect?status=success
// - Failure: https://xxx.supabase.co/functions/v1/chip-payment-redirect?status=failed
//
// Some CHIP redirect flows append a purchase id in the querystring; when present
// we update the matching payment row(s) by `chip_payment_id`.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

function pickPurchaseId(url: URL): string | null {
  const candidates = [
    url.searchParams.get("id"),
    url.searchParams.get("purchase_id"),
    url.searchParams.get("purchaseId"),
    url.searchParams.get("transaction_id"),
  ].filter((v) => typeof v === "string" && v.length > 0) as string[];
  return candidates[0] ?? null;
}

async function markCancelledByChipPaymentId(chipPaymentId: string) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) return;

  const supabase = createClient(supabaseUrl, serviceKey);
  const cancelledAt = new Date().toISOString();

  // Best-effort updates across tables; ignore errors so redirect still works.
  await supabase
    .from("hibah_payments")
    .update({ status: "cancelled", updated_at: cancelledAt })
    .eq("chip_payment_id", chipPaymentId)
    .not("status", "in", "(paid,settled,cleared)");

  await supabase
    .from("wasiat_subscription_payments")
    .update({ status: "cancelled", updated_at: cancelledAt })
    .eq("chip_payment_id", chipPaymentId)
    .not("status", "in", "(paid,settled,cleared)");

  await supabase
    .from("trust_payments")
    .update({ status: "cancelled", updated_at: cancelledAt })
    .eq("chip_payment_id", chipPaymentId)
    .not("status", "in", "(paid,settled,cleared)");
}

Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
      },
    });
  }

  if (req.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const url = new URL(req.url);
    const status = url.searchParams.get("status") || "success";
    const chipPaymentId = pickPurchaseId(url);
    console.log("[chip-payment-redirect] url:", url.toString());
    console.log("[chip-payment-redirect] status:", status, "purchase_id:", chipPaymentId);

    // If user cancelled / failed and we know which purchase it was, mark it cancelled
    // so coupon reuse can proceed immediately.
    if (status !== "success" && chipPaymentId) {
      await markCancelledByChipPaymentId(chipPaymentId);
    }

    const deepLinkScheme = "sampul";
    
    // Determine deep link based on status
    const deepLink = status === "success" 
      ? `${deepLinkScheme}://trust?payment=success`
      : `${deepLinkScheme}://trust?payment=failed`;
    
    // Direct redirect to deep link (HTTP 302)
    // This will attempt to open the app directly without showing any HTML page
    return new Response(null, {
      status: 302,
      headers: {
        "Location": deepLink,
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    console.error("Redirect error:", error);
    return new Response("Error generating redirect page", { status: 500 });
  }
});
