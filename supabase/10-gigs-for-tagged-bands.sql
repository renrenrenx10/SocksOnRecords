-- Socks On Records: a band can see and edit any gig it is in the line-up of (not just gigs it created).
-- Run once in the Supabase SQL Editor (safe to run again).

create or replace function public.can_edit_gig(gid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_admin()
    or exists (select 1 from public.gigs g where g.id = gid and g.created_by = auth.uid())
    or exists (select 1 from public.gig_acts a
               join public.band_members m on m.band_id = a.band_id
               where a.gig_id = gid and m.user_id = auth.uid())
$$;
grant execute on function public.can_edit_gig(uuid) to authenticated;

drop policy if exists gigs_update on public.gigs;
create policy gigs_update on public.gigs for update
  using (public.can_edit_gig(id)) with check (public.can_edit_gig(id));
drop policy if exists gigs_delete on public.gigs;
create policy gigs_delete on public.gigs for delete
  using (public.can_edit_gig(id));

-- the line-up: whoever can edit the gig can change it
drop policy if exists gig_acts_write on public.gig_acts;
create policy gig_acts_write on public.gig_acts for all
  using (public.can_edit_gig(gig_id)) with check (public.can_edit_gig(gig_id));

-- Saving a line-up replaces it in one go. This has to be one step: if the app deleted the old
-- line-up first, a band that is only on the gig through its tag would lose the right to add it back.
create or replace function public.set_gig_acts(p_gig uuid, p_acts jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.can_edit_gig(p_gig) then raise exception 'You cannot edit this gig'; end if;
  delete from public.gig_acts where gig_id = p_gig;
  insert into public.gig_acts (gig_id, band_id, act_name, position)
    select p_gig, nullif(a->>'band_id', '')::uuid, nullif(a->>'act_name', ''), coalesce((a->>'position')::int, 0)
    from jsonb_array_elements(coalesce(p_acts, '[]'::jsonb)) as a
    where nullif(a->>'band_id', '') is not null or nullif(a->>'act_name', '') is not null;
end $$;
revoke all on function public.set_gig_acts(uuid, jsonb) from public, anon;
grant execute on function public.set_gig_acts(uuid, jsonb) to authenticated;
