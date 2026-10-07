-- Adds a cover image column to zine_issues so the /zine/ index page can show a cover
-- picture per issue, the same way releases already carry a cover_url.
-- Run this once in the Supabase SQL editor.

alter table zine_issues
  add column if not exists cover_url text;

-- Then set a cover image per issue, e.g.:
-- update zine_issues set cover_url = 'https://...' where issue_number = 1;
