// @ts-nocheck
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

function corsHeaders(extra: Record<string, string> = {}) {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    ...extra,
  };
}

function jsonResponse(payload: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: corsHeaders({ "Content-Type": "application/json" }),
  });
}

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function buildExecutorInvitationEmailHtml(params: {
  executorName: string;
  addedByName: string;
  recipientEmail: string;
  appHost: string;
  contactEmail: string;
  twitterUrl: string;
  facebookUrl: string;
  instagramUrl: string;
  executorCode?: string;
}): string {
  const {
    executorName,
    addedByName,
    recipientEmail,
    appHost,
    contactEmail,
    twitterUrl,
    facebookUrl,
    instagramUrl,
    executorCode,
  } = params;

  const displayCode = (executorCode ?? "").trim();
  const codeHtml = displayCode
    ? `
      <div style="background:#F9FAFB;border:1px solid #E4E7EC;border-radius:8px;padding:16px;margin:20px 0;">
        <p style="margin:0;color:#101828;font-size:14px;font-weight:600;">Reference code</p>
        <p style="margin:8px 0 0 0;color:#475467;font-size:16px;font-family:monospace;">${displayCode}</p>
      </div>
    `
    : "";

  return `
    <div style="padding:32px 24px;background-color:#FFFFFF;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;">
      <img
        src="https://sampul.co/images/Email_sampul_background.png"
        alt="Sampul"
        style="width:100%;max-width:640px;height:auto;border:0;display:block;"
      />

      <h1 style="width:100%;color:#101828;font-size:36px;font-weight:600;line-height:44px;margin:25px 0;">
        Salam and greetings ${executorName},
      </h1>

      <div style="color:#475467;font-size:18px;font-weight:400;line-height:28px;">
        <p style="margin:0 0 20px 0;">
          ${addedByName} has added you as their <span style="color:#2F1DA9;">executor</span> in Sampul.
        </p>
        <p style="margin:0 0 20px 0;">
          This means you may be contacted in the future to help carry out their wishes and support their loved ones with estate matters.
        </p>
        <p style="margin:0 0 20px 0;">
          No action is needed right now. We are sharing this early so everything stays clear for everyone.
        </p>
      </div>

      ${codeHtml}

      <div style="margin:24px 0 10px 0;">
        <a
          href="${appHost}/signin"
          style="display:inline-block;padding:0.5rem 1rem;font-size:1.05rem;font-weight:500;line-height:1.5;text-align:center;text-decoration:none;border:1px solid transparent;border-radius:0.5rem;color:#FFFFFF;background-color:#3c22e2;"
        >
          Open Sampul
        </a>
      </div>

      <div style="width:150px;height:2px;background:#EAECF0;margin:35px 0;"></div>

      <div style="color:#475467;font-size:18px;line-height:28px;margin-bottom:24px;">
        <p style="margin:0 0 12px 0;">
          If you have any questions, you can reach us at
          <span style="color:#2F1DA9;">${contactEmail}</span>.
        </p>
        <p style="margin:0;">
          — The Sampul team
        </p>
      </div>

      <div style="color:#475467;font-size:16px;line-height:24px;margin-bottom:24px;">
        This email was sent to <span style="color:#2F1DA9;">${recipientEmail}</span>.<br />
        © 2026 sampul.co
      </div>

      <div style="display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap;margin-top:24px;">
        <a href="${appHost}" style="margin-right:auto;">
          <img
            src="https://sampul.co/images/Logo.png"
            alt="Sampul"
            style="height:30px;width:auto;border:0;display:block;"
          />
        </a>
        <div>
          <a href="${twitterUrl}" style="margin-right:10px;text-decoration:none;">
            <img src="https://sampul.co/images/Social_icon_x.png" alt="X" style="height:30px;width:auto;border:0;" />
          </a>
          <a href="${facebookUrl}" style="margin-right:10px;text-decoration:none;">
            <img src="https://sampul.co/images/Social_icon_facebook.png" alt="Facebook" style="height:30px;width:auto;border:0;" />
          </a>
          <a href="${instagramUrl}" style="text-decoration:none;">
            <img src="https://sampul.co/images/Social_icon_instagram.png" alt="Instagram" style="height:30px;width:auto;border:0;" />
          </a>
        </div>
      </div>
    </div>
  `;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const fromEmail = Deno.env.get("RESEND_FROM_EMAIL") ?? "Sampul <noreply@sampul.co>";
    const appHost = Deno.env.get("APP_HOST") ?? "https://sampul.co";
    const contactEmail = Deno.env.get("CONTACT_EMAIL") ?? "hello@sampul.co";
    const twitterUrl = Deno.env.get("TWITTER_URL") ?? "https://x.com/sampulco";
    const facebookUrl = Deno.env.get("FACEBOOK_URL") ?? "https://facebook.com";
    const instagramUrl = Deno.env.get("INSTAGRAM_URL") ?? "https://instagram.com";

    if (!supabaseUrl || !serviceKey) {
      return jsonResponse({ error: "Server configuration error" }, 500);
    }

    if (!resendApiKey) {
      return jsonResponse({ error: "RESEND_API_KEY is missing" }, 500);
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceKey);

    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.startsWith("Bearer ")
      ? authHeader.slice("Bearer ".length)
      : "";

    if (!token) {
      return jsonResponse({ error: "Missing bearer token" }, 401);
    }

    const { data: userData, error: userError } = await supabaseAdmin.auth.getUser(token);
    const userId = userData?.user?.id ?? null;
    if (userError || !userId) {
      return jsonResponse({ error: "Invalid token" }, 401);
    }

    const body = await req.json().catch(() => null);
    const belovedIdRaw = body?.belovedId;
    const legacyExecutorCode = typeof body?.executorCode === "string" ? body.executorCode.trim() : "";
    const belovedId = Number(belovedIdRaw);
    if (!Number.isInteger(belovedId) || belovedId <= 0) {
      return jsonResponse({ error: "belovedId is required" }, 400);
    }

    const { data: beloved, error: belovedError } = await supabaseAdmin
      .from("beloved")
      .select("id, uuid, type, name, email")
      .eq("id", belovedId)
      .eq("uuid", userId)
      .maybeSingle();

    if (belovedError) {
      return jsonResponse({ error: "Failed to load family member" }, 500);
    }

    if (!beloved) {
      return jsonResponse({ error: "Family member not found" }, 404);
    }

    if (beloved.type !== "co_sampul") {
      return jsonResponse({ sent: false, reason: "not_executor" }, 200);
    }

    const recipientEmail = (beloved.email ?? "").trim();
    if (!recipientEmail || !isValidEmail(recipientEmail)) {
      return jsonResponse({ sent: false, reason: "invalid_recipient_email" }, 200);
    }

    const { data: profileData } = await supabaseAdmin
      .from("profiles")
      .select("nric_name, username")
      .eq("uuid", userId)
      .maybeSingle();

    const addedByName = (profileData?.nric_name || profileData?.username || "A Sampul user").trim();
    const executorName = (beloved.name ?? "there").trim();

    const subject = "You were added as an executor on Sampul";
    const html = buildExecutorInvitationEmailHtml({
      executorName,
      addedByName,
      recipientEmail,
      appHost,
      contactEmail,
      twitterUrl,
      facebookUrl,
      instagramUrl,
      executorCode: legacyExecutorCode || `CO-SAMPUL-${beloved.id}`,
    });
    const text = [
      `Hi ${executorName},`,
      "",
      `${addedByName} added you as an executor in Sampul.`,
      "As an executor, you may be contacted later to help carry out their wishes.",
      "No action is needed right now. This message is just to keep you informed.",
      "",
      "Thank you,",
      "Sampul Team",
    ].join("\n");

    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [recipientEmail],
        subject,
        html,
        text,
      }),
    });

    if (!resendResponse.ok) {
      const resendError = await resendResponse.text();
      console.error("executor-registration-email: resend failed", resendError);
      return jsonResponse({ error: "Failed to send email" }, 502);
    }

    return jsonResponse({ sent: true }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("executor-registration-email: unhandled error", message);
    return jsonResponse({ error: message }, 500);
  }
});
