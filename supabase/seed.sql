-- Socks On Records: starting data (23 bands, releases, past gigs).
-- Run AFTER schema.sql. Re-running is safe: rows are matched on slug/id and skipped if present.

insert into public.bands (slug,name,location,bio,bandcamp_url,instagram_url,facebook_url,spotify_url,youtube_url,website_url,bandcamp_image_url,sort_order) values
('das-kapitans','Das Kapitans','Peterborough, UK','Energetic indie punk rock from the Norfolk/Cambridgeshire borders. Founders of Socks On Records and lovers of friendly people.','https://daskapitansband.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0044990874_23.jpg',1),
('gtfod','Get The Fuck Outta Dodge','Sheffield, UK','Bass shouts and drum yelps from Def Leppard country.','https://gtfod.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0039456292_23.jpg',2),
('coup-de-tete','Coup De Tete','Peterborough, UK',null,'https://coupdetete.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0031643233_23.jpg',3),
('dan-the-d','The Dan The D (Dan Donovan)','England, UK',null,'https://dandonovan.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0040329785_23.jpg',4),
('our-souls','Our Souls','Leicester, UK','Louche Leicester quartet pedalling a brand of melodic punk rock.','https://weareoursouls.bandcamp.com/',null,null,null,null,null,null,5),
('soviet-films','Soviet Films','Peterborough, UK',null,'https://sovietfilms.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0032513105_23.jpg',6),
('good-job-kid','Good Job Kid','Peterborough, UK','Peterborough Synth Fuelled Midwest Emo Attempt','https://goodjobkid.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0040462438_23.jpg',7),
('dodo-appreciation-society','The Dodo Appreciation Society',null,'All hail the dodo','https://thedodoappreciationsociety1.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0032366728_23.jpg',8),
('we-punch-tigers','We Punch Tigers','Basildon, UK','Punk band','https://wepunchtigers.bandcamp.com/',null,'https://www.facebook.com/WePunchTigersBand/',null,null,null,'https://f4.bcbits.com/img/0027532590_23.jpg',9),
('mices','Mices','Norwich, UK',null,'https://micesareaband.bandcamp.com/',null,null,null,null,null,null,10),
('sprainer','Sprainer','Peterborough, UK','No Sprain, No Gain. Anglia, East. Unplaceable Accents. Ska-Curious. Jazz for the dumb and upset. Pop for the deeply confused. Beer Spillers. Rear Spillers. Career Spillers. Music for the Scorched Palette. Sprainer Must Be Stopped.','https://sprainer.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0037444117_23.jpg',11),
('the-prods','The Prods','London, UK','Punk, balladry and humour sometimes guaranteed. A British take on life viewed through a pint-shaped lens.','https://theprods.bandcamp.com/',null,null,null,null,'https://theprods.com','https://f4.bcbits.com/img/0014995956_23.jpg',12),
('oh-doom','Oh Doom!','North London / Hertfordshire, UK','Loud, sad songs from North London/Hertfordshire, UK.','https://ohdoom.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0036209266_23.jpg',13),
('for-i-the-badger','For I The Badger','England, UK','Formed in 2023, For I The Badger are a 4 piece alternative/punk band mixing intensity with intent. Their sound combines driving, melodic bass lines and lyrics that bite.','https://forithebadger.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0042978890_23.jpg',14),
('rudimentary-paste','Rudimentary Paste','England, UK','Emerging like the withered oldmanbabyface of Kuato from the exposed torso of foamcore pioneers such as Not Your Damned Apples and Morse Code Operator #2. Postmodernist manwrong art-wonk nonsense.','https://rudimentarypaste.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0041112688_23.jpg',15),
('a-great-notion','A Great Notion','Peterborough, UK','Four piece punk rock from Cambridgeshire. New album ''unsociabilities...'' out 9th June 2023','https://agreatnotion.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0032427506_23.jpg',16),
('jrowsy','jrowsy','Peterborough, UK','jrowsy is an alternative artist from Peterborough, UK. part of Socks on Records.','https://jrowsy.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0046488777_23.jpg',17),
('dead-leaves','Dead Leaves','Peterborough, UK','Dead Leaves are a Peterborough (UK) based band, sharing a love for soaring melodies with fuzz gazer interludes. The name reflects a desire for a degree of humility mixed with an urge to create songs that matter and have meaning. A reaction to the what-you-see-is-what-you-get punk resurgence in recent years, Dead Leaves offer depth and soulfulness.','https://deadleaves2.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0041182860_23.jpg',18),
('rough-pup','Rough Pup','England, UK',null,'https://roughpup.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/a3019491631_5.jpg',19),
('ooh-shush','Ooh Shush','Peterborough, UK','Funky, indie, punky','https://oohshush.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0043393456_23.jpg',20),
('kanfora','Kanfora','Varese, Italy','Most of what we have been is here. Music is just a medium.','https://kanfora.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0041931219_23.jpg',21),
('my-name-is-o','My Name Is O','London, UK',null,'https://nameequalso.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0038728855_23.jpg',22),
('al-pacinos-sister','Al Pacinos Sister','England, UK',null,'https://alpacinossister.bandcamp.com/',null,null,null,null,null,'https://f4.bcbits.com/img/0045131584_23.jpg',23)
on conflict (slug) do nothing;

