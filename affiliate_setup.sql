-- Affiliate / referral setup (run in Supabase SQL editor)
--
-- Minimal model:
-- - Users can share a code they own (in `affiliate_codes`)
-- - New users can "claim" a code once (recorded in `affiliate_referrals`)
--
-- This script creates:
-- - tables
-- - indexes/constraints
-- - (no SQL functions required; Edge Functions handle code creation/claiming)

create extension if not exists pgcrypto;

create table if not exists public.affiliate_codes (
  code text primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create unique index if not exists affiliate_codes_owner_id_unique
  on public.affiliate_codes(owner_id);

create table if not exists public.affiliate_referrals (
  id bigserial primary key,
  code text not null references public.affiliate_codes(code) on delete restrict,
  referrer_id uuid not null references auth.users(id) on delete cascade,
  referred_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint affiliate_referrals_one_per_referred unique (referred_id)
);

create index if not exists affiliate_referrals_referrer_id_idx
  on public.affiliate_referrals(referrer_id);

create index if not exists affiliate_referrals_code_idx
  on public.affiliate_referrals(code);

alter table public.affiliate_codes enable row level security;
alter table public.affiliate_referrals enable row level security;

-- Policies (tight by default)
-- Owners can read their own code row.
drop policy if exists "affiliate_codes_select_own" on public.affiliate_codes;
create policy "affiliate_codes_select_own"
on public.affiliate_codes
for select
to authenticated
using (owner_id = auth.uid());

-- Users can read referrals where they are the referrer or the referred.
drop policy if exists "affiliate_referrals_select_involved" on public.affiliate_referrals;
create policy "affiliate_referrals_select_involved"
on public.affiliate_referrals
for select
to authenticated
using (referrer_id = auth.uid() or referred_id = auth.uid());

-- Inserts into affiliate_referrals are performed by an Edge Function (service role),
-- so we do not expose an RPC for claiming.

-- Cleanup: remove previously-created helper function (if you ran an older version).
drop function if exists public.get_or_create_my_affiliate_code();

