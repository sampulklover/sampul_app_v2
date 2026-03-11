-- Learning resources (podcasts, guides) for Resources & Insights screen
-- Run this in your Supabase SQL editor or migrations.

create table if not exists public.learning_resources (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),

  -- 'podcast' or 'guide'
  resource_type text not null check (resource_type in ('podcast', 'guide')),

  -- High-level grouping e.g. 'trusts_wills', 'estate_planning'
  category text not null,

  title text not null,

  -- For podcasts this is the listen duration label (e.g. "12 min listen")
  -- For guides this can be a read-time label (e.g. "7 min read")
  duration_label text,

  author_name text,

  published_at date default current_date,

  -- Long-form body/description for detail page
  body text,

  -- Video URL for podcasts (YouTube, Vimeo, or direct video URL)
  video_url text,

  -- Image URL for guides (thumbnail/cover image)
  image_url text,

  -- Whether this resource is visible to end-users
  is_published boolean not null default true,

  -- Optional ordering within type/category
  sort_index int
);

-- Keep updated_at in sync
create or replace function public.set_learning_resources_updated_at()
returns trigger as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_learning_resources_updated_at on public.learning_resources;
create trigger trg_learning_resources_updated_at
before update on public.learning_resources
for each row
execute procedure public.set_learning_resources_updated_at();

alter table public.learning_resources enable row level security;

-- Allow anyone to read published resources
drop policy if exists "Public read published learning resources" on public.learning_resources;
create policy "Public read published learning resources"
on public.learning_resources
for select
using (is_published = true);

-- Only admins (based on roles table) can insert/update/delete
drop policy if exists "Admins manage learning resources" on public.learning_resources;
create policy "Admins manage learning resources"
on public.learning_resources
for all
using (
  exists (
    select 1
    from public.roles r
    where r.uuid = auth.uid()
      and r.role = 'admin'::user_roles
  )
)
with check (
  exists (
    select 1
    from public.roles r
    where r.uuid = auth.uid()
      and r.role = 'admin'::user_roles
  )
);

