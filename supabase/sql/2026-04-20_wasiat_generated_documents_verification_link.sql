begin;

alter table public.wasiat_generated_documents
  add column if not exists verification_id bigint;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'wasiat_generated_documents_verification_id_fkey'
  ) then
    alter table public.wasiat_generated_documents
      add constraint wasiat_generated_documents_verification_id_fkey
      foreign key (verification_id) references public.verification(id) on delete set null;
  end if;
end
$$;

create unique index if not exists wasiat_generated_documents_verification_id_uidx
  on public.wasiat_generated_documents (verification_id)
  where verification_id is not null;

commit;
