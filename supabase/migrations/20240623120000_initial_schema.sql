-- Adventure v1 schema: trips, checklist, journal entries + RLS

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.trips (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  location text,
  start_date date,
  end_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trips_dates_check check (
    start_date is null
    or end_date is null
    or end_date >= start_date
  )
);

create table if not exists public.trip_checklist_items (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id) on delete cascade,
  label text not null,
  completed boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  body text not null default '',
  location text,
  photo_urls text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

create index if not exists trips_user_id_idx on public.trips (user_id);
create index if not exists trips_start_date_idx on public.trips (start_date desc);
create index if not exists trip_checklist_items_trip_id_idx on public.trip_checklist_items (trip_id);
create index if not exists journal_entries_trip_id_idx on public.journal_entries (trip_id);
create index if not exists journal_entries_user_id_idx on public.journal_entries (user_id);
create index if not exists journal_entries_created_at_idx on public.journal_entries (created_at desc);

-- ---------------------------------------------------------------------------
-- updated_at trigger
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trips_set_updated_at on public.trips;
create trigger trips_set_updated_at
  before update on public.trips
  for each row execute function public.set_updated_at();

drop trigger if exists journal_entries_set_updated_at on public.journal_entries;
create trigger journal_entries_set_updated_at
  before update on public.journal_entries
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.trips enable row level security;
alter table public.trip_checklist_items enable row level security;
alter table public.journal_entries enable row level security;

-- trips: owner only
drop policy if exists trips_select_own on public.trips;
create policy trips_select_own on public.trips
  for select using (auth.uid() = user_id);

drop policy if exists trips_insert_own on public.trips;
create policy trips_insert_own on public.trips
  for insert with check (auth.uid() = user_id);

drop policy if exists trips_update_own on public.trips;
create policy trips_update_own on public.trips
  for update using (auth.uid() = user_id);

drop policy if exists trips_delete_own on public.trips;
create policy trips_delete_own on public.trips
  for delete using (auth.uid() = user_id);

-- checklist: via trip ownership
drop policy if exists checklist_select_own on public.trip_checklist_items;
create policy checklist_select_own on public.trip_checklist_items
  for select using (
    exists (
      select 1 from public.trips t
      where t.id = trip_id and t.user_id = auth.uid()
    )
  );

drop policy if exists checklist_insert_own on public.trip_checklist_items;
create policy checklist_insert_own on public.trip_checklist_items
  for insert with check (
    exists (
      select 1 from public.trips t
      where t.id = trip_id and t.user_id = auth.uid()
    )
  );

drop policy if exists checklist_update_own on public.trip_checklist_items;
create policy checklist_update_own on public.trip_checklist_items
  for update using (
    exists (
      select 1 from public.trips t
      where t.id = trip_id and t.user_id = auth.uid()
    )
  );

drop policy if exists checklist_delete_own on public.trip_checklist_items;
create policy checklist_delete_own on public.trip_checklist_items
  for delete using (
    exists (
      select 1 from public.trips t
      where t.id = trip_id and t.user_id = auth.uid()
    )
  );

-- journal entries: owner only
drop policy if exists journal_select_own on public.journal_entries;
create policy journal_select_own on public.journal_entries
  for select using (auth.uid() = user_id);

drop policy if exists journal_insert_own on public.journal_entries;
create policy journal_insert_own on public.journal_entries
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.trips t
      where t.id = trip_id and t.user_id = auth.uid()
    )
  );

drop policy if exists journal_update_own on public.journal_entries;
create policy journal_update_own on public.journal_entries
  for update using (auth.uid() = user_id);

drop policy if exists journal_delete_own on public.journal_entries;
create policy journal_delete_own on public.journal_entries
  for delete using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Storage: journal photos (private per-user paths)
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('journal-photos', 'journal-photos', false)
on conflict (id) do nothing;

drop policy if exists journal_photos_select_own on storage.objects;
create policy journal_photos_select_own on storage.objects
  for select using (
    bucket_id = 'journal-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists journal_photos_insert_own on storage.objects;
create policy journal_photos_insert_own on storage.objects
  for insert with check (
    bucket_id = 'journal-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists journal_photos_update_own on storage.objects;
create policy journal_photos_update_own on storage.objects
  for update using (
    bucket_id = 'journal-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists journal_photos_delete_own on storage.objects;
create policy journal_photos_delete_own on storage.objects
  for delete using (
    bucket_id = 'journal-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
