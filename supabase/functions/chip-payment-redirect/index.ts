// CHIP Payment Redirect Handler
// Serves simple HTML pages that redirect to deep links
// This allows CHIP to redirect to HTTP URLs while still opening the app via deep link
//
// Usage:
// - Success: https://xxx.supabase.co/functions/v1/chip-payment-redirect?status=success
// - Failure: https://xxx.supabase.co/functions/v1/chip-payment-redirect?status=failed

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
