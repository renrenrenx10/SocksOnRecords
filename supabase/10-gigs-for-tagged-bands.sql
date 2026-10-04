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
