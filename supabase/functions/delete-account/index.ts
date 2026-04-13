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
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({
        error: { message: "Method Not Allowed. Only POST is supported." },
      }),
      {
        status: 405,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      },
    );
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceKey) {
    return new Response(
      JSON.stringify({
        error: {
          message: "Server configuration error",
          details: { has_url: !!supabaseUrl, has_service_key: !!serviceKey },
        },
      }),
      {
        status: 500,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      },
    );
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceKey);

  // Authenticate user via Bearer token
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.startsWith("Bearer ")
    ? authHeader.slice("Bearer ".length)
    : "";

  if (!token) {
    return new Response(
      JSON.stringify({ error: { message: "Missing bearer token" } }),
      {
        status: 401,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      },
    );
  }

  const { data: userData, error: userError } = await supabaseAdmin.auth.getUser(
    token,
  );
  const userId = userData?.user?.id ?? null;

  if (userError || !userId) {
    return new Response(
      JSON.stringify({ error: { message: "Invalid or expired token" } }),
      {
        status: 401,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      },
    );
  }

  try {
    // Look up account row to check subscription status
    const { data: accounts, error: accountsError } = await supabaseAdmin
      .from("accounts")
      .select("*")
      .eq("uuid", userId);

    if (accountsError) {
      return new Response(
        JSON.stringify({ error: { message: accountsError.message } }),
        {
          status: 400,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    if (!accounts || accounts.length === 0) {
      return new Response(
        JSON.stringify({
          error: { message: "Account doesn't exist." },
        }),
        {
          status: 400,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    const account = accounts[0] as {
      is_subscribed?: boolean | null;
      wasiat_subscription_period_end?: string | null;
    };

    const endRaw = account.wasiat_subscription_period_end;
    const hasActiveWasiatWindow =
      typeof endRaw === "string" &&
      endRaw.length > 0 &&
      new Date(endRaw).getTime() > Date.now();

    const legacyStripeOnlySubscribed =
      account.is_subscribed === true &&
      (endRaw == null || String(endRaw).length === 0);

    if (hasActiveWasiatWindow || legacyStripeOnlySubscribed) {
      return new Response(
        JSON.stringify({
          error: {
            message:
              "If you want to delete your profile, you need to wait until your Wasiat access period has ended, or contact support if you subscribed through another channel.",
          },
        }),
        {
          status: 400,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    // Delete the user via admin API
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
      userId,
    );

    if (deleteError) {
      return new Response(
        JSON.stringify({ error: { message: deleteError.message } }),
        {
          status: 400,
          headers: corsHeaders({ "Content-Type": "application/json" }),
        },
      );
    }

    return new Response(
      JSON.stringify({ data: { deleted: true } }),
      {
        status: 200,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      },
    );
  } catch (err) {
    console.error("delete-account edge function error:", err);
    return new Response(
      JSON.stringify({ error: { message: "Internal Server Error" } }),
      {
        status: 500,
        headers: corsHeaders({ "Content-Type": "application/json" }),
      },
    );
  }
});

