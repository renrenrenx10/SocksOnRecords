-- Socks On Records: band video links, a Videos page, Socks On Sessions, and the newsletter list.
-- Run once in the Supabase SQL Editor (safe to run again).

-- One YouTube link per band (bands and admins edit this on the band form)
alter table public.bands add column if not exists video_url text;

-- ============ VIDEOS: extra videos that admins add ============
create table if not exists public.videos (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  youtube_url text not null,
  band_id     uuid references public.bands(id) on delete set null,   -- optional: shows on that band's page too
  published   boolean not null default true,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now()
);

-- ============ SOCKS ON SESSIONS ============
create table if not exists public.sessions (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  session_date date,
  band_id      uuid references public.bands(id) on delete set null,  -- optional roster band
  band_text    text,                                                  -- or a guest act's name
  summary      text,
  video_url    text,                                                  -- YouTube link
  audio_url    text,                                                  -- Spotify / Apple Podcasts / SoundCloud / any link
  published    boolean not null default true,
  created_at   timestamptz not null default now()
);

-- ============ NEWSLETTER ============
create table if not exists public.subscribers (
  id         uuid primary key default gen_random_uuid(),
  email      text not null check (length(email) <= 254 and email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  name       text check (name is null or length(name) <= 120),
  source     text,
  created_at timestamptz not null default now()
);
create unique index if not exists subscribers_email_uniq on public.subscribers (lower(email));

-- ============ PERMISSIONS ============
alter table public.videos      enable row level security;
alter table public.sessions    enable row level security;
alter table public.subscribers enable row level security;

drop policy if exists videos_select on public.videos;
create policy videos_select on public.videos for select using (published or public.is_admin());
drop policy if exists videos_admin on public.videos;
create policy videos_admin on public.videos for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists sessions_select on public.sessions;
create policy sessions_select on public.sessions for select using (published or public.is_admin());
drop policy if exists sessions_admin on public.sessions;
create policy sessions_admin on public.sessions for all using (public.is_admin()) with check (public.is_admin());

-- anyone can sign up; only admins can see or remove the list
drop policy if exists subscribers_insert on public.subscribers;
create policy subscribers_insert on public.subscribers for insert to anon, authenticated with check (true);
drop policy if exists subscribers_admin_select on public.subscribers;
create policy subscribers_admin_select on public.subscribers for select using (public.is_admin());
drop policy if exists subscribers_admin_delete on public.subscribers;
create policy subscribers_admin_delete on public.subscribers for delete using (public.is_admin());

grant select on public.videos, public.sessions to anon, authenticated;
grant insert, update, delete on public.videos, public.sessions to authenticated;
revoke all on public.subscribers from anon;
grant insert on public.subscribers to anon;
grant select, insert, delete on public.subscribers to authenticated;
