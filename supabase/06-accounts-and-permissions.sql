-- Socks On Records: add logins from the admin screen, and let bands manage their own releases.
-- Run once in the Supabase SQL Editor (safe to run again).

-- ============ RELEASES: bands can add and edit their own ============
alter table public.releases add column if not exists created_by uuid default auth.uid() references auth.users(id) on delete set null;

create or replace function public.is_any_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.band_members where user_id = auth.uid())
$$;

-- admin, whoever added the release, or a member of a band that is on it
create or replace function public.can_edit_release(rid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_admin()
    or exists (select 1 from public.releases r where r.id = rid and r.created_by = auth.uid())
    or exists (select 1 from public.release_bands rb
               join public.band_members m on m.band_id = rb.band_id
               where rb.release_id = rid and m.user_id = auth.uid())
$$;

drop policy if exists releases_admin on public.releases;
drop policy if exists releases_insert on public.releases;
create policy releases_insert on public.releases for insert
  with check (public.is_admin() or (public.is_any_member() and (created_by is null or created_by = auth.uid())));
drop policy if exists releases_update on public.releases;
create policy releases_update on public.releases for update
  using (public.can_edit_release(id)) with check (public.can_edit_release(id));
drop policy if exists releases_delete on public.releases;
create policy releases_delete on public.releases for delete using (public.can_edit_release(id));

drop policy if exists release_bands_admin on public.release_bands;
drop policy if exists release_bands_insert on public.release_bands;
create policy release_bands_insert on public.release_bands for insert
  with check (public.is_admin() or (public.is_band_member(band_id) and public.can_edit_release(release_id)));
drop policy if exists release_bands_delete on public.release_bands;
create policy release_bands_delete on public.release_bands for delete
  using (public.is_admin() or (public.is_band_member(band_id) and public.can_edit_release(release_id)));
drop policy if exists release_bands_update on public.release_bands;
create policy release_bands_update on public.release_bands for update
  using (public.is_admin()) with check (public.is_admin());

-- ============ ADMIN-ONLY: create, re-password and remove logins ============
create or replace function public.admin_create_user(p_email text, p_name text, p_password text, p_band_ids uuid[] default '{}')
returns uuid language plpgsql security definer set search_path = public, auth, extensions as $$
declare
  uid uuid := gen_random_uuid();
  em  text := lower(trim(p_email));
  col text;
begin
  if not public.is_admin() then raise exception 'Only admins can add logins'; end if;
  if em is null or em !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'That email address does not look right: %', p_email; end if;
  if length(coalesce(p_password, '')) < 8 then raise exception 'The password needs at least 8 characters'; end if;
  if exists (select 1 from auth.users where lower(email) = em) then raise exception '% already has a login', em; end if;

  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  values ('00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated', em,
          extensions.crypt(p_password, extensions.gen_salt('bf')), now(),
          '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

  -- the login service expects these token columns to be '' rather than null
  foreach col in array array['confirmation_token','recovery_token','email_change_token_new','email_change',
                             'email_change_token_current','phone_change','phone_change_token','reauthentication_token'] loop
    if exists (select 1 from information_schema.columns where table_schema = 'auth' and table_name = 'users' and column_name = col) then
      execute format('update auth.users set %I = coalesce(%I, '''') where id = $1', col, col) using uid;
    end if;
  end loop;

  insert into auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  values (uid::text, uid, jsonb_build_object('sub', uid::text, 'email', em, 'email_verified', true, 'phone_verified', false),
          'email', now(), now(), now());

  insert into public.profiles (id, email, display_name) values (uid, em, nullif(trim(p_name), ''))
    on conflict (id) do update set display_name = excluded.display_name, email = excluded.email;
  insert into public.band_members (band_id, user_id)
    select b, uid from unnest(coalesce(p_band_ids, '{}')) as b on conflict do nothing;
  return uid;
end $$;

create or replace function public.admin_set_password(p_user uuid, p_password text)
returns void language plpgsql security definer set search_path = public, auth, extensions as $$
begin
  if not public.is_admin() then raise exception 'Only admins can change someone else''s password'; end if;
  if length(coalesce(p_password, '')) < 8 then raise exception 'The password needs at least 8 characters'; end if;
  update auth.users set encrypted_password = extensions.crypt(p_password, extensions.gen_salt('bf')), updated_at = now() where id = p_user;
  if not found then raise exception 'No such login'; end if;
end $$;

create or replace function public.admin_delete_user(p_user uuid)
returns void language plpgsql security definer set search_path = public, auth as $$
begin
  if not public.is_admin() then raise exception 'Only admins can remove logins'; end if;
  if p_user = auth.uid() then raise exception 'You cannot remove your own login'; end if;
  delete from auth.users where id = p_user;
end $$;

revoke all on function public.admin_create_user(text, text, text, uuid[]) from public, anon;
revoke all on function public.admin_set_password(uuid, text) from public, anon;
revoke all on function public.admin_delete_user(uuid) from public, anon;
grant execute on function public.admin_create_user(text, text, text, uuid[]) to authenticated;
grant execute on function public.admin_set_password(uuid, text) to authenticated;
grant execute on function public.admin_delete_user(uuid) to authenticated;
grant execute on function public.is_any_member() to authenticated;
grant execute on function public.can_edit_release(uuid) to authenticated;
