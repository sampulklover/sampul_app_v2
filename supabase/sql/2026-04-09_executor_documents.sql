-- Executor supporting documents (Hibah-style)
-- Run this in Supabase SQL Editor.
-- Safe to re-run: uses IF NOT EXISTS where possible.

begin;

-- 1) Table
create table if not exists public.executor_documents (
  id uuid primary key default gen_random_uuid(),
  executor_id integer not null references public.executor(id) on delete cascade,
  title text,
  file_name text not null,
  file_path text not null,
  file_size bigint not null,
  file_type text not null,
  document_type text not null default 'supporting',
  uploaded_at timestamptz not null default now(),
  uuid uuid not null references public.profiles(uuid)
);

-- If table already existed before adding title:
alter table public.executor_documents
  add column if not exists title text;

-- 2) Helpful indexes
create index if not exists executor_documents_executor_id_idx
  on public.executor_documents (executor_id);

create index if not exists executor_documents_uuid_idx
  on public.executor_documents (uuid);

-- 3) Row Level Security (recommended)
alter table public.executor_documents enable row level security;

-- Read own rows
drop policy if exists executor_documents_select_own on public.executor_documents;
create policy executor_documents_select_own
on public.executor_documents
for select
using (uuid = auth.uid());

-- Insert own rows
drop policy if exists executor_documents_insert_own on public.executor_documents;
create policy executor_documents_insert_own
on public.executor_documents
for insert
with check (uuid = auth.uid());

-- Update own rows (optional but safe)
drop policy if exists executor_documents_update_own on public.executor_documents;
create policy executor_documents_update_own
on public.executor_documents
for update
using (uuid = auth.uid())
with check (uuid = auth.uid());

-- Delete own rows
drop policy if exists executor_documents_delete_own on public.executor_documents;
create policy executor_documents_delete_own
on public.executor_documents
for delete
using (uuid = auth.uid());

commit;

