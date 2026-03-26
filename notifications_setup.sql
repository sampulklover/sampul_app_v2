-- Notifications table for in-app + push notifications

create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  title       text not null,
  body        text not null,
  type        text,                -- e.g. 'trust_update', 'reminder', etc.
  data        jsonb,               -- extra payload for deep links, etc.
  created_at  timestamptz not null default now(),
  read_at     timestamptz          -- null = unread
);

-- Indexes for common queries
create index if not exists notifications_user_id_created_at_idx
  on public.notifications (user_id, created_at desc);

create index if not exists notifications_user_id_unread_idx
  on public.notifications (user_id)
  where read_at is null;

-- Enable Row Level Security
alter table public.notifications enable row level security;

-- Policies: users can only see and update their own notifications

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
on public.notifications
for select
using (auth.uid() = user_id);

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
on public.notifications
for update
using (auth.uid() = user_id);

drop policy if exists "notifications_delete_own" on public.notifications;
create policy "notifications_delete_own"
on public.notifications
for delete
using (auth.uid() = user_id);

-- Allow inserts from:
-- - Supabase service role (edge functions, backend jobs)
-- - Authenticated user inserting a row for themselves
drop policy if exists "notifications_insert_service_only" on public.notifications;
create policy "notifications_insert_service_only"
on public.notifications
for insert
with check (
  auth.role() = 'service_role'
  or auth.uid() = user_id
);

