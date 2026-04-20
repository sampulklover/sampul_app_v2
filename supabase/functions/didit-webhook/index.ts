import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const JSON_HEADERS = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-Signature, X-Timestamp",
};

function jsonResponse(payload: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(payload), { status, headers: JSON_HEADERS });
}

function logInfo(message: string, data: Record<string, unknown> = {}): void {
  console.log(`didit-webhook: ${message}`, data);
}

function logWarn(message: string, data: Record<string, unknown> = {}): void {
  console.warn(`didit-webhook: ${message}`, data);
}

function logError(message: string, data: Record<string, unknown> = {}): void {
  console.error(`didit-webhook: ${message}`, data);
}

function normalizeSignature(rawSignature: string): string[] {
  return rawSignature
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean)
    // Only strip known keyed formats like "v1=...", "sig=...", "signature=...".
    // Do not strip plain base64 values that contain "=" padding.
    .map((s) => /^(v\d+|sig|signature)=/i.test(s) ? s.split("=").slice(1).join("=").trim() : s)
    .map((s) => s.toLowerCase());
}

function hexToBytes(hex: string): Uint8Array {
  const cleanHex = hex.trim().toLowerCase();
  if (cleanHex.length % 2 !== 0) throw new Error("Invalid hex length");
  const bytes = new Uint8Array(cleanHex.length / 2);
  for (let i = 0; i < cleanHex.length; i += 2) {
    bytes[i / 2] = Number.parseInt(cleanHex.slice(i, i + 2), 16);
  }
  return bytes;
}

function timingSafeEqualBytes(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i += 1) {
    diff |= a[i] ^ b[i];
  }
  return diff === 0;
}

function isLikelyHex(input: string): boolean {
  return /^[0-9a-f]+$/i.test(input) && input.length % 2 === 0;
}

function base64ToBytes(input: string): Uint8Array {
  const normalized = input.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

async function hmacBytes(secret: string, message: string): Promise<Uint8Array> {
  const encoder = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(message));
  return new Uint8Array(signature);
}

async function verifyWebhookSignature(opts: {
  bodyText: string;
  timestamp: string;
  signatureHeader: string;
  webhookSecret: string;
}): Promise<boolean> {
  const { bodyText, timestamp, signatureHeader, webhookSecret } = opts;
  const providedSignatures = normalizeSignature(signatureHeader);
  if (providedSignatures.length === 0) return false;

  // Support both likely payload concatenation formats for compatibility.
  const candidates = await Promise.all([
    hmacBytes(webhookSecret, `${timestamp}.${bodyText}`),
    hmacBytes(webhookSecret, `${bodyText}${timestamp}`),
    hmacBytes(webhookSecret, `${timestamp}${bodyText}`),
  ]);

  for (const provided of providedSignatures) {
    try {
      const providedBytes = isLikelyHex(provided)
        ? hexToBytes(provided)
        : base64ToBytes(provided);
      for (const candidate of candidates) {
        if (timingSafeEqualBytes(providedBytes, candidate)) {
          return true;
        }
      }
    } catch {
      // Ignore malformed signature fragment and continue.
    }
  }
  return false;
}

