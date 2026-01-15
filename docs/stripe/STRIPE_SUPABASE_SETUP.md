> **📘 Master Guide**: For complete pricing/subscription documentation including admin guide for managing plans, see [PRICING_SUBSCRIPTION_GUIDE.md](./PRICING_SUBSCRIPTION_GUIDE.md)

## Supabase + Stripe setup (using existing `public.accounts`)

No schema changes needed—`public.accounts` already stores subscription data:
- Link to user: `uuid` (FK to profiles)
- Stripe linkage: `stripe_customer`, `stripe_price_id`, `stripe_product`, `stripe_interval`
- State: `is_subscribed` (boolean)

### Quick steps checklist
1) Stripe: Grab your publishable key, secret key, webhook signing secret, and plan price IDs (free/secure).  
2) Supabase SQL (optional safety): `create extension if not exists http with schema extensions;`  
3) Supabase secrets: set `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` (webhook only).  
4) Deploy Edge Functions: `create-checkout-session`, `create-billing-portal`, `get-subscription`, `stripe-webhook` (webhook with `--no-verify-jwt`).  
5) Configure Stripe webhook to point to `stripe-webhook` function URL using the signing secret.  
6) Mobile `.env`: fill `STRIPE_PUBLISHABLE_KEY`, `STRIPE_MERCHANT_DISPLAY_NAME`, `STRIPE_RETURN_URL_SCHEME`, `STRIPE_PRICE_ID_FREE`, `STRIPE_PRICE_ID_SECURE`.  
7) App install: run `flutter pub get` (needs full perms locally).  
8) Test: open Settings → Plans & subscription; start checkout; confirm return URL; check `accounts` updates; open billing portal.

---

## Detailed step‑by‑step guide

### 1. Configure products and prices in Stripe
- **Create products**  
  - Go to Stripe Dashboard → **Products** → **Add product**.  
  - Example: `Free plan`, `Secure plan`.  
  - For each product, add a **Price** (e.g. recurring yearly `RM 180` for Secure, `RM 0` for Free if you want to keep it there for now).  
- **Get Price IDs**  
  - On each product’s page, scroll to **Pricing** → click the price row.  
  - Copy the **Price ID** (looks like `price_123...`).  
  - Put them into your project `.env` (or Supabase secrets if used there later):  
    - `STRIPE_PRICE_ID_FREE=price_xxx`  (not prduct id, not prod_XXX but price_xxx)
    - `STRIPE_PRICE_ID_SECURE=price_yyy`  

### 2. Get Stripe API keys
- In Stripe Dashboard, go to **Developers → API keys**.  
- Under **Standard keys**:
  - **Publishable key** → set in your Flutter `.env` as `STRIPE_PUBLISHABLE_KEY`.  
  - **Secret key** (use **restricted or secret key**, NOT publishable) → set in Supabase as `STRIPE_SECRET_KEY`.  
- Never commit the secret key to Git. It should only live in Supabase **Secrets** or your local `.env` for testing.

### 3. Create the webhook and get the signing secret
- In Stripe Dashboard, go to **Developers → Webhooks**.  
- Click **Add endpoint**:
  - **Endpoint URL**: after you deploy your `stripe-webhook` Edge Function, Supabase shows a URL like  
    `https://<PROJECT_REF>.functions.supabase.co/stripe-webhook`  
    Use that as the endpoint URL.  
  - **Version**: keep default/latest.  
  - **Events to send**: at minimum select:
    - `customer.subscription.created`
    - `customer.subscription.updated`
    - `customer.subscription.deleted`
- After saving, open the webhook you just created:
  - On the right side under **Signing secret**, click **Reveal**.  
  - Copy that value and set it as Supabase secret **`STRIPE_WEBHOOK_SECRET`**.