insert into public.band_notes (band_id, note)
select b.id, v.note from (values
('das-kapitans','Bandcamp bio says they founded Socks On Records.'),
('coup-de-tete','No bio on Bandcamp.'),
('dan-the-d','No bio text captured. Bandcamp description mentions 18 albums recorded over 30 years; get a proper bio from Dan.'),
('our-souls','Bandcamp image URL not captured.'),
('soviet-films','No bio on Bandcamp.'),
('good-job-kid','Members listed on Bandcamp: Will and Aidan.'),
('dodo-appreciation-society','No location on Bandcamp. Original bio ends with three praying-hands emoji.'),
('we-punch-tigers','Bandcamp bio is minimal: ''Punk band'' / ''Punk songs''.'),
('mices','No bio captured. Location from the label''s artist list.'),
('the-prods','Own site with gigs: https://theprods.com'),
('for-i-the-badger','Bandcamp also calls them odd, unhinged and politically angry, with songs on mental health, addiction, injustice and poverty.'),
('rudimentary-paste','Bio is a joke; the band may want a straighter one for the site.'),
('a-great-notion','Bio is dated (2023 album announcement); ask for a current one.'),
('rough-pup','No bio or location on the page. Debut EP Something To Say is on Socks On Records.'),
('ooh-shush','Local image file is named ''Oh Shush.jpg''; the band is Ooh Shush.'),
('my-name-is-o','No bio. Local image is a tiny pink ring (6 KB), needs a real photo. Bandcamp lists releases as ''O''.'),
('al-pacinos-sister','No bio. Local filename has a typo (Pachinos).')
) as v(slug,note) join public.bands b on b.slug=v.slug
on conflict (band_id) do nothing;