function mapDiditStatus(raw: string): {
  verificationStatus: string;
  kycStatus: string | null;
  isCompleted: boolean;
} {
  const diditStatus = raw.toLowerCase();
  switch (diditStatus) {
    case "completed":
    case "verified":
    case "approved":
    case "accepted":
    case "success":
    case "passed":
    case "pass":
      return { verificationStatus: "verified", kycStatus: diditStatus, isCompleted: true };
    case "declined":
    case "rejected":
    case "failed":
    case "denied":
      return { verificationStatus: "rejected", kycStatus: diditStatus, isCompleted: true };
    case "pending":
    case "in_progress":
    case "processing":
    case "in_review":
    case "review":
    case "not started":
      return { verificationStatus: "pending", kycStatus: "pending", isCompleted: false };
    case "expired":
      return { verificationStatus: "rejected", kycStatus: "expired", isCompleted: true };
    case "cancelled":
    case "canceled":
      return { verificationStatus: "pending", kycStatus: null, isCompleted: false };
    default:
      // Unknown statuses should not downgrade account KYC.
      return { verificationStatus: "pending", kycStatus: null, isCompleted: false };
  }
}

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();

  if (req.method === "OPTIONS") {
    logInfo("cors preflight", { request_id: requestId });
    return new Response(null, { status: 204, headers: JSON_HEADERS });
  }

  if (req.method !== "POST") {
    logWarn("invalid method", { request_id: requestId, method: req.method });
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const bodyText = await req.text();
    let body: any;
    try {
      body = JSON.parse(bodyText);
    } catch {
      logWarn("invalid json payload", { request_id: requestId, body_length: bodyText.length });
      return jsonResponse({ error: "Invalid JSON payload" }, 400);
    }

    const webhookSecret = Deno.env.get("DIDIT_WEBHOOK_SECRET_KEY");
    const signature = req.headers.get("X-Signature") ?? req.headers.get("x-signature");
    const timestamp = req.headers.get("X-Timestamp") ?? req.headers.get("x-timestamp");
    logInfo("incoming request", {
      request_id: requestId,
      has_webhook_secret: !!webhookSecret,
      has_signature: !!signature,
      has_timestamp: !!timestamp,
      signature_length: signature?.length ?? 0,
      timestamp_length: timestamp?.length ?? 0,
    });

    if (webhookSecret) {
      if (!signature || !timestamp) {
        logWarn("missing signature headers", {
          request_id: requestId,
          has_signature: !!signature,
          has_timestamp: !!timestamp,
        });
        return jsonResponse({ error: "Missing signature headers" }, 401);
      }
      const isValidSignature = await verifyWebhookSignature({
        bodyText,
        timestamp,
        signatureHeader: signature,
        webhookSecret,
      });
      if (!isValidSignature) {
        logWarn("signature verification failed", {
          request_id: requestId,
          webhook_type: body?.webhook_type ?? null,
          session_id: body?.session_id ?? null,
          vendor_data_present: !!body?.vendor_data,
        });
        return jsonResponse({ error: "Invalid signature" }, 401);
      }
      logInfo("signature verification passed", { request_id: requestId });
    }

    const webhookType = body.webhook_type as string | undefined;
    if (webhookType && webhookType !== "status.updated") {
      logInfo("ignored webhook type", { request_id: requestId, webhook_type: webhookType });
      return jsonResponse({ received: true, ignored: true, reason: "Unsupported webhook_type" }, 200);
    }

    const diditSessionId = body.session_id as string | undefined;
    const vendorData = body.vendor_data as string | undefined;
    const decisionStatus = body?.decision?.status as string | undefined;
    const rootStatus = body?.status as string | undefined;
    const diditStatusRaw = (decisionStatus ?? rootStatus ?? "").trim();
    logInfo("parsed webhook payload", {
      request_id: requestId,
      webhook_type: webhookType ?? null,
      session_id: diditSessionId ?? null,
      has_vendor_data: !!vendorData,
      raw_status: diditStatusRaw || null,
    });

    if (!vendorData && !diditSessionId) {
      logWarn("missing session identifier", { request_id: requestId });
      return jsonResponse({ error: "Missing session identifier" }, 400);
    }
    if (!diditStatusRaw) {
      logWarn("missing status field", { request_id: requestId });
      return jsonResponse({ error: "Missing status in payload" }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !supabaseServiceKey) {
      logError("missing supabase env", {
        request_id: requestId,
        has_url: !!supabaseUrl,
        has_service_key: !!supabaseServiceKey,
      });
      return jsonResponse(
        {
          error: "Server configuration error",
          details: {
            has_url: !!supabaseUrl,
            has_service_key: !!supabaseServiceKey,
          },
        },
        500,
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    let verification: { id: number; uuid: string; didit_session_id: string | null } | null = null;
    let verificationError: any = null;

    if (vendorData) {
      const result = await supabase
        .from("verification")
        .select("id, uuid, didit_session_id")
        .eq("session_id", vendorData)
        .maybeSingle();
      verification = result.data;
      verificationError = result.error;
    }

    if (!verification && diditSessionId) {
      const result = await supabase
        .from("verification")
        .select("id, uuid, didit_session_id")
        .eq("didit_session_id", diditSessionId)
        .maybeSingle();
      verification = result.data;
      verificationError = result.error;
    }

    if (verificationError || !verification) {
      logWarn("verification record not found", {
        request_id: requestId,
        didit_session_id: diditSessionId ?? null,
        vendor_data: vendorData ?? null,
        lookup_error: verificationError?.message ?? null,
      });
      return jsonResponse({ error: "Verification record not found" }, 404);
    }

    const mapped = mapDiditStatus(diditStatusRaw);
    logInfo("status mapped", {
      request_id: requestId,
      verification_id: verification.id,
      user_uuid: verification.uuid,
      verification_status: mapped.verificationStatus,
      kyc_status: mapped.kycStatus,
    });
    const nowIso = new Date().toISOString();

    const updateData: Record<string, unknown> = {
      status: mapped.verificationStatus,
      updated_at: nowIso,
      metadata: body,
    };
    if (mapped.isCompleted) {
      updateData.completed_at = nowIso;
    }

    if (mapped.verificationStatus === "rejected") {
      const decision = body?.decision;
      const allWarnings: any[] = [
        ...(decision?.id_verification?.warnings ?? []),
        ...(decision?.liveness?.warnings ?? []),
        ...(decision?.face_match?.warnings ?? []),
      ];
      const errorMessages = allWarnings
        .filter((w: any) => w?.log_type === "error")
        .map((w: any) => w?.short_description ?? w?.long_description)
        .filter(Boolean)
        .join("; ");
      if (errorMessages) {
        updateData.error_message = errorMessages;
      }
    }

    if (diditSessionId && !verification.didit_session_id) {
      updateData.didit_session_id = diditSessionId;
    }

    const { error: verificationUpdateError } = await supabase
      .from("verification")
      .update(updateData)
      .eq("id", verification.id);

    if (verificationUpdateError) {
      logError("failed to update verification", {
        request_id: requestId,
        verification_id: verification.id,
        message: verificationUpdateError.message,
      });
      return jsonResponse({ error: "Failed to update verification" }, 500);
    }

    logInfo("webhook processed successfully", {
      request_id: requestId,
      verification_id: verification.id,
      user_uuid: verification.uuid,
      verification_status: mapped.verificationStatus,
      kyc_status: mapped.kycStatus,
    });

    return jsonResponse(
      {
        received: true,
        verification_status: mapped.verificationStatus,
        kyc_status: mapped.kycStatus,
      },
      200,
    );
  } catch (e) {
    const errorMessage = e instanceof Error ? e.message : String(e);
    logError("unhandled error", { request_id: requestId, message: errorMessage });
    return jsonResponse({ error: `Webhook Error: ${errorMessage}` }, 400);
  }
});

