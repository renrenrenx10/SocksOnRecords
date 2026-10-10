#!/usr/bin/env python3
"""Socks On Records: builds the search-friendly pages, sitemap.xml and robots.txt.

The main site is one interactive page, which search engines and link previews can't see into.
This script reads the live data from Supabase and writes plain, fast, crawlable pages:
  /roster/  /band/<slug>/  /gigs/  /releases/  /videos/  /sessions/  /merch/  /contact/  /404.html
plus sitemap.xml and robots.txt. It runs by itself every day on GitHub (see .github/workflows/seo.yml),
or run it yourself:   python tools/generate_seo.py        (needs only Python 3, no installs)
To test without the network:   python tools/generate_seo.py --from-json sample.json
"""
import json, os, re, sys, html, urllib.request, urllib.parse, datetime

SITE = "https://socksonrecords.uk"
SUPA = "https://xnbkdgmojfupjerqorcw.supabase.co/rest/v1/"
KEY = "sb_publishable__XrZLQTrqwf9xeLBn5xI7w_vVgFJzCf"
ROOT = os.environ.get("SEO_ROOT") or os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OG_DEFAULT = SITE + "/og-image.jpg"
NAME = "Socks On Records"
TAG = "DIY punk label, Peterborough & King's Lynn"
DESC = ("Socks On Records is a DIY, non-profit record label and gig promoter in Peterborough and King's Lynn. "
        "Meet the bands, find gigs, releases, videos, Socks On Sessions and merch.")
e = lambda s: html.escape(str(s if s is not None else ""), quote=True)
today = datetime.date.today().isoformat()

# ---------------------------------------------------------------- data
def get(path):
    req = urllib.request.Request(SUPA + path, headers={"apikey": KEY, "Authorization": "Bearer " + KEY})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)

MONTHS = {m: i + 1 for i, m in enumerate("jan feb mar apr may jun jul aug sep oct nov dec".split())}

def rel_key(r):
    """Newest-first key: the release date if set, else worked out from the text ("Sep 2023", "2021")."""
    if r.get("released_date"): return r["released_date"][:10]
    t = r.get("released_text") or ""
    y = re.search(r"\b(1[89]\d\d|20\d\d)\b", t)
    if not y: return ""
    m = re.search(r"\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\b", t, re.I)
    dd = re.search(r"\b([0-3]?\d)(?:st|nd|rd|th)?\b(?=\s+(?:of\s+)?[A-Za-z])", t)
    day = int(dd.group(1)) if m and dd and 1 <= int(dd.group(1)) <= 31 else 1
    return "%s-%02d-%02d" % (y.group(1), MONTHS[m.group(1).lower()] if m else 1, day)

def sort_releases(rs):
    rs = sorted(rs, key=lambda r: (r.get("title") or "").lower())
    return sorted(rs, key=rel_key, reverse=True)

def load():
    if "--from-json" in sys.argv:
        d = json.load(open(sys.argv[sys.argv.index("--from-json") + 1], encoding="utf-8"))
        d["releases"] = sort_releases(d.get("releases") or [])
        return d
    d = {}
    d["bands"] = get("bands?select=*&published=eq.true&order=sort_order.asc,name.asc")
    d["gigs"] = get("gigs?select=*,gig_acts(position,act_name,bands(slug,name))&order=event_date.asc")
    d["releases"] = get("releases?select=title,artist_text,type,released_text,released_date,bandcamp_url,cover_url,release_bands(bands(slug))&order=released_date.desc.nullslast,title.asc")
    for k, q in (("videos", "videos?select=title,youtube_url,bands(slug,name)&published=eq.true&order=sort_order.asc"),
                 ("sessions", "sessions?select=*,bands(slug,name)&published=eq.true&order=session_date.desc.nullslast"),
                 ("shop", "shop_items?select=*&published=eq.true&order=sort_order.asc")):
        try: d[k] = get(q)
        except Exception as ex: print("skipped", k, ex); d[k] = []
    d["releases"] = sort_releases(d["releases"])
    return d

# ---------------------------------------------------------------- helpers
def clip(s, n=158):
    s = re.sub(r"\s+", " ", s or "").strip()
    if len(s) <= n: return s
    return s[:n].rsplit(" ", 1)[0].rstrip(",.;: ") + "…"

def yt_id(u):
    m = re.search(r"(?:youtu\.be/|v=|/embed/|/shorts/|/live/)([A-Za-z0-9_-]{11})", u or "")
    return m.group(1) if m else None