### 4. Set Supabase secrets
- In Supabase Dashboard → your project:
  - Go to **Project Settings → API** and note:
    - `SUPABASE_URL`
    - `anon` key (already used by the Flutter app)
    - `service_role` key (used only in the webhook function)  
  - Go to **Edge Functions → Secrets**:
    - Add/Update:
      - `STRIPE_SECRET_KEY` = your Stripe secret key  
      - `STRIPE_WEBHOOK_SECRET` = webhook signing secret from step 3  
      - `SUPABASE_SERVICE_ROLE_KEY` = service role key (only for `stripe-webhook`)  
      - (Optional, if you want functions to know anon key/URL) `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- CLI alternative (from your Supabase project root):
  ```bash
  supabase secrets set STRIPE_SECRET_KEY=sk_... STRIPE_WEBHOOK_SECRET=whsec_... SUPABASE_SERVICE_ROLE_KEY=service_role_...
  ```

### 5. Deploy Edge Functions
- Make sure you have the Supabase CLI installed (`npm i -g supabase`) and you’re logged in (`supabase login`).  
- From your backend repo (where `supabase/functions` folder lives):
  ```bash
  supabase functions deploy list-plans --project-ref <PROJECT_REF>
  supabase functions deploy create-checkout-session --project-ref <PROJECT_REF>
  supabase functions deploy create-billing-portal --project-ref <PROJECT_REF>
  supabase functions deploy get-subscription --project-ref <PROJECT_REF>
  supabase functions deploy stripe-webhook --project-ref <PROJECT_REF> --no-verify-jwt
  ```
- After deploying `stripe-webhook`, copy its public URL and ensure it matches the webhook URL in Stripe (step 3).

### 6. Configure Flutter `.env`
- In your Flutter project `.env` (copy from `ENV.example`):
  ```env
  STRIPE_PUBLISHABLE_KEY=pk_live_...
  STRIPE_MERCHANT_DISPLAY_NAME=Sampul
  STRIPE_RETURN_URL_SCHEME=sampul
  STRIPE_PRICE_ID_FREE=price_xxx
  STRIPE_PRICE_ID_SECURE=price_yyy
  ```
- Run `flutter pub get` and fully rebuild the app (not just hot reload) so the `flutter_stripe` plugin and new env values are applied.

### 7. Test the end‑to‑end flow
- **Mobile:**
  - Open the app → **Settings → Plans & subscription**.  
  - Confirm plans are loaded from Stripe (names/prices should match dashboard).  
  - Tap a paid plan → you should be redirected to Stripe Checkout. Complete test payment.  
  - After redirect back (or manually reopening the app), pull to refresh:
    - `public.accounts` row for your user should have `is_subscribed = true`, `stripe_price_id` set.  
    - The app should mark that plan as **Current** and show status `active`.
- **Webhook verification:**
  - In Stripe Dashboard → **Developers → Webhooks → Logs**, check that events to your endpoint are `200 OK`.  
  - If you see `400` or signature errors, double‑check `STRIPE_WEBHOOK_SECRET` in Supabase and redeploy `stripe-webhook`.

### Edge Function names (referenced by the app)
- `create-checkout-session`
- `create-billing-portal`
- `get-subscription`
- `list-plans` (optional, to fetch active Stripe prices/products for UI)
- Webhook: `stripe-webhook`

### Required secrets (Supabase Dashboard → Edge Functions → Secrets)
- `STRIPE_SECRET_KEY`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (optional – not needed if you always use service role)
- `SUPABASE_SERVICE_ROLE_KEY` (used by server-side functions that bypass RLS)
- `STRIPE_WEBHOOK_SECRET` (for `stripe-webhook`)

### .env keys already scaffolded in the app
- `STRIPE_PUBLISHABLE_KEY`
- `STRIPE_MERCHANT_DISPLAY_NAME`
- `STRIPE_RETURN_URL_SCHEME`
- `STRIPE_PRICE_ID_FREE`
- `STRIPE_PRICE_ID_SECURE`

### Suggested function behaviors
- `create-checkout-session`: find/create Stripe customer (metadata `supabase_user_id`), ensure an `accounts` row for the user, create Checkout Session for `priceId`, return `{ sessionUrl }`.
- `create-billing-portal`: use stored `stripe_customer` from `accounts` to create billing portal session, return `{ portalUrl }`. Uses **service role key** to read `accounts` even with RLS on.
- `get-subscription`: read from `accounts` (by `uuid`) and return `{ plan_id: stripe_price_id, plan_name: stripe_product, status: is_subscribed ? 'active' : 'inactive', interval: stripe_interval }`. Uses **service role key** so the mobile app always sees the latest subscription state.
- `stripe-webhook`: on `customer.subscription.*`, upsert `accounts` by `stripe_customer` (or by metadata `supabase_user_id`):
  - `stripe_price_id` = current price id
  - `stripe_product` = price.product
  - `stripe_interval` = price.recurring.interval
  - `is_subscribed` = subscription.status not in (`canceled`, `incomplete_expired`)
  - set `uuid` if missing using metadata

### Deployment (cli example)
```
supabase functions deploy create-checkout-session --project-ref <ref>
supabase functions deploy create-billing-portal --project-ref <ref>
supabase functions deploy get-subscription --project-ref <ref>
supabase functions deploy stripe-webhook --project-ref <ref> --no-verify-jwt
```

> Note: For webhooks, set the Stripe endpoint to the deployed `stripe-webhook` URL and use `STRIPE_WEBHOOK_SECRET`. Keep JWT verification off for webhooks; keep it on for the other functions.

### Edge Function code (Deno / TypeScript)
Create these files under your Supabase functions and deploy.  
They follow the official Supabase Stripe webhook example [`Handling Stripe Webhooks`](https://supabase.com/docs/guides/functions/examples/stripe-webhooks), using the `denonext` target which is compatible with the current Edge runtime.

#### `list-plans/index.ts` (optional, mirrors the web API you shared)
```ts
import Stripe from "https://esm.sh/stripe@14?target=denonext";

