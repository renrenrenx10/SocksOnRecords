-- Socks On Records: fix "new row violates row-level security policy for table release_bands"
-- when a band member edits a release their band is on.
-- Run once in the Supabase SQL Editor (safe to run again).
--
-- Why it failed: saving used to delete the band's link to the release and then add it back.
-- For a release an admin created, that link is the ONLY thing giving the band the right to edit it,
-- so once it was deleted the add-back was refused. This does it in one step instead.

create or replace function public.set_release_bands(p_release uuid, p_bands uuid[])
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.can_edit_release(p_release) then raise exception 'You cannot edit this release'; end if;
  -- admins replace the whole list; band members only change their own bands' links
  delete from public.release_bands rb
   where rb.release_id = p_release
     and (public.is_admin() or public.is_band_member(rb.band_id));
  insert into public.release_bands (release_id, band_id)
    select p_release, b from (select distinct unnest(coalesce(p_bands, '{}'::uuid[])) as b) x
    where b is not null and (public.is_admin() or public.is_band_member(b))
    on conflict do nothing;
end $$;
revoke all on function public.set_release_bands(uuid, uuid[]) from public, anon;
grant execute on function public.set_release_bands(uuid, uuid[]) to authenticated;
