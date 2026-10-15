-- Socks On Records: the "Friends of ours" page (labels, promoters and mates doing their own thing).
-- Run once in the Supabase SQL Editor (safe to run again). Edit the list in Admin > Friends.

create table if not exists public.friends (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  name        text not null check (char_length(name) between 1 and 150),   -- who
  what        text check (what is null or char_length(what) <= 300),       -- what they do
  place       text check (place is null or char_length(place) <= 150),     -- where
  contact     text check (contact is null or char_length(contact) <= 300), -- how: a website, an email or a handle
  sort_order  integer not null default 0,
  published   boolean not null default true
);

alter table public.friends enable row level security;
drop policy if exists friends_select on public.friends;
create policy friends_select on public.friends for select using (published or public.is_admin());
drop policy if exists friends_admin on public.friends;
create policy friends_admin on public.friends for all using (public.is_admin()) with check (public.is_admin());

grant select on public.friends to anon, authenticated;
grant insert, update, delete on public.friends to authenticated;

-- The first two, only added if the list is empty. Change or delete them in admin.
insert into public.friends (name, what, place, contact, sort_order)
select * from (values
  ('Horn and Hoof Records', 'Label and gig promoter', 'Manchester / Stockport', 'https://www.hornandhoof.co.uk/', 1),
  ('Evil Music Live', 'Gig promoter and hella fun', 'Oldham', 'thecrashmats@gmail.com', 2)
) as v(name, what, place, contact, sort_order)
where not exists (select 1 from public.friends);