insert into public.releases (id,title,artist_text,type,released_text,released_date,bandcamp_url,cover_url,label) values
('4f930c97-9a34-5dea-a827-68703ee5a0f9','Something To Say','Rough Pup','EP','13 April 2026','2026-04-13'::date,'https://roughpup.bandcamp.com/album/something-to-say','https://f4.bcbits.com/img/a3019491631_5.jpg','Socks On Records'),
('02890672-6569-5f82-86a3-b64ccf300d61','EP 1','Mices','EP','31 May 2023','2023-05-31'::date,'https://micesareaband.bandcamp.com/album/ep-1','https://f4.bcbits.com/img/a0696584074_5.jpg',null),
('30adf30d-4612-51d5-b578-b4286a760ff6','¡Unchained Melanie!','Our Souls','Track','06 June 2026','2026-06-06'::date,'https://weareoursouls.bandcamp.com/track/unchained-melanie','https://f4.bcbits.com/img/a4142406108_5.jpg',null),
('7bbb5c2d-1a09-54f0-8644-8c8eaf049946','unsociabilities...','A Great Notion','Album','9 June 2023','2023-06-09'::date,null,null,null),
('a7f506d1-d2e1-596b-a5ff-653e72bcdf59','Get Up','Das Kapitans','EP',null,null,null,null,'Socks On Records'),
('187d578e-1e83-5f1e-ac75-a558397b2a60','Idol (Single)','Das Kapitans','Single','Jun 2023',null,null,null,'Socks On Records'),
('1c861696-c9a2-544c-b06a-3a3e0d35cb8f','Lungs','Das Kapitans','Release',null,null,null,null,'Socks On Records'),
('54cf029c-5e4a-5c5c-b17d-13c80f8cb0f7','Live at P-Town''s Most Wanted','Das Kapitans','Live',null,null,null,null,'Socks On Records'),
('36e6ed96-6276-51fd-bb17-85f1b8445cd3','Live at Mamma Liz''s Voodoo Lounge','Das Kapitans','Live',null,null,null,null,'Socks On Records'),
('994f74fc-2357-51c0-a872-9c6148a015e9','The Dogs Got Jobs','Das Kapitans','Release',null,null,null,null,'Socks On Records'),
('65d12fd2-484a-5ef7-be1e-470840859778','Das Kapitans','Das Kapitans','Release','May 2024',null,null,null,'Socks On Records'),
('0fc0eacf-aacd-5236-ab38-f96881b98bf8','SPLIT','Das Kapitans & Mices','Split',null,null,null,null,'Socks On Records'),
('0d621f0f-ebd8-523c-9aec-e8425265bb2a','Live At The Ostrich','Al Pacinos Sister','Live',null,null,null,null,'Socks On Records'),
('89873814-c42a-5007-b960-eb9b24c6fed9','Trevor','Al Pacinos Sister','Release',null,null,null,null,'Socks On Records'),
('5eb8d125-bad4-5860-867d-a76329f137ab','La La Land','Al Pacinos Sister','Release',null,null,null,null,'Socks On Records'),
('c2c54edf-2f19-571b-a615-a87283f3a0b9','Slipped Through The Moment','O (My Name Is O)','Release',null,null,null,null,'Socks On Records'),
('a259c139-c792-50a5-8ed3-f36c8b29ff65','Night Fades Too Soon/Sinking','O featuring The Dan The D','Release',null,null,null,null,'Socks On Records'),
('04a78e36-8b1f-578b-bf6f-aa2bf6be21e0','Socks On Records & Friends Vol 2','Various artists','Compilation','23 March 2023','2023-03-23'::date,'https://socksonrecords.bandcamp.com/album/socks-on-records-friends-vol-2',null,'Socks On Records'),
('3ac0f3d7-a7c1-5e34-88dd-0409d0b0671b','Socks On Records And Friends Volume 3','Various artists','Compilation','01 September 2023','2023-09-01'::date,'https://socksonrecords.bandcamp.com/album/socks-on-records-and-friends-volume-3',null,'Socks On Records'),
('8dc73a21-50df-5aec-b9cc-3087ebcc6ee2','Live at Mama Liz''s Voodoo Lounge','Socks On Records','Live','May 2023',null,null,null,'Socks On Records'),
('df23e383-1fcb-5a59-984e-049fcde3b348','Socks On Party Live 2025','Socks On Records','Live','2025',null,null,null,'Socks On Records'),
('b94273dc-6ed8-58c9-b973-457dd5228b56','2 Angry Songs','[artist unknown]','Release','Mar 2026',null,null,null,'Socks On Records'),
('17601666-fe8f-5d6b-a75f-e7d429e90bb4','Elvytys','[artist unknown]','Release','Apr 2026',null,null,null,'Socks On Records'),
('e5bd7f4d-155a-5f14-896d-ca8e8115958d','Bootlegs & B-Sides','[artist unknown]','Release','May 2026',null,null,null,'Socks On Records'),
('0fa6ddd4-8b53-5c44-96b2-48c1787e9c41','two','[artist unknown]','Release','May 2026',null,null,null,'Socks On Records')
on conflict (id) do nothing;

insert into public.release_bands (release_id, band_id)
select v.rid::uuid, b.id from (values
('4f930c97-9a34-5dea-a827-68703ee5a0f9','rough-pup'),
('02890672-6569-5f82-86a3-b64ccf300d61','mices'),
('30adf30d-4612-51d5-b578-b4286a760ff6','our-souls'),
('7bbb5c2d-1a09-54f0-8644-8c8eaf049946','a-great-notion'),
('a7f506d1-d2e1-596b-a5ff-653e72bcdf59','das-kapitans'),
('187d578e-1e83-5f1e-ac75-a558397b2a60','das-kapitans'),
('1c861696-c9a2-544c-b06a-3a3e0d35cb8f','das-kapitans'),
('54cf029c-5e4a-5c5c-b17d-13c80f8cb0f7','das-kapitans'),
('36e6ed96-6276-51fd-bb17-85f1b8445cd3','das-kapitans'),
('994f74fc-2357-51c0-a872-9c6148a015e9','das-kapitans'),
('65d12fd2-484a-5ef7-be1e-470840859778','das-kapitans'),
('0fc0eacf-aacd-5236-ab38-f96881b98bf8','das-kapitans'),
('0fc0eacf-aacd-5236-ab38-f96881b98bf8','mices'),
('0d621f0f-ebd8-523c-9aec-e8425265bb2a','al-pacinos-sister'),
('89873814-c42a-5007-b960-eb9b24c6fed9','al-pacinos-sister'),
('5eb8d125-bad4-5860-867d-a76329f137ab','al-pacinos-sister'),
('c2c54edf-2f19-571b-a615-a87283f3a0b9','my-name-is-o'),
('a259c139-c792-50a5-8ed3-f36c8b29ff65','my-name-is-o'),
('a259c139-c792-50a5-8ed3-f36c8b29ff65','dan-the-d')
) as v(rid,slug) join public.bands b on b.slug=v.slug
on conflict do nothing;

