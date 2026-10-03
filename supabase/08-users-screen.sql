-- Socks On Records: Users screen (last sign-in) and a reliable admin on/off switch.
-- Run once in the Supabase SQL Editor (safe to run again).

-- Admin-only list of every login with last sign-in time
create or replace function public.admin_list_users()
returns table (id uuid, email text, display_name text, is_admin boolean, created_at timestamptz, last_sign_in_at timestamptz)
language plpgsql stable security definer set search_path = public, auth as $$
begin
  if not public.is_admin() then raise exception 'Only admins can see the user list'; end if;
  return query
    select u.id, u.email::text, p.display_name, coalesce(p.is_admin, false), u.created_at, u.last_sign_in_at
    from auth.users u left join public.profiles p on p.id = u.id
    order by lower(coalesce(p.display_name, u.email::text));
end $$;

-- Admin-only: make someone an admin, or take it away (not for yourself)
create or replace function public.admin_set_admin(p_user uuid, p_admin boolean)
returns void language plpgsql security definer set search_path = public, auth as $$
begin
  if not public.is_admin() then raise exception 'Only admins can change who is an admin'; end if;
  if p_user = auth.uid() then raise exception 'You cannot change your own admin status'; end if;
  insert into public.profiles (id, email)
    select u.id, u.email::text from auth.users u where u.id = p_user
    on conflict (id) do nothing;
  update public.profiles set is_admin = p_admin where id = p_user;
  if not found then raise exception 'No such login'; end if;
end $$;

revoke all on function public.admin_list_users() from public, anon;
revoke all on function public.admin_set_admin(uuid, boolean) from public, anon;
grant execute on function public.admin_list_users() to authenticated;
grant execute on function public.admin_set_admin(uuid, boolean) to authenticated;