def fmt_date(s):
    try:
        d = datetime.date.fromisoformat(s[:10])
        return d.strftime("%a ") + str(d.day) + d.strftime(" %b %Y")
    except Exception: return s or ""

def ld(obj): return '<script type="application/ld+json">' + json.dumps(obj, ensure_ascii=False).replace("</", "<\\/") + "</script>"

NAV = [("roster", "Roster"), ("gigs", "Gigs"), ("releases", "Releases"), ("videos", "Videos"),
       ("sessions", "Sessions"), ("https://socksonrecords.bigcartel.com/", "Merch"), ("contact", "Contact")]

def page(path, title, desc, body, image=None, jsonld=None, og_type="website", spa=None, noindex=False):
    url = SITE + "/" + path
    full_title = title if title.endswith(NAME) else f"{title} | {NAME}"
    img = image or OG_DEFAULT
    nav = "".join((f'<a href="{k}" rel="noopener">{v}</a>' if k.startswith("http") else f'<a href="/{k}/"{" aria-current=page" if path.startswith(k) else ""}>{v}</a>') for k, v in NAV)
    app = SITE + "/" + (spa or "")
    out = f"""<!doctype html>
<html lang="en-GB">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(full_title)}</title>
<meta name="description" content="{e(clip(desc))}">
<link rel="canonical" href="{e(url)}">
{'<meta name="robots" content="noindex">' if noindex else '<meta name="robots" content="index, follow, max-image-preview:large">'}
<meta name="theme-color" content="#16130F">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<meta property="og:site_name" content="{NAME}">
<meta property="og:locale" content="en_GB">
<meta property="og:type" content="{og_type}">
<meta property="og:title" content="{e(full_title)}">
<meta property="og:description" content="{e(clip(desc, 200))}">
<meta property="og:url" content="{e(url)}">
<meta property="og:image" content="{e(img)}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{e(full_title)}">
<meta name="twitter:description" content="{e(clip(desc, 200))}">
<meta name="twitter:image" content="{e(img)}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Anton&family=Archivo:wght@400;500;700&family=Space+Mono:wght@400;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/seo.css">
{ld(jsonld) if jsonld else ""}
</head>
<body>
<header class="top"><div class="w"><a class="logo" href="/"><img src="/logo.png" alt="{NAME}" width="130" height="65"></a><nav aria-label="Main">{nav}</nav></div></header>
<main class="w">
{body}
<p class="app"><a class="btn" href="{e(app)}">Open the full interactive site &rarr;</a></p>
</main>
<footer class="w"><p>{NAME} &middot; DIY label, gig promoters and community. Totally non-profit. &middot; Peterborough &amp; King's Lynn, East of England</p>
<p><a href="mailto:socksonrecords@gmail.com">socksonrecords@gmail.com</a> &middot; <a href="https://www.instagram.com/socks_on_records/">Instagram</a> &middot; <a href="https://www.instagram.com/socksongraphics/">Socks On Graphics</a></p></footer>
</body>
</html>
"""
    d = os.path.join(ROOT, path)
    os.makedirs(d, exist_ok=True)
    open(os.path.join(d, "index.html"), "w", encoding="utf-8").write(out)
    return url

def links(b):
    items = [("Bandcamp", b.get("bandcamp_url")), ("Instagram", b.get("instagram_url")), ("Facebook", b.get("facebook_url")),
             ("Spotify", b.get("spotify_url")), ("YouTube", b.get("youtube_url")), ("Website", b.get("website_url")),
             ("Merch", b.get("merch_url") or (b["bandcamp_url"].rstrip("/") + "/merch" if b.get("bandcamp_url") else None))]
    return [(n, u) for n, u in items if u]

def bimg(b):
    if b.get("image_url"): return b["image_url"]
    if os.path.exists(os.path.join(ROOT, "img", b["slug"] + ".jpg")): return f'{SITE}/img/{b["slug"]}.jpg'
    return b.get("bandcamp_image_url")

