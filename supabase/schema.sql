-- Socks On Records: database schema, permissions and image storage.
-- Run this first in Supabase: SQL Editor > New query > paste > Run.
-- Safe to re-run: it uses "if not exists" / "or replace" / drop-then-create for policies.

-- ============ TABLES ============

create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text,
  display_name text,
  is_admin     boolean not null default false,
  created_at   timestamptz not null default now()
);

create table if not exists public.bands (
  id                 uuid primary key default gen_random_uuid(),
  slug               text not null unique,
  name               text not null,
  location           text,
  bio                text,
  image_url          text,            -- photo uploaded to the band-images bucket
  bandcamp_image_url text,            -- fallback pulled from Bandcamp
  bandcamp_url       text,
  instagram_url      text,
  facebook_url       text,
  spotify_url        text,
  youtube_url        text,
  website_url        text,
  published          boolean not null default true,
  sort_order         integer not null default 0,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

-- Which logged-in users can edit which band
create table if not exists public.band_members (
  band_id uuid not null references public.bands(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  primary key (band_id, user_id)
);

-- Private admin notes about a band (e.g. "needs a better photo")
create table if not exists public.band_notes (
  band_id uuid primary key references public.bands(id) on delete cascade,
  note    text not null
);

create table if not exists public.releases (
  id            uuid primary key default gen_random_uuid(),
  title         text not null,
  artist_text   text,
  type          text,
  released_text text,
  released_date date,
  bandcamp_url  text,
  cover_url     text,
  label         text,
  created_at    timestamptz not null default now()
);

create table if not exists public.release_bands (
  release_id uuid not null references public.releases(id) on delete cascade,
  band_id    uuid not null references public.bands(id) on delete cascade,
  primary key (release_id, band_id)
);

create table if not exists public.gigs (
  id            uuid primary key default gen_random_uuid(),
  title         text not null,
  series        text,                 -- e.g. 'East Angrier'
  event_date    date not null,
  time_text     text,                 -- free text, e.g. 'Doors 7pm'
  venue_name    text,
  venue_address text,
  price_text    text,
  ticket_url    text,
  status        text not null default 'on_sale'
                check (status in ('on_sale','sold_out','free','cancelled')),
  notes         text,
  created_by    uuid references auth.users(id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Line-up: either a roster band (band_id) or a guest act (act_name)
create table if not exists public.gig_acts (
  id        uuid primary key default gen_random_uuid(),
  gig_id    uuid not null references public.gigs(id) on delete cascade,
  band_id   uuid references public.bands(id) on delete set null,
  act_name  text,
  position  integer not null default 0,
  check (band_id is not null or act_name is not null)
);

-- News / updates. band_id null = label-wide news.
create table if not exists public.updates (
  id           uuid primary key default gen_random_uuid(),
  band_id      uuid references public.bands(id) on delete cascade,
  title        text not null,
  body         text,
  link_url     text,
  published_at timestamptz not null default now(),
  created_by   uuid references auth.users(id) on delete set null
);

create index if not exists gigs_event_date_idx on public.gigs (event_date);
create index if not exists gig_acts_gig_idx on public.gig_acts (gig_id);
create index if not exists gig_acts_band_idx on public.gig_acts (band_id);
create index if not exists updates_band_idx on public.updates (band_id);

-- ============ HELPERS ============

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false)
$$;

create or replace function public.is_band_member(b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.band_members where band_id = b and user_id = auth.uid())
$$;

create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists bands_touch on public.bands;
create trigger bands_touch before update on public.bands
  for each row execute function public.touch_updated_at();
drop trigger if exists gigs_touch on public.gigs;
create trigger gigs_touch before update on public.gigs
  for each row execute function public.touch_updated_at();

-- Every new login gets a profile row automatically
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email) on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============ ROW LEVEL SECURITY ============
-- Public can read the website content. Only admins and the right band members can change it.

alter table public.profiles      enable row level security;
alter table public.bands         enable row level security;
alter table public.band_members  enable row level security;
alter table public.band_notes    enable row level security;
alter table public.releases      enable row level security;
alter table public.release_bands enable row level security;
alter table public.gigs          enable row level security;
alter table public.gig_acts      enable row level security;
alter table public.updates       enable row level security;

-- profiles: you see yourself, admins see everyone; you can rename yourself but not make yourself admin
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select
  using (id = auth.uid() or public.is_admin());
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid() and is_admin = public.is_admin());
drop policy if exists profiles_admin_all on public.profiles;
create policy profiles_admin_all on public.profiles for all
  using (public.is_admin()) with check (public.is_admin());

-- bands: public read (published only), band members edit their own, admins do everything
drop policy if exists bands_select on public.bands;
create policy bands_select on public.bands for select
  using (published or public.is_admin() or public.is_band_member(id));
drop policy if exists bands_update on public.bands;
create policy bands_update on public.bands for update
  using (public.is_admin() or public.is_band_member(id))
  with check (public.is_admin() or public.is_band_member(id));
drop policy if exists bands_admin_insert on public.bands;
create policy bands_admin_insert on public.bands for insert with check (public.is_admin());
drop policy if exists bands_admin_delete on public.bands;
create policy bands_admin_delete on public.bands for delete using (public.is_admin());

-- band_members: you see your own links, admins manage them all
drop policy if exists band_members_select on public.band_members;
create policy band_members_select on public.band_members for select
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists band_members_admin on public.band_members;
create policy band_members_admin on public.band_members for all
  using (public.is_admin()) with check (public.is_admin());

-- band_notes: admins only
drop policy if exists band_notes_admin on public.band_notes;
create policy band_notes_admin on public.band_notes for all
  using (public.is_admin()) with check (public.is_admin());

-- releases and their band links: public read, admin write (bands can request changes for now)
drop policy if exists releases_select on public.releases;
create policy releases_select on public.releases for select using (true);
drop policy if exists releases_admin on public.releases;
create policy releases_admin on public.releases for all
  using (public.is_admin()) with check (public.is_admin());
drop policy if exists release_bands_select on public.release_bands;
create policy release_bands_select on public.release_bands for select using (true);
drop policy if exists release_bands_admin on public.release_bands;
create policy release_bands_admin on public.release_bands for all
  using (public.is_admin()) with check (public.is_admin());

-- gigs: public read; any band member can add a gig; the creator or an admin can edit it
drop policy if exists gigs_select on public.gigs;
create policy gigs_select on public.gigs for select using (true);
drop policy if exists gigs_insert on public.gigs;
create policy gigs_insert on public.gigs for insert
  with check (
    public.is_admin()
    or (created_by = auth.uid()
        and exists (select 1 from public.band_members m where m.user_id = auth.uid()))
  );
drop policy if exists gigs_update on public.gigs;
create policy gigs_update on public.gigs for update
  using (public.is_admin() or created_by = auth.uid())
  with check (public.is_admin() or created_by = auth.uid());
drop policy if exists gigs_delete on public.gigs;
create policy gigs_delete on public.gigs for delete
  using (public.is_admin() or created_by = auth.uid());

-- gig_acts: public read; whoever can edit the gig can edit its line-up
drop policy if exists gig_acts_select on public.gig_acts;
create policy gig_acts_select on public.gig_acts for select using (true);
drop policy if exists gig_acts_write on public.gig_acts;
create policy gig_acts_write on public.gig_acts for all
  using (public.is_admin()
         or exists (select 1 from public.gigs g where g.id = gig_id and g.created_by = auth.uid()))
  with check (public.is_admin()
         or exists (select 1 from public.gigs g where g.id = gig_id and g.created_by = auth.uid()));

-- updates: public read; band members post for their own band; admins post anywhere (incl. label-wide)
drop policy if exists updates_select on public.updates;
create policy updates_select on public.updates for select using (true);
drop policy if exists updates_insert on public.updates;
create policy updates_insert on public.updates for insert
  with check (
    public.is_admin()
    or (band_id is not null and public.is_band_member(band_id) and created_by = auth.uid())
  );
drop policy if exists updates_update on public.updates;
create policy updates_update on public.updates for update
  using (public.is_admin() or created_by = auth.uid())
  with check (public.is_admin() or created_by = auth.uid());
drop policy if exists updates_delete on public.updates;
create policy updates_delete on public.updates for delete
  using (public.is_admin() or created_by = auth.uid());

-- ============ API ACCESS ============
-- Row level security above is the real gatekeeper; these grants just let the API see the tables.
grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to anon, authenticated;
grant insert, update, delete on all tables in schema public to authenticated;
revoke select on public.profiles, public.band_members, public.band_notes from anon;
grant execute on function public.is_admin() to anon, authenticated;
grant execute on function public.is_band_member(uuid) to anon, authenticated;

-- ============ IMAGE STORAGE ============
-- Public bucket for band photos. Upload to <band id>/<filename>.
insert into storage.buckets (id, name, public)
values ('band-images', 'band-images', true)
on conflict (id) do nothing;

drop policy if exists band_images_read on storage.objects;
create policy band_images_read on storage.objects for select
  using (bucket_id = 'band-images');
drop policy if exists band_images_write on storage.objects;
create policy band_images_write on storage.objects for insert to authenticated
  with check (bucket_id = 'band-images'
    and (public.is_admin() or public.is_band_member(((storage.foldername(name))[1])::uuid)));
drop policy if exists band_images_update on storage.objects;
create policy band_images_update on storage.objects for update to authenticated
  using (bucket_id = 'band-images'
    and (public.is_admin() or public.is_band_member(((storage.foldername(name))[1])::uuid)));
drop policy if exists band_images_delete on storage.objects;
create policy band_images_delete on storage.objects for delete to authenticated
  using (bucket_id = 'band-images'
    and (public.is_admin() or public.is_band_member(((storage.foldername(name))[1])::uuid)));
