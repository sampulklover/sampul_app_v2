-- Referral rewards: per-user coupons (5% Hibah / 5% Wasiat) with apply-at-checkout.
-- Run in Supabase SQL Editor. Safe to re-run (uses IF NOT EXISTS).

begin;

create table if not exists public.user_coupons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  applies_to text not null check (applies_to in ('hibah', 'wasiat')),
  discount_percent int not null default 5
    check (discount_percent > 0 and discount_percent <= 100),
  status text not null default 'active'
    check (status in ('active', 'used', 'expired')),
  source text not null,
  expires_at timestamptz not null,
  used_at timestamptz,
  used_payment_kind text check (used_payment_kind is null or used_payment_kind in ('hibah', 'wasiat')),
  used_payment_id uuid,
  referral_id bigint references public.affiliate_referrals (id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists user_coupons_user_id_idx on public.user_coupons (user_id);
create index if not exists user_coupons_user_status_idx on public.user_coupons (user_id, status);

-- At most one referrer reward coupon per referral row per product (idempotency).
create unique index if not exists user_coupons_referrer_hibah_once
  on public.user_coupons (referral_id)
  where source = 'referrer_reward_hibah' and referral_id is not null;

create unique index if not exists user_coupons_referrer_wasiat_once
  on public.user_coupons (referral_id)
  where source = 'referrer_reward_wasiat' and referral_id is not null;

alter table public.user_coupons enable row level security;

drop policy if exists user_coupons_select_own on public.user_coupons;
create policy user_coupons_select_own
on public.user_coupons
for select
to authenticated
using (user_id = auth.uid());

-- Payments: link optional applied coupon (validated in chip-create-payment).
alter table public.hibah_payments
  add column if not exists user_coupon_id uuid references public.user_coupons (id) on delete set null;

alter table public.wasiat_subscription_payments
  add column if not exists user_coupon_id uuid references public.user_coupons (id) on delete set null;

alter table public.wasiat_subscription_payments
  add column if not exists original_amount_cents bigint;

comment on table public.user_coupons is 'Discount coupons; referee welcome grants on claim-referral; referrer rewards on successful referee CHIP payment.';

commit;