# ---------------------------------------------------------------- pages
def build(d):
    urls = []
    bands = d["bands"]; by_slug = {b["slug"]: b for b in bands}
    rel_by_band = {}
    for r in d["releases"]:
        for rb in r.get("release_bands") or []:
            s = rb.get("bands") and rb["bands"].get("slug")
            if s: rel_by_band.setdefault(s, []).append(r)
    gig_by_band = {}
    for g in d["gigs"]:
        for a in g.get("gig_acts") or []:
            s = a.get("bands") and a["bands"].get("slug")
            if s: gig_by_band.setdefault(s, []).append(g)
    upcoming = [g for g in d["gigs"] if g["event_date"] >= today and g.get("status") != "cancelled"]

    # --- roster
    cards = "".join(
        f'<article class="card"><a href="/band/{e(b["slug"])}/">' + (f'<img src="{e(bimg(b))}" alt="{e(b["name"])}" loading="lazy" width="400" height="400">' if bimg(b) else "")
        + f'</a><h2><a href="/band/{e(b["slug"])}/">{e(b["name"])}</a></h2><p class="mono">{e(b.get("location") or "")}</p><p>{e(clip(b.get("bio"), 120))}</p></article>' for b in bands)
    urls.append(page("roster/", "Roster: the bands on Socks On Records",
        f"Meet the {len(bands)} bands on Socks On Records, a DIY punk, hardcore and alternative label in Peterborough and King's Lynn.",
        f'<h1>Roster</h1><p class="lead">The bands on the label. Tap one for their music, gigs and links.</p><div class="grid">{cards}</div>',
        jsonld={"@context": "https://schema.org", "@type": "ItemList", "name": "Socks On Records roster",
                "itemListElement": [{"@type": "ListItem", "position": i + 1, "url": f'{SITE}/band/{b["slug"]}/', "name": b["name"]} for i, b in enumerate(bands)]},
        spa="#/roster"))

    # --- bands
    for b in bands:
        s = b["slug"]; rels = rel_by_band.get(s, []); gigs = gig_by_band.get(s, [])
        loc = b.get("location") or ""
        desc = clip(b.get("bio")) or f'{b["name"]}{" from " + loc if loc else ""}, on Socks On Records. Music, gigs and links.'
        ls = links(b)
        body = f'<h1>{e(b["name"])}</h1>' + (f'<p class="mono">{e(loc)}</p>' if loc else "")
        body += '<div class="split">' + (f'<img class="hero" src="{e(bimg(b))}" alt="{e(b["name"])}" width="600" height="600">' if bimg(b) else "")
        body += f'<div><p class="bio">{e(b.get("bio") or "").replace(chr(10), "<br>")}</p>'
        body += '<p class="btns">' + "".join(f'<a class="btn sm" href="{e(u)}" rel="noopener">{n}</a>' for n, u in ls) + "</p></div></div>"
        vid = yt_id(b.get("video_url"))
        if vid: body += f'<h2>Video</h2><p><a href="{e(b["video_url"])}" rel="noopener"><img class="thumb" src="https://i.ytimg.com/vi/{vid}/hqdefault.jpg" alt="Watch a video by {e(b["name"])}" loading="lazy" width="480" height="360"></a></p>'
        if rels:
            def rel_li(r):
                t = e(r["title"])
                if r.get("bandcamp_url"): t = '<a href="' + e(r["bandcamp_url"]) + '" rel="noopener">' + t + "</a>"
                return "<li>" + t + '<span class="mono"> ' + e(r.get("type") or "") + " " + e(r.get("released_text") or "") + "</span></li>"
            body += '<h2>Releases</h2><ul class="list">' + "".join(rel_li(r) for r in rels) + "</ul>"
        up = [g for g in gigs if g["event_date"] >= today and g.get("status") != "cancelled"]
        past = [g for g in gigs if g["event_date"] < today][::-1][:8]
        if up: body += "<h2>Upcoming gigs</h2><ul class=\"list\">" + "".join(f'<li>{e(g["title"])}<span class="mono"> {e(fmt_date(g["event_date"]))}{" · " + e(g["venue_name"]) if g.get("venue_name") else ""}</span></li>' for g in up) + "</ul>"
        if past: body += "<h2>Past gigs</h2><ul class=\"list\">" + "".join(f'<li>{e(g["title"])}<span class="mono"> {e(fmt_date(g["event_date"]))}{" · " + e(g["venue_name"]) if g.get("venue_name") else ""}</span></li>' for g in past) + "</ul>"
        obj = {"@context": "https://schema.org", "@type": "MusicGroup", "name": b["name"], "url": f"{SITE}/band/{s}/",
               "description": b.get("bio") or desc, "sameAs": [u for n, u in ls if n not in ("Merch",)]}
        if bimg(b): obj["image"] = bimg(b)
        if rels: obj["album"] = [{"@type": "MusicAlbum", "name": r["title"], **({"url": r["bandcamp_url"]} if r.get("bandcamp_url") else {})} for r in rels[:30]]
        urls.append(page(f"band/{s}/", f'{b["name"]}' + (f" ({loc})" if loc else ""), desc, body, image=bimg(b),
                         jsonld=obj, og_type="profile", spa=f"#/band/{s}"))

    # --- gigs
    def gig_li(g):
        acts = ", ".join(a.get("bands", {}) and a["bands"]["name"] if a.get("bands") else a.get("act_name") or "" for a in sorted(g.get("gig_acts") or [], key=lambda x: x.get("position") or 0))
        bits = [fmt_date(g["event_date"]), g.get("time_text"), g.get("venue_name"), g.get("price_text")]
        t = f'<li><strong>{e(g["title"])}</strong>' + (" <span class=\"tag\">Cancelled</span>" if g.get("status") == "cancelled" else "") + (" <span class=\"tag\">Sold out</span>" if g.get("status") == "sold_out" else "")
        t += f'<br><span class="mono">{e(" · ".join(x for x in bits if x))}</span>' + (f"<br>{e(acts)}" if acts else "")
        if g.get("ticket_url") and g.get("status") not in ("cancelled", "sold_out"): t += f' <a class="btn sm" href="{e(g["ticket_url"])}" rel="noopener">Tickets</a>'
        return t + "</li>"
    events = []
    for g in upcoming:
        ev = {"@type": "Event", "name": g["title"], "startDate": g["event_date"], "eventAttendanceMode": "https://schema.org/OfflineEventAttendanceMode",
              "eventStatus": "https://schema.org/EventScheduled", "organizer": {"@type": "Organization", "name": NAME, "url": SITE},
              "location": {"@type": "Place", "name": g.get("venue_name") or "Venue to be confirmed", "address": g.get("venue_address") or g.get("venue_name") or "East of England"}}
        if g.get("poster_url"): ev["image"] = g["poster_url"]
        acts = [a["bands"]["name"] if a.get("bands") else a.get("act_name") for a in (g.get("gig_acts") or [])]
        if any(acts): ev["performer"] = [{"@type": "MusicGroup", "name": a} for a in acts if a]
        if g.get("ticket_url"): ev["offers"] = {"@type": "Offer", "url": g["ticket_url"], "availability": "https://schema.org/SoldOut" if g.get("status") == "sold_out" else "https://schema.org/InStock"}
        events.append(ev)
    past = [g for g in d["gigs"] if g["event_date"] < today][::-1]
    body = '<h1>Gigs</h1><p class="lead">Live punk, hardcore and DIY shows in Peterborough, King\'s Lynn and beyond.</p>'
    body += "<h2>Coming up</h2>" + ('<ul class="list">' + "".join(gig_li(g) for g in upcoming) + "</ul>" if upcoming else "<p>Nothing announced right now. Follow us on Instagram for news.</p>")
    body += "<h2>Past gigs</h2><ul class=\"list\">" + "".join(gig_li(g) for g in past[:60]) + "</ul>"
    first = upcoming[0] if upcoming else None
    urls.append(page("gigs/", "Gigs: live punk shows in Peterborough & King's Lynn",
        (f'Next up: {first["title"]} on {fmt_date(first["event_date"])}. ' if first else "") + "Upcoming and past Socks On Records gigs across Peterborough, King's Lynn and the East of England.",
        body, jsonld={"@context": "https://schema.org", "@graph": events} if events else None, image=(first or {}).get("poster_url"), spa="#/gigs"))

    # --- releases
    body = '<h1>Releases</h1><p class="lead">Albums, EPs, singles and compilations from the label and its bands. Listen on Bandcamp.</p><ul class="list">'
    for r in d["releases"]:
        t = e(r["title"])
        if r.get("bandcamp_url"): t = f'<a href="{e(r["bandcamp_url"])}" rel="noopener">{t}</a>'
        body += f'<li><strong>{t}</strong> <span class="mono">{e(r.get("artist_text") or "")} · {e(r.get("type") or "")} {e(r.get("released_text") or "")}</span></li>'
    urls.append(page("releases/", "Releases: albums, EPs and singles",
        f'{len(d["releases"])} releases from Socks On Records and its bands. Punk, hardcore and alternative music, streaming and download on Bandcamp.', body + "</ul>", spa="#/releases"))

    # --- videos
    vids = [v for v in d["videos"] if yt_id(v.get("youtube_url"))] + [{"title": b["name"], "youtube_url": b["video_url"], "bands": {"slug": b["slug"], "name": b["name"]}} for b in bands if yt_id(b.get("video_url"))]
    body = '<h1>Videos</h1><p class="lead">Live clips, music videos and footage from the bands on the label.</p><div class="grid">'
    for v in vids:
        i = yt_id(v["youtube_url"])
        body += f'<article class="card"><a href="{e(v["youtube_url"])}" rel="noopener"><img src="https://i.ytimg.com/vi/{i}/hqdefault.jpg" alt="{e(v["title"])}" loading="lazy" width="480" height="360"></a><h2>{e(v["title"])}</h2>' + (f'<p class="mono"><a href="/band/{e(v["bands"]["slug"])}/">{e(v["bands"]["name"])}</a></p>' if v.get("bands") else "") + "</article>"
    urls.append(page("videos/", "Videos: live clips and music videos", "Watch live clips, music videos and footage from Socks On Records bands.", body + "</div>", spa="#/videos"))

    # --- sessions
    body = '<h1>Socks On Sessions</h1><p class="lead">Part live video, part podcast. A band plays in the room, then gets interviewed.</p>'
    for s_ in d["sessions"]:
        who = (s_.get("bands") or {}).get("name") or s_.get("band_text") or ""
        body += f'<article class="card wide"><p class="mono">{e(fmt_date(s_.get("session_date") or ""))} {("· " + e(who)) if who else ""}</p><h2>{e(s_["title"])}</h2>' + (f'<p>{e(s_.get("summary"))}</p>' if s_.get("summary") else "")
        body += '<p class="btns">' + (f'<a class="btn sm" href="{e(s_["video_url"])}" rel="noopener">Watch</a>' if s_.get("video_url") else "") + (f'<a class="btn sm" href="{e(s_["audio_url"])}" rel="noopener">Listen</a>' if s_.get("audio_url") else "") + "</p></article>"
    if not d["sessions"]: body += "<p>The first sessions are being edited. Check back soon.</p>"
    urls.append(page("sessions/", "Socks On Sessions: live band videos and interviews", "Socks On Sessions is part live video, part podcast: a band plays in the room, then gets interviewed. Watch or listen.", body, spa="#/sessions"))

    # --- merch: the menu points at Big Cartel for now, so /merch/ simply forwards there
    d_ = os.path.join(ROOT, "merch"); os.makedirs(d_, exist_ok=True)
    open(os.path.join(d_, "index.html"), "w", encoding="utf-8").write(
        '<!doctype html><html lang="en-GB"><head><meta charset="utf-8"><title>Merch | Socks On Records</title>'
        '<meta name="robots" content="noindex"><link rel="canonical" href="https://socksonrecords.bigcartel.com/">'
        '<meta http-equiv="refresh" content="0; url=https://socksonrecords.bigcartel.com/"></head>'
        '<body><p><a href="https://socksonrecords.bigcartel.com/">Socks On Records merch on Big Cartel</a></p></body></html>')

    # --- contact
    urls.append(page("contact/", "Contact", "Get in touch with Socks On Records: gigs, releases, press and bands. Email socksonrecords@gmail.com or message us on Instagram.",
        '<h1>Contact</h1><p class="lead">Want to play, release something, or just say hello?</p><p><a class="btn" href="mailto:socksonrecords@gmail.com">socksonrecords@gmail.com</a></p>'
        '<p>Instagram: <a href="https://www.instagram.com/socks_on_records/">@socks_on_records</a> (label) and <a href="https://www.instagram.com/socksongraphics/">@socksongraphics</a> (graphics).</p>', spa="#/contact"))

    # --- 404
    page404 = page("_404/", "Page not found", "This page doesn't exist. Head back to the Socks On Records home page.", '<h1>Not found</h1><p class="lead">That page has gone missing. Try the <a href="/roster/">roster</a>, <a href="/gigs/">gigs</a> or <a href="/">home page</a>.</p>', noindex=True)
    src = os.path.join(ROOT, "_404", "index.html"); os.replace(src, os.path.join(ROOT, "404.html")); os.rmdir(os.path.join(ROOT, "_404"))
    return urls

def write_sitemap(urls):
    allu = [SITE + "/"] + urls
    x = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + "".join(f"<url><loc>{e(u)}</loc></url>\n" for u in allu) + "</urlset>\n"
    open(os.path.join(ROOT, "sitemap.xml"), "w", encoding="utf-8").write(x)
    open(os.path.join(ROOT, "robots.txt"), "w").write(f"User-agent: *\nAllow: /\nDisallow: /admin.html\n\nSitemap: {SITE}/sitemap.xml\n")

if __name__ == "__main__":
    data = load()
    u = build(data)
    write_sitemap(u)
    print("wrote", len(u), "pages + sitemap.xml + robots.txt")
