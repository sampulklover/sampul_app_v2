-- Wasiat annual access via CHIP (one-time yearly payment; subscription window on accounts)
-- Run in Supabase SQL Editor. Safe to re-run.

begin;

create table if not exists public.wasiat_subscription_payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  status text,
  amount bigint not null check (amount > 0),
  chip_client_id text,
  chip_payment_id text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz default now()
);

create index if not exists wasiat_subscription_payments_user_id_idx
  on public.wasiat_subscription_payments (user_id);

alter table public.accounts
  add column if not exists wasiat_subscription_period_start timestamptz;

alter table public.accounts
  add column if not exists wasiat_subscription_period_end timestamptz;

alter table public.wasiat_subscription_payments enable row level security;

drop policy if exists wasiat_subscription_payments_select_own on public.wasiat_subscription_payments;
create policy wasiat_subscription_payments_select_own
on public.wasiat_subscription_payments
for select
using (user_id = auth.uid());

commit;
