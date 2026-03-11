-- Feedback table for in‑app bug reports & feature requests
-- Run this in your Supabase SQL editor (or add to your migrations)

create table if not exists public.feedback (
  id             bigserial primary key,
  uuid           uuid references auth.users (id) on delete set null,
  email          text,
  type           text not null check (type in ('bug', 'feature')),
  description    text not null,
  screenshot_url text,
  created_at     timestamptz not null default now()
);

-- Indexes
create index if not exists idx_feedback_uuid on public.feedback (uuid);
create index if not exists idx_feedback_created_at on public.feedback (created_at);

-- Enable Row Level Security
alter table public.feedback enable row level security;

-- Policies: authenticated users can insert and view their own feedback

drop policy if exists "Users can insert their own feedback" on public.feedback;
create policy "Users can insert their own feedback"
on public.feedback
for insert
to authenticated
with check (auth.uid() is not null);

drop policy if exists "Users can view their own feedback" on public.feedback;
create policy "Users can view their own feedback"
on public.feedback
for select
to authenticated
using (uuid = auth.uid());

-- Optional: if you have an is_admin() helper, you can allow admins to manage all feedback:
-- drop policy if exists "Admins can manage all feedback" on public.feedback;
-- create policy "Admins can manage all feedback"
-- on public.feedback
-- for all
-- to authenticated
-- using (is_admin());
-- with check (is_admin());

