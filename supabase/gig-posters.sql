-- Socks On Records: gig poster uploads.
-- Run once in Supabase: SQL Editor > New query > paste > Run. Safe to re-run.

alter table public.gigs add column if not exists poster_url text;

insert into storage.buckets (id, name, public)
values ('gig-posters', 'gig-posters', true)
on conflict (id) do nothing;

drop policy if exists gig_posters_read on storage.objects;
create policy gig_posters_read on storage.objects for select
  using (bucket_id = 'gig-posters');

-- Admins and band members can upload, into a folder named after their own user id
drop policy if exists gig_posters_insert on storage.objects;
create policy gig_posters_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'gig-posters'
    and (storage.foldername(name))[1] = auth.uid()::text
    and (public.is_admin() or exists (select 1 from public.band_members m where m.user_id = auth.uid())));

-- You can replace or delete your own uploads; admins can touch any
drop policy if exists gig_posters_update on storage.objects;
create policy gig_posters_update on storage.objects for update to authenticated
  using (bucket_id = 'gig-posters' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));
drop policy if exists gig_posters_delete on storage.objects;
create policy gig_posters_delete on storage.objects for delete to authenticated
  using (bucket_id = 'gig-posters' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));