insert into public.gigs (id,title,series,event_date,venue_name,venue_address,price_text,status) values
('b69613b1-fdf7-5069-a06f-7eb5eb8f2275','The Yee-Haws / Das Kapitans / Rudimentary Paste',null,'2026-10-02'::date,'The Holloway','Norwich','£5','sold_out'),
('d14b1d09-f69a-5fe3-a1a4-2e6ec2299f77','East Angrier X','East Angrier','2025-01-25'::date,'The Ostrich Inn','17 North Street, Peterborough PE1 2RA',null,'on_sale'),
('d7a7adbb-f651-530b-a8a5-be4ba21236cc','East Angrier 8: Socks On Records night','East Angrier','2024-07-13'::date,null,null,null,'on_sale'),
('ca4cd4ca-80e1-5eef-aabc-0ec7bc327bd5','East Angrier 7','East Angrier','2024-01-13'::date,'The Ostrich Inn','17 North Street, Peterborough PE1 2RA',null,'on_sale'),
('02e4c268-725f-54ad-8592-7527531136cb','Two-day punk weekender',null,'2023-07-15'::date,'The Ostrich Inn','17 North Street, Peterborough PE1 2RA','Free','free')
on conflict (id) do nothing;

-- Line-ups. Roster bands link to their band row; everyone else is a guest act.
insert into public.gig_acts (id,gig_id,band_id,act_name,position)
select gen_random_uuid(), v.gid::uuid, b.id, v.act, v.pos from (values
('b69613b1-fdf7-5069-a06f-7eb5eb8f2275',0,null,'The Yee-Haws'),
('b69613b1-fdf7-5069-a06f-7eb5eb8f2275',1,'das-kapitans',null),
('b69613b1-fdf7-5069-a06f-7eb5eb8f2275',2,'rudimentary-paste',null),
('d14b1d09-f69a-5fe3-a1a4-2e6ec2299f77',0,null,'Spoilers'),
('d14b1d09-f69a-5fe3-a1a4-2e6ec2299f77',1,null,'Verse Chorus Inferno'),
('d14b1d09-f69a-5fe3-a1a4-2e6ec2299f77',2,'das-kapitans',null),
('d14b1d09-f69a-5fe3-a1a4-2e6ec2299f77',3,'sprainer',null),
('d14b1d09-f69a-5fe3-a1a4-2e6ec2299f77',4,'mices',null),
('d14b1d09-f69a-5fe3-a1a4-2e6ec2299f77',5,null,'Dudesmell'),
('d14b1d09-f69a-5fe3-a1a4-2e6ec2299f77',6,'our-souls',null),
('d14b1d09-f69a-5fe3-a1a4-2e6ec2299f77',7,'rudimentary-paste',null),
('d14b1d09-f69a-5fe3-a1a4-2e6ec2299f77',8,null,'Yoke'),
('d14b1d09-f69a-5fe3-a1a4-2e6ec2299f77',9,null,'Adventures By Post'),
('d7a7adbb-f651-530b-a8a5-be4ba21236cc',0,'das-kapitans',null),
('d7a7adbb-f651-530b-a8a5-be4ba21236cc',1,'mices',null),
('d7a7adbb-f651-530b-a8a5-be4ba21236cc',2,'coup-de-tete',null),
('ca4cd4ca-80e1-5eef-aabc-0ec7bc327bd5',0,null,'Pest'),
('ca4cd4ca-80e1-5eef-aabc-0ec7bc327bd5',1,null,'Call To The Faithful'),
('ca4cd4ca-80e1-5eef-aabc-0ec7bc327bd5',2,null,'Slater'),
('ca4cd4ca-80e1-5eef-aabc-0ec7bc327bd5',3,'our-souls',null),
('ca4cd4ca-80e1-5eef-aabc-0ec7bc327bd5',4,null,'Wicca'),
('ca4cd4ca-80e1-5eef-aabc-0ec7bc327bd5',5,'gtfod',null),
('ca4cd4ca-80e1-5eef-aabc-0ec7bc327bd5',6,null,'Dogs! Teeth!'),
('ca4cd4ca-80e1-5eef-aabc-0ec7bc327bd5',7,null,'Radio Aftermath'),
('ca4cd4ca-80e1-5eef-aabc-0ec7bc327bd5',8,'jrowsy',null)
) as v(gid,pos,slug,act) left join public.bands b on b.slug=v.slug
where not exists (select 1 from public.gig_acts x where x.gig_id=v.gid::uuid);
