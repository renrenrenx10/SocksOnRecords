# Socks On Records data pull

Collected 2 Oct 2026 from the 23 Bandcamp pages, the label's Bandcamp/Big Cartel/Facebook, and press coverage.

Files
- bands.csv: one row per band (slug is the stable key). Import-ready for a Supabase `bands` table.
- links.csv: one row per band link (band_slug, platform, url).
- releases.csv: known releases. band_slugs is semicolon-separated; blank means a label-level release.
- socks-on-data.json: everything above in one file, plus label info and gigs.

What is still missing (Bandcamp's page text did not expose it)
- Instagram, Spotify, YouTube and website links: none captured for any band. Only We Punch Tigers has a Facebook link. Ask the bands.
- Full discographies: only 3 band pages exposed releases. Most release rows come from the label's page and have no date, URL or cover.
- Bios: 9 bands have none or a joke/dated one (see notes column).
- Locations: The Dodo Appreciation Society has none.
- Four label releases (2 Angry Songs, Elvytys, Bootlegs & B-Sides, two) have no artist captured.
- Bandcamp image URLs missing for Our Souls, Mices and Rough Pup (Rough Pup uses its EP cover).
- Gigs list is only what press and band sites showed, not a full history.

Band photos are NOT in this pack: use the originals in images/ (local_image_file column).
