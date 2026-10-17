-- Fanzine: let an admin edit (and delete) any contributor's page, not just the pages they
-- created themselves. zine_pages/zine_issues were set up outside this migration folder, so this
-- adds explicit, idempotent policies rather than assuming what's there now -- safe to run again.
-- Run once in the Supabase SQL Editor.

alter table public.zine_pages enable row level security;
alter table public.zine_issues enable row level security;

-- ---- zine_pages: every contributor can read and add pages; only the page's own creator or an
-- admin can update/delete it. This is what made admin edits on someone else's page silently fail
-- to save before -- the UPDATE was being rejected by Postgres with no visible error in the app.
drop policy if exists zine_pages_select on public.zine_pages;
create policy zine_pages_select on public.zine_pages for select
  to authenticated using (true);

drop policy if exists zine_pages_insert on public.zine_pages;
create policy zine_pages_insert on public.zine_pages for insert
  to authenticated with check (public.is_admin() or created_by = auth.uid());

drop policy if exists zine_pages_update on public.zine_pages;
create policy zine_pages_update on public.zine_pages for update
  to authenticated using (public.is_admin() or created_by = auth.uid())
  with check (public.is_admin() or created_by = auth.uid());

drop policy if exists zine_pages_delete on public.zine_pages;
create policy zine_pages_delete on public.zine_pages for delete
  to authenticated using (public.is_admin() or created_by = auth.uid());

-- ---- zine_issues: one row per issue (published flag, pdf_url) -- not per-contributor, so every
-- signed-in contributor can read and write it, same as before; admin isn't required here.
drop policy if exists zine_issues_select on public.zine_issues;
create policy zine_issues_select on public.zine_issues for select
  to authenticated using (true);

drop policy if exists zine_issues_write on public.zine_issues;
create policy zine_issues_write on public.zine_issues for all
  to authenticated using (true) with check (true);
