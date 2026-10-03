-- Socks On Records: Shop page (merch + tickets) and stock control.
-- Run once in the Supabase SQL Editor (safe to run again).

create table if not exists public.shop_items (
  id           uuid primary key default gen_random_uuid(),
  kind         text not null default 'merch' check (kind in ('merch', 'ticket')),
  title        text not null,
  description  text,
  price_pence  integer not null default 1000 check (price_pence >= 0),
  stock        integer not null default 0 check (stock >= 0),
  image_url    text,
  buy_url      text,          -- where "Buy" goes: Big Cartel, Dodge Designed This, a ticket seller...
  published    boolean not null default true,
  sort_order   integer not null default 0,
  created_at   timestamptz not null default now()
);

alter table public.shop_items enable row level security;
drop policy if exists shop_select on public.shop_items;
create policy shop_select on public.shop_items for select using (published or public.is_admin());
drop policy if exists shop_admin on public.shop_items;
create policy shop_admin on public.shop_items for all using (public.is_admin()) with check (public.is_admin());

-- Placeholders so the page has something on it (only added if the table is empty). Edit or delete in admin.
insert into public.shop_items (kind, title, description, price_pence, stock, sort_order)
select * from (values
  ('merch',  'Socks On tee',                  'Placeholder. Black tee with the Socks On logo.',                       1000, 25, 1),
  ('merch',  'Socks On compilation CD',       'Placeholder. A CD of bands from the label.',                          1000, 50, 2),
  ('merch',  'Socks On trucker cap',          'Placeholder. Mesh-back trucker cap.',                                  1000, 20, 3),
  ('ticket', 'Socks On night ticket',         'Placeholder. Swap this for a real gig and add the ticket link.',       1000, 40, 1)
) as v(kind, title, description, price_pence, stock, sort_order)
where not exists (select 1 from public.shop_items);
