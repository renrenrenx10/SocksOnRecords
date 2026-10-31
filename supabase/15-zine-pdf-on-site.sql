-- Point issue 1 at the copy of the PDF kept with the website (instead of Supabase storage).
-- This stops zine downloads counting against Supabase's bandwidth. Safe to run twice.
update public.zine_issues
set pdf_url = 'https://socksonrecords.uk/zine/issue-1.pdf'
where issue_number = 1;
