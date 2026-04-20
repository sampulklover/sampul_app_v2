begin;

-- Snapshot-based generated Wasiat documents.
-- Purpose: freeze a "generated" version so it doesn't auto-change when the user edits assets/profile later.

create table if not exists public.wasiat_generated_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  will_id bigint,
  will_code text,
  created_at timestamptz not null default now(),
  snapshot jsonb not null
);

create index if not exists wasiat_generated_documents_user_id_idx
  on public.wasiat_generated_documents (user_id, created_at desc);

alter table public.wasiat_generated_documents enable row level security;

drop policy if exists wasiat_generated_documents_select_own on public.wasiat_generated_documents;
create policy wasiat_generated_documents_select_own
on public.wasiat_generated_documents
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists wasiat_generated_documents_insert_own on public.wasiat_generated_documents;
create policy wasiat_generated_documents_insert_own
on public.wasiat_generated_documents
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists wasiat_generated_documents_delete_own on public.wasiat_generated_documents;
create policy wasiat_generated_documents_delete_own
on public.wasiat_generated_documents
for delete
to authenticated
using (auth.uid() = user_id);

commit;

