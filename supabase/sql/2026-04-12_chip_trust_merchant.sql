-- Separate CHIP merchant for trust payments (Hibah/Wasiat keep chip_customer_id + main CHIP keys).

alter table public.accounts
  add column if not exists chip_trust_customer_id text;

create unique index if not exists accounts_chip_trust_customer_id_key
  on public.accounts (chip_trust_customer_id)
  where chip_trust_customer_id is not null;
