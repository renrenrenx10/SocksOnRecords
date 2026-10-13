-- Socks On Records: the "Wanna play a show" and "Book a band" forms.
-- Run once in the Supabase SQL Editor (safe to run again).
-- Anyone can send one in; only admins can read, mark or delete them (Admin > Enquiries).

create table if not exists public.play_requests (
  id              uuid primary key default gen_random_uuid(),
  created_at      timestamptz not null default now(),
  status          text not null default 'new' check (status in ('new', 'replied', 'archived')),
  band_name       text not null check (char_length(band_name) between 1 and 150),
  contact_name    text not null check (char_length(contact_name) between 1 and 150),
  email           text not null check (char_length(email) between 5 and 200),
  music_link      text not null check (char_length(music_link) between 1 and 500),
  city            text not null check (char_length(city) between 1 and 150),
  socials         text check (socials is null or char_length(socials) <= 1000),
  message         text check (message is null or char_length(message) <= 4000),
  recommendations text check (recommendations is null or char_length(recommendations) <= 2000)
);

create table if not exists public.booking_requests (
  id           uuid primary key default gen_random_uuid(),
  created_at   timestamptz not null default now(),
  status       text not null default 'new' check (status in ('new', 'replied', 'archived')),
  who          text not null check (char_length(who) between 1 and 300),
  contact      text not null check (char_length(contact) between 3 and 300),
  bands        text[] not null check (cardinality(bands) between 1 and 20),
  event_date   date,
  venue        text not null check (char_length(venue) between 1 and 300),
  details      text check (details is null or char_length(details) <= 4000),
  socials      text check (socials is null or char_length(socials) <= 1000),
  other_bands  text check (other_bands is null or char_length(other_bands) <= 2000)
);

create index if not exists play_requests_created_idx on public.play_requests (created_at desc);
create index if not exists booking_requests_created_idx on public.booking_requests (created_at desc);

alter table public.play_requests enable row level security;
alter table public.booking_requests enable row level security;

drop policy if exists play_insert on public.play_requests;
create policy play_insert on public.play_requests for insert to anon, authenticated with check (status = 'new');
drop policy if exists play_admin_select on public.play_requests;
create policy play_admin_select on public.play_requests for select to authenticated using (public.is_admin());
drop policy if exists play_admin_update on public.play_requests;
create policy play_admin_update on public.play_requests for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists play_admin_delete on public.play_requests;
create policy play_admin_delete on public.play_requests for delete to authenticated using (public.is_admin());

drop policy if exists booking_insert on public.booking_requests;
create policy booking_insert on public.booking_requests for insert to anon, authenticated with check (status = 'new');
drop policy if exists booking_admin_select on public.booking_requests;
create policy booking_admin_select on public.booking_requests for select to authenticated using (public.is_admin());
drop policy if exists booking_admin_update on public.booking_requests;
create policy booking_admin_update on public.booking_requests for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists booking_admin_delete on public.booking_requests;
create policy booking_admin_delete on public.booking_requests for delete to authenticated using (public.is_admin());

revoke all on public.play_requests, public.booking_requests from anon, authenticated;
grant insert on public.play_requests, public.booking_requests to anon, authenticated;
grant select, update, delete on public.play_requests, public.booking_requests to authenticated;
