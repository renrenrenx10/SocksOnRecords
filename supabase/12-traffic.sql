-- Socks On Records: simple, private traffic counting, viewable in Admin > Traffic.
-- Run once in the Supabase SQL Editor (safe to run again).
--
-- What is stored per page view: the page path, the site the visitor came from (just the site name,
-- like google.com), a random per-visit code (so visits can be counted, it is not linked to a person and
-- is forgotten when the tab closes), and mobile/tablet/desktop. No IP address, no cookies, no names.

create table if not exists public.page_views (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  path       text not null check (char_length(path) between 1 and 120),
  ref        text check (ref is null or char_length(ref) <= 80),
  session_id text check (session_id is null or char_length(session_id) <= 40),
  device     text check (device is null or device in ('mobile', 'tablet', 'desktop'))
);
create index if not exists page_views_created_idx on public.page_views (created_at desc);

alter table public.page_views enable row level security;
drop policy if exists page_views_insert on public.page_views;
create policy page_views_insert on public.page_views for insert to anon, authenticated with check (true);
drop policy if exists page_views_admin_select on public.page_views;
create policy page_views_admin_select on public.page_views for select to authenticated using (public.is_admin());
drop policy if exists page_views_admin_delete on public.page_views;
create policy page_views_admin_delete on public.page_views for delete to authenticated using (public.is_admin());

revoke all on public.page_views from anon, authenticated;
grant insert on public.page_views to anon, authenticated;
grant select, delete on public.page_views to authenticated;

-- One call returns everything the Traffic screen shows (days are UK days). Admins only.
create or replace function public.admin_traffic(p_days int default 30)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  n int := least(greatest(coalesce(p_days, 30), 1), 365);
  today date := (now() at time zone 'Europe/London')::date;
  d0 date := today - (n - 1);
  p0 date := today - (2 * n - 1);
  res jsonb;
begin
  if not public.is_admin() then raise exception 'Only admins can see traffic'; end if;
  with v as (
    select (created_at at time zone 'Europe/London')::date as d, path, ref, device,
           coalesce(session_id, 'x' || id::text) as sid
    from public.page_views
    where created_at >= (p0::timestamp at time zone 'Europe/London')
  ), cur as (select * from v where d >= d0), prev as (select * from v where d < d0)
  select jsonb_build_object(
    'days', n,
    'views', (select count(*) from cur),
    'visitors', (select count(distinct sid) from cur),
    'prev_views', (select count(*) from prev),
    'prev_visitors', (select count(distinct sid) from prev),
    'today_views', (select count(*) from cur where d = today),
    'today_visitors', (select count(distinct sid) from cur where d = today),
    'daily', (select coalesce(jsonb_agg(jsonb_build_object('d', g.d::date, 'views', coalesce(x.views, 0), 'visitors', coalesce(x.visitors, 0)) order by g.d), '[]'::jsonb)
              from generate_series(d0::timestamp, today::timestamp, interval '1 day') as g(d)
              left join (select d, count(*) as views, count(distinct sid) as visitors from cur group by d) x on x.d = g.d::date),
    'pages', (select coalesce(jsonb_agg(t order by t.views desc, t.path), '[]'::jsonb)
              from (select path, count(*) as views, count(distinct sid) as visitors from cur group by path order by count(*) desc, path limit 15) t),
    'refs', (select coalesce(jsonb_agg(t order by t.visitors desc, t.ref), '[]'::jsonb)
             from (select ref, count(distinct sid) as visitors from cur where ref is not null group by ref order by count(distinct sid) desc, ref limit 10) t),
    'from_ref', (select count(distinct sid) from cur where ref is not null),
    'devices', (select coalesce(jsonb_agg(t order by t.visitors desc), '[]'::jsonb)
                from (select coalesce(device, 'unknown') as device, count(distinct sid) as visitors from cur group by 1) t)
  ) into res;
  return res;
end $$;
revoke all on function public.admin_traffic(int) from public, anon;
grant execute on function public.admin_traffic(int) to authenticated;
