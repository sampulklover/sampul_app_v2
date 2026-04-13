-- Allow staff (admin/marketing) to manage AI KB content
-- Run in Supabase SQL Editor. Safe to re-run.

begin;

-- Helper: staff check based on public.roles (uuid = auth.uid())
create or replace function public.is_staff_for_ai_content()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.roles r
    where r.uuid = auth.uid()
      and lower(r.role::text) in ('admin', 'marketing')
  );
$$;

-- Sources: staff can read all, update, insert, delete
drop policy if exists ai_kb_sources_select_staff on public.ai_kb_sources;
create policy ai_kb_sources_select_staff
on public.ai_kb_sources
for select
to authenticated
using (public.is_staff_for_ai_content());

drop policy if exists ai_kb_sources_update_staff on public.ai_kb_sources;
create policy ai_kb_sources_update_staff
on public.ai_kb_sources
for update
to authenticated
using (public.is_staff_for_ai_content())
with check (public.is_staff_for_ai_content());

drop policy if exists ai_kb_sources_insert_staff on public.ai_kb_sources;
create policy ai_kb_sources_insert_staff
on public.ai_kb_sources
for insert
to authenticated
with check (public.is_staff_for_ai_content());

drop policy if exists ai_kb_sources_delete_staff on public.ai_kb_sources;
create policy ai_kb_sources_delete_staff
on public.ai_kb_sources
for delete
to authenticated
using (public.is_staff_for_ai_content());

-- Entries: staff can read all (useful for debugging imports)
drop policy if exists ai_kb_entries_select_staff on public.ai_kb_entries;
create policy ai_kb_entries_select_staff
on public.ai_kb_entries
for select
to authenticated
using (public.is_staff_for_ai_content());

-- Entries: staff can insert/update/delete (for manual corrections)
drop policy if exists ai_kb_entries_insert_staff on public.ai_kb_entries;
create policy ai_kb_entries_insert_staff
on public.ai_kb_entries
for insert
to authenticated
with check (public.is_staff_for_ai_content());

drop policy if exists ai_kb_entries_update_staff on public.ai_kb_entries;
create policy ai_kb_entries_update_staff
on public.ai_kb_entries
for update
to authenticated
using (public.is_staff_for_ai_content())
with check (public.is_staff_for_ai_content());

drop policy if exists ai_kb_entries_delete_staff on public.ai_kb_entries;
create policy ai_kb_entries_delete_staff
on public.ai_kb_entries
for delete
to authenticated
using (public.is_staff_for_ai_content());

-- Chunks: staff can read all
drop policy if exists ai_kb_chunks_select_staff on public.ai_kb_chunks;
create policy ai_kb_chunks_select_staff
on public.ai_kb_chunks
for select
to authenticated
using (public.is_staff_for_ai_content());

-- Chunks: staff can update/delete (rare; but useful when adjusting chunk text)
drop policy if exists ai_kb_chunks_update_staff on public.ai_kb_chunks;
create policy ai_kb_chunks_update_staff
on public.ai_kb_chunks
for update
to authenticated
using (public.is_staff_for_ai_content())
with check (public.is_staff_for_ai_content());

drop policy if exists ai_kb_chunks_delete_staff on public.ai_kb_chunks;
create policy ai_kb_chunks_delete_staff
on public.ai_kb_chunks
for delete
to authenticated
using (public.is_staff_for_ai_content());

commit;