// Use the account's default Stripe API version (no explicit apiVersion here).
const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") as string);

Deno.serve(async (req) => {
  if (req.method !== "GET") {
    return new Response(JSON.stringify({ error: "Method Not Allowed" }), { status: 405 });
  }
  try {
    console.log('list-plans: fetching active prices from Stripe');
    const { data: prices } = await stripe.prices.list({
      expand: ["data.product"],
      active: true,
    });
    console.log(`list-plans: received ${prices.length} prices from Stripe`);

    const plans = prices
      .filter((p) => p.active && typeof p.product === "object" && p.product?.active)
      .map((p) => ({
        price_id: p.id,
        name: (p.product as Stripe.Product).name,
        price: p.unit_amount,
        interval: p.recurring?.interval ?? "one_time",
        currency: p.currency,
        product_id: (p.product as Stripe.Product).id,
        description: (p.product as Stripe.Product).description,
        active: (p.product as Stripe.Product).active,
      }))
      .sort((a, b) => (a.price ?? 0) - (b.price ?? 0));

    return Response.json({ plans });
  } catch (err) {
    return new Response(JSON.stringify({ error: "Error", err }), { status: 500 });
  }
});
```

#### `create-checkout-session/index.ts`
```ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import Stripe from "https://esm.sh/stripe@14?target=denonext";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") as string);

interface Body { priceId: string; successUrl: string; cancelUrl: string }

Deno.serve(async (req) => {
  try {
    // Use service role key so RLS on accounts doesn't hide the row.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );
    const authHeader = req.headers.get("Authorization") ?? "";
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
    if (authError || !user) return new Response("Unauthorized", { status: 401 });

    const { priceId, successUrl, cancelUrl } = (await req.json()) as Body;
    if (!priceId || !successUrl || !cancelUrl) {
      return new Response("Missing params", { status: 400 });
    }

    // Fetch account row
    const { data: accountRows } = await supabase
      .from("accounts")
      .select("*")
      .eq("uuid", user.id)
      .limit(1);
    const account = accountRows?.[0];

    // Reuse/create Stripe customer
    let customerId = account?.stripe_customer;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: user.email ?? undefined,
        metadata: { supabase_user_id: user.id },
      });
      customerId = customer.id;
      await supabase
        .from("accounts")
        .upsert({ uuid: user.id, stripe_customer: customerId });
    }

    console.log('create-checkout-session: creating session', {
      userId: user.id,
      priceId,
      customerId,
    });
    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: customerId,
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl,
      cancel_url: cancelUrl,
      subscription_data: {
        metadata: { supabase_user_id: user.id },
      },
      metadata: { supabase_user_id: user.id },
    });

    console.log('create-checkout-session: session created', {
      id: session.id,
      url: session.url,
    });
    return Response.json({ sessionUrl: session.url });
  } catch (e) {
    return new Response(`Error: ${e}`, { status: 500 });
  }
});
```

#### `create-billing-portal/index.ts`
```ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import Stripe from "https://esm.sh/stripe@14?target=denonext";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") as string);

interface Body { returnUrl: string }

