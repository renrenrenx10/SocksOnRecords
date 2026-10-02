-- Merch link per band. Blank means the site uses the band's Bandcamp page + /merch.
-- Safe to run more than once.
alter table public.bands add column if not exists merch_url text;
