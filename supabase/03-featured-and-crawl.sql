-- Socks On Records: featured release box + extra release details.
-- Run once in Supabase: SQL Editor > New query > paste > Run. Safe to re-run.
-- Run this BEFORE 04-crawl-import.sql.

-- Small key/value table for site-wide bits an admin edits (the featured release for now)
create table if not exists public.site_settings (
  key        text primary key,
  value      jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.site_settings enable row level security;
drop policy if exists site_settings_select on public.site_settings;
create policy site_settings_select on public.site_settings for select using (true);
drop policy if exists site_settings_admin on public.site_settings;
create policy site_settings_admin on public.site_settings for all
  using (public.is_admin()) with check (public.is_admin());
grant select on public.site_settings to anon, authenticated;
grant insert, update, delete on public.site_settings to authenticated;

-- Extra detail on each release (filled by the Bandcamp crawler, editable later)
alter table public.releases add column if not exists embed_url   text;   -- Bandcamp player, e.g. https://bandcamp.com/EmbeddedPlayer/album=123/
alter table public.releases add column if not exists description text;
alter table public.releases add column if not exists tracks      jsonb;