Deno.serve(async (req) => {
  try {
    // Use service role key so RLS on accounts doesn't hide the row.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );
    const authHeader = req.headers.get("Authorization") ?? "";
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
    if (authError || !user) return new Response("Unauthorized", { status: 401 });

    const { returnUrl } = (await req.json()) as Body;
    if (!returnUrl) return new Response("Missing returnUrl", { status: 400 });

    const { data: accountRows, error } = await supabase
      .from("accounts")
      .select("stripe_customer")
      .eq("uuid", user.id)
      .limit(1);
    console.log('create-billing-portal: accountRows', accountRows, 'error', error);
    const customerId = accountRows?.[0]?.stripe_customer;
    if (!customerId) return new Response("No Stripe customer", { status: 400 });

    const portal = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: returnUrl,
    });

    return Response.json({ portalUrl: portal.url });
  } catch (e) {
    return new Response(`Error: ${e}`, { status: 500 });
  }
});
```

#### `get-subscription/index.ts`
```ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import Stripe from "https://esm.sh/stripe@14?target=denonext";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") as string);

Deno.serve(async (req) => {
  try {
    // Use service role key so RLS on accounts doesn't hide the row.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const authHeader = req.headers.get("Authorization") ?? "";
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
    if (authError || !user) return new Response("Unauthorized", { status: 401 });

    const { data: accountRows, error } = await supabase
      .from("accounts")
      .select("stripe_price_id, stripe_product, stripe_interval, is_subscribed")
      .eq("uuid", user.id)
      .limit(1);
    console.log('get-subscription: accountRows', accountRows, 'error', error);
    const account = accountRows?.[0];

    let priceName: string | null = account?.stripe_product ?? null;
    let amount: number | null = null;
    let currency: string | null = null;

    if (account?.stripe_price_id) {
      const price = await stripe.prices.retrieve(account.stripe_price_id);
      priceName =
        typeof price.nickname === "string"
          ? price.nickname
          : typeof price.product === "string"
            ? (await stripe.products.retrieve(price.product)).name
            : account.stripe_product ?? null;
      if (price.unit_amount && price.currency) {
        amount = price.unit_amount;
        currency = price.currency;
      }
    }

    return Response.json({
      plan_id: account?.stripe_price_id ?? null,
      plan_name: priceName,
      amount, // in smallest currency unit
      currency,
      interval: account?.stripe_interval ?? null,
      status: account?.is_subscribed ? "active" : "inactive",
    });
  } catch (e) {
    return new Response(`Error: ${e}`, { status: 500 });
  }
});
```

#### `stripe-webhook/index.ts` (JWT off)
```ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import Stripe from "https://esm.sh/stripe@14?target=denonext";

// Use your Stripe secret key (test or live) from Supabase secrets.
const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") as string);

// Use subtle crypto provider as in official Supabase example:
// https://supabase.com/docs/guides/functions/examples/stripe-webhooks
const cryptoProvider = Stripe.createSubtleCryptoProvider();
const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;

Deno.serve(async (req) => {
  try {
    const body = await req.text();
    const sig = req.headers.get("stripe-signature") ?? "";

    // IMPORTANT: use the async verifier with the subtle crypto provider
    const event = await stripe.webhooks.constructEventAsync(
      body,
      sig,
      webhookSecret,
      undefined,
      cryptoProvider,
    );

    if (event.type.startsWith("customer.subscription.")) {
      const sub = event.data.object as Stripe.Subscription;
      const price = sub.items.data[0]?.price;
      const supabaseUserId =
        (sub.metadata?.supabase_user_id as string | undefined) ??
        (typeof sub.customer === "string" ? sub.customer : undefined);

      const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, // service role
      );

      if (supabaseUserId) {
        await supabase.from("accounts").upsert(
          {
            uuid: supabaseUserId,
            stripe_customer:
              typeof sub.customer === "string" ? sub.customer : undefined,
            stripe_price_id: price?.id,
            stripe_product:
              typeof price?.product === "string" ? price.product : undefined,
            stripe_interval: price?.recurring?.interval ?? null,
            is_subscribed: !["canceled", "incomplete_expired"].includes(
              sub.status,
            ),
          },
          { onConflict: "uuid" },
        );
      }
    }

    return new Response(JSON.stringify({ received: true }), { status: 200 });
  } catch (e) {
    return new Response(`Webhook Error: ${e}`, { status: 400 });
  }
});
```

> Remember to set secrets for each function: `STRIPE_SECRET_KEY` everywhere, plus `STRIPE_WEBHOOK_SECRET` and `SUPABASE_SERVICE_ROLE_KEY` for `stripe-webhook`. Keep JWT verification disabled for the webhook function only.

