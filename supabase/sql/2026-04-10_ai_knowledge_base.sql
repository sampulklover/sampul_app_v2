-- Sampul AI Knowledge Base (keyword + vector + hybrid)
-- Run this in Supabase SQL Editor. Safe to re-run.
--
-- References:
-- - Supabase AI & Vectors guide: https://supabase.com/docs/guides/ai

begin;

-- 0) Extensions
create extension if not exists vector;
create extension if not exists pg_trgm;

-- 1) KB sources (e.g., an XLSX import "Sampul_Hibah_Knowledge_Base_v1.xlsx")
create table if not exists public.ai_kb_sources (
  id uuid primary key default gen_random_uuid(),
  name text not null,                -- display name
  source_type text not null default 'file', -- file | manual | url
  source_uri text,                   -- storage path or URL
  product text,                      -- hibah | wasiat | trust | executor | general
  language text,                     -- en | bm
  version text,                      -- v1, v2, etc
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id)
);

create index if not exists ai_kb_sources_active_idx
  on public.ai_kb_sources (is_active, product, language);

-- 2) KB entries (one row per Q/A pair or instruction row)
create table if not exists public.ai_kb_entries (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references public.ai_kb_sources(id) on delete cascade,

  -- from your sheets: content + category + product + language
  category text,                     -- faq | process | fees | eligibility | objection | education
  product text,                      -- hibah | wasiat | trust | executor | general
  language text,                     -- en | bm

  -- structured content (recommended)
  question text,                     -- optional (some rows may be pure guidance)
  answer text not null,              -- the "A:" content (plain language)
  tags text[] not null default '{}',

  -- lifecycle
  is_active boolean not null default true,
  priority integer not null default 0, -- use for ⭐ PRIORITY sheets / manual boosting
  canonical_key text,                -- optional stable key e.g. "hibah.what_is_hibah_hartanah"

  -- raw/original for audit/debug
  raw_content text,                  -- original cell text if you imported combined Q/A
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id)
);

create index if not exists ai_kb_entries_source_idx
  on public.ai_kb_entries (source_id);

create index if not exists ai_kb_entries_active_idx
  on public.ai_kb_entries (is_active, product, language, category);

create index if not exists ai_kb_entries_priority_idx
  on public.ai_kb_entries (priority desc, updated_at desc);

-- 3) Search helpers (keyword)
alter table public.ai_kb_entries
  add column if not exists search_text text;

update public.ai_kb_entries
  set search_text = coalesce(question,'') || E'\n' || coalesce(answer,'')
  where search_text is null;

-- Generated column for full-text search (English config by default; adjust later if needed)
alter table public.ai_kb_entries
  add column if not exists search_tsv tsvector
  generated always as (to_tsvector('english', coalesce(search_text,''))) stored;

create index if not exists ai_kb_entries_search_tsv_idx
  on public.ai_kb_entries using gin (search_tsv);

-- Trigram index for partial matching / typos
create index if not exists ai_kb_entries_search_text_trgm_idx
  on public.ai_kb_entries using gin (search_text gin_trgm_ops);

-- 4) Chunk table (optional but recommended for long answers + better retrieval)
create table if not exists public.ai_kb_chunks (
  id uuid primary key default gen_random_uuid(),
  entry_id uuid not null references public.ai_kb_entries(id) on delete cascade,
  chunk_index integer not null default 0,
  content text not null,             -- chunk text used for retrieval
  token_estimate integer,            -- optional
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (entry_id, chunk_index)
);

create index if not exists ai_kb_chunks_entry_idx
  on public.ai_kb_chunks (entry_id, chunk_index);

create index if not exists ai_kb_chunks_active_idx
  on public.ai_kb_chunks (is_active);

-- 5) Vector embeddings per chunk (store embeddings here; keep table skinny)
-- Note: vector dimension depends on embedding model. 1536 is common (OpenAI text-embedding-3-small).
-- If you use another model later, you can create a new column or a new table versioned by model.
alter table public.ai_kb_chunks
  add column if not exists embedding vector(1536);

create index if not exists ai_kb_chunks_embedding_idx
  on public.ai_kb_chunks using ivfflat (embedding vector_cosine_ops)
  with (lists = 100);

-- 6) Retrieval functions

-- 6a) Keyword search (FTS + trigram fallback)
create or replace function public.ai_kb_search_keyword(
  query_text text,
  query_product text default null,
  query_language text default null,
  match_count int default 5
)
returns table (
  entry_id uuid,
  source_id uuid,
  product text,
  language text,
  category text,
  question text,
  answer text,
  tags text[],
  score double precision
)
language sql
stable
as $$
  with candidates as (
    select
      e.*,
      ts_rank_cd(e.search_tsv, plainto_tsquery('english', query_text)) as fts_score,
      similarity(e.search_text, query_text) as trigram_score
    from public.ai_kb_entries e
    where e.is_active = true
      and (query_product is null or e.product = query_product)
      and (query_language is null or e.language = query_language)
      and (
        e.search_tsv @@ plainto_tsquery('english', query_text)
        or e.search_text % query_text
      )
  )
  select
    c.id as entry_id,
    c.source_id,
    c.product,
    c.language,
    c.category,
    c.question,
    c.answer,
    c.tags,
    (coalesce(c.fts_score, 0) * 0.75 + coalesce(c.trigram_score, 0) * 0.25) as score
  from candidates c
  order by c.priority desc, score desc, c.updated_at desc
  limit match_count;
$$;

-- 6b) Semantic search (vector) over chunks, returning their parent entries
create or replace function public.ai_kb_search_semantic(
  query_embedding vector(1536),
  query_product text default null,
  query_language text default null,
  match_count int default 5
)
returns table (
  chunk_id uuid,
  entry_id uuid,
  source_id uuid,
  product text,
  language text,
  category text,
  question text,
  answer text,
  chunk_content text,
  distance double precision
)
language sql
stable
as $$
  select
    c.id as chunk_id,
    e.id as entry_id,
    e.source_id,
    e.product,
    e.language,
    e.category,
    e.question,
    e.answer,
    c.content as chunk_content,
    (c.embedding <=> query_embedding) as distance
  from public.ai_kb_chunks c
  join public.ai_kb_entries e on e.id = c.entry_id
  where c.is_active = true
    and e.is_active = true
    and c.embedding is not null
    and (query_product is null or e.product = query_product)
    and (query_language is null or e.language = query_language)
  order by e.priority desc, distance asc
  limit match_count;
$$;

-- 7) RLS (safe defaults)
alter table public.ai_kb_sources enable row level security;
alter table public.ai_kb_entries enable row level security;
alter table public.ai_kb_chunks enable row level security;

-- Read access: allow authenticated users to read active KB (AI can also use service role)
drop policy if exists ai_kb_sources_select_active on public.ai_kb_sources;
create policy ai_kb_sources_select_active
on public.ai_kb_sources
for select
to authenticated
using (is_active = true);

drop policy if exists ai_kb_entries_select_active on public.ai_kb_entries;
create policy ai_kb_entries_select_active
on public.ai_kb_entries
for select
to authenticated
using (is_active = true);

drop policy if exists ai_kb_chunks_select_active on public.ai_kb_chunks;
create policy ai_kb_chunks_select_active
on public.ai_kb_chunks
for select
to authenticated
using (is_active = true);

-- Write access: keep locked down (no authenticated write policies by default).
-- Use service role (Edge Functions) or add admin policies later once your admin roles are confirmed.

commit;

