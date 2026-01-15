// Didit Webhook Handler
// Updates verification table (session tracking) and accounts.kyc_status (user verification status)
// Similar pattern to stripe-webhook

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
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
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json" } }
    );
  }

  try {
    // Get request body as text first (like Stripe webhook)
    const bodyText = await req.text();
    let body: any;
    
    try {
      body = JSON.parse(bodyText);
    } catch (e) {
      return new Response(
        JSON.stringify({ error: "Invalid JSON payload" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const headers = req.headers;
    
    // Webhook secret for verifying Didit webhook requests (optional for now)
    const webhookSecret = Deno.env.get("DIDIT_WEBHOOK_SECRET_KEY");

    // Verify webhook signature (Didit uses X-Signature and X-Timestamp headers)
    const signature = headers.get("X-Signature") || headers.get("x-signature");
    const timestamp = headers.get("X-Timestamp") || headers.get("x-timestamp");
    
    // TODO: Implement signature verification based on Didit's documentation
    // Didit likely uses: HMAC-SHA256(body + timestamp, secret)
    // For now, we'll trust requests (you should implement proper verification)
    // if (webhookSecret && signature && timestamp) {
    //   const expectedSignature = calculateSignature(bodyText, timestamp, webhookSecret);
    //   if (signature !== expectedSignature) {
    //     return new Response("Invalid signature", { status: 401 });
    //   }
    // }

    // Extract event data from Didit webhook
    // Based on actual Didit webhook payload structure
    const webhookType = body.webhook_type; // e.g., "status.updated"
    const diditSessionId = body.session_id; // Didit's session ID (e.g., "726f2d35-354f-44f3-8398-54e72cd0352b")
    const vendorData = body.vendor_data; // Our internal session_id (e.g., "didit_1767534073475_073475")
    const status = body.status; // Overall status (e.g., "Declined", "Approved")
    const decision = body.decision; // Decision object with detailed status
    const decisionStatus = decision?.status; // Decision status (e.g., "Approved", "Declined")
    const metadata = body; // Store full payload

    if (!vendorData && !diditSessionId) {
      return new Response(
        JSON.stringify({ error: "Missing session identifier" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Get Supabase credentials
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
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

    const supabase = createClient(
      supabaseUrl,
      supabaseServiceKey, // service role for bypassing RLS
    );

    // Find verification record by session_id (vendor_data) or didit_session_id
    // vendor_data is our internal session_id, so try that first
    let { data: verification, error: verificationError } = await supabase
      .from("verification")
      .select("id, uuid, session_id, didit_session_id")
      .eq("session_id", vendorData)
      .maybeSingle();

    // If not found by vendor_data, try by didit_session_id
    if (!verification && diditSessionId) {
      const result = await supabase
        .from("verification")
        .select("id, uuid, session_id, didit_session_id")
        .eq("didit_session_id", diditSessionId)
        .maybeSingle();
      verification = result.data;
      verificationError = result.error;
    }

    if (verificationError || !verification) {
      return new Response(
        JSON.stringify({ error: "Verification record not found" }),
        { status: 404 }
      );
    }

    const userUuid = verification.uuid;

    // Map Didit status to common status values
    // Didit uses: "Approved", "Declined", "Pending", etc. (capitalized)
    // Use decision.status if available, otherwise use root status
    // kyc_status uses: approved, pending, accepted, rejected, declined (text field)
    const diditStatus = (decisionStatus || status || "").toLowerCase();
    let mappedStatus: string; // For verification.status (flexible text)
    let kycStatus: string | null = null; // For accounts.kyc_status (standard values)

    switch (diditStatus) {
      case "approved":
        mappedStatus = "approved";
        kycStatus = "approved";
        break;
      case "declined":
        mappedStatus = "declined";
        kycStatus = "declined";
        break;
      case "accepted":
        mappedStatus = "accepted";
        kycStatus = "accepted";
        break;
      case "rejected":
        mappedStatus = "rejected";
        kycStatus = "rejected";
        break;
      case "pending":
      case "in_progress":
      case "processing":
      case "not started":
        mappedStatus = "pending";
        kycStatus = "pending";
        break;
      case "expired":
        mappedStatus = "expired";
        kycStatus = "expired";
        break;
      case "cancelled":
      case "canceled":
        mappedStatus = "cancelled";
        // Don't update kyc_status if cancelled (keep previous state)
        kycStatus = null;
        break;
      default:
        // Keep original status if unknown, but normalize to lowercase
        mappedStatus = diditStatus || "pending";
        kycStatus = "pending";
    }

    // Update verification table (session tracking)
    const updateData: Record<string, any> = {
      status: mappedStatus,
      updated_at: new Date().toISOString(),
      metadata: metadata,
    };

    // Set completed_at if verification is completed (approved, declined, rejected, accepted)
    if (["approved", "declined", "rejected", "accepted"].includes(mappedStatus)) {
      updateData.completed_at = new Date().toISOString();
    }

    // Add error message if verification was declined
    // Check for warnings/errors in decision object
    if (mappedStatus === "declined" || mappedStatus === "rejected") {
      const allWarnings: any[] = [
        ...(decision?.id_verification?.warnings || []),
        ...(decision?.liveness?.warnings || []),
        ...(decision?.face_match?.warnings || []),
      ];
      
      const errorMessages = allWarnings
        .filter((w: any) => w.log_type === "error")
        .map((w: any) => w.short_description || w.long_description)
        .filter(Boolean)
        .join("; ");
      
      if (errorMessages) {
        updateData.error_message = errorMessages;
      }
    }

    // Update didit_session_id if not already set
    if (diditSessionId && !verification.didit_session_id) {
      updateData.didit_session_id = diditSessionId;
    }

    const { error: updateError } = await supabase
      .from("verification")
      .update(updateData)
      .eq("id", verification.id);

    if (updateError) {
      return new Response(
        JSON.stringify({ error: "Failed to update verification" }),
        { status: 500 }
      );
    }

    // Update accounts.kyc_status (user's actual verification status)
    if (kycStatus && userUuid) {
      // Ensure accounts row exists for user
      const { data: account } = await supabase
        .from("accounts")
        .select("uuid")
        .eq("uuid", userUuid)
        .single();

      if (!account) {
        // Create accounts row if it doesn't exist
        const { error: createError } = await supabase
          .from("accounts")
          .insert({
            uuid: userUuid,
            kyc_status: kycStatus,
          });

        if (createError) {
          // Silently fail - account creation error
        }
      } else {
        // Update existing accounts row
        const { error: accountUpdateError } = await supabase
          .from("accounts")
          .update({ kyc_status: kycStatus })
          .eq("uuid", userUuid);

        if (accountUpdateError) {
          // Silently fail - account update error
        }
      }
    }

    return new Response(
      JSON.stringify({ 
        received: true, 
        status: mappedStatus,
        kyc_status: kycStatus,
      }),
      { 
        status: 200,
        headers: { "Content-Type": "application/json" }
      }
    );
  } catch (e) {
    const errorMessage = e instanceof Error ? e.message : String(e);
    return new Response(
      JSON.stringify({ error: `Webhook Error: ${errorMessage}` }),
      { 
        status: 400,
        headers: { "Content-Type": "application/json" }
      }
    );
  }
});

