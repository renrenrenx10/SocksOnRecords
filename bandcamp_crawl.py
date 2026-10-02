#!/usr/bin/env python3
"""
Socks On Records: Bandcamp crawler.

Reads each band's Bandcamp page (from data/bands.csv), lists their releases,
opens every release page and collects: title, artist, date, cover image, about
text, credits, track list and the official embed player id. It writes CSV and
JSON files for you to look over, plus a SQL file to paste into Supabase.

NOTE: Bandcamp now shows plain scripts a "Client Challenge" bot check, so the
live crawl below may find nothing. The supported route is the browser-collected
file: python bandcamp_crawl.py --import-json data/crawl/browser_raw.jsonl
Needs Python 3.8+ and nothing else installed.

    python bandcamp_crawl.py                  # everything, politely (about 2 seconds between requests)
    python bandcamp_crawl.py --only rough-pup # just one band, to try it out
    python bandcamp_crawl.py --parse-file saved_page.html   # check the parser against a page you saved

Pages are cached in data/crawl/cache, so re-running does not hit Bandcamp again
unless you add --refresh.

The SQL it writes only FILLS BLANKS: it never overwrites a bio, link or photo
you have already edited in the admin screen.
"""
import argparse
import csv
import hashlib
import html
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime
from urllib.parse import parse_qs, unquote, urljoin, urlparse

UA = "Mozilla/5.0 (compatible; SocksOnRecordsSiteBuilder/1.0; +mailto:socksonrecords@gmail.com)"
HERE = os.path.dirname(os.path.abspath(__file__))


# ---------------------------------------------------------------- fetching
class Fetcher:
    def __init__(self, cache_dir, delay, refresh):
        self.cache_dir, self.delay, self.refresh = cache_dir, delay, refresh
        self.last = 0.0
        os.makedirs(cache_dir, exist_ok=True)

    def get(self, url):
        key = hashlib.sha1(url.encode()).hexdigest()[:16]
        path = os.path.join(self.cache_dir, key + ".html")
        if os.path.exists(path) and not self.refresh:
            with open(path, encoding="utf-8") as f:
                return f.read()
        wait = self.delay - (time.time() - self.last)
        if wait > 0:
            time.sleep(wait)
        last_err = None
        for attempt in range(3):
            try:
                req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "en-GB,en;q=0.9"})
                with urllib.request.urlopen(req, timeout=30) as r:
                    body = r.read().decode(r.headers.get_content_charset() or "utf-8", "replace")
                self.last = time.time()
                with open(path, "w", encoding="utf-8") as f:
                    f.write("<!-- " + url + " -->\n" + body)
                return body
            except urllib.error.HTTPError as e:
                last_err = e
                if e.code == 404:
                    break
                time.sleep(3 * (attempt + 1))
            except Exception as e:  # network blips
                last_err = e
                time.sleep(3 * (attempt + 1))
        raise RuntimeError("could not fetch %s (%s)" % (url, last_err))


# ----------------------------------------------------------------- parsing
def clean(s):
    return html.unescape(re.sub(r"[ \t]+\n", "\n", s or "")).strip()


def text_of(fragment):
    fragment = re.sub(r"<br\s*/?>", "\n", fragment or "", flags=re.I)
    fragment = re.sub(r"</p>", "\n\n", fragment, flags=re.I)
    return clean(re.sub(r"<[^>]+>", "", fragment))


def attr_json(doc, attr):
    """Bandcamp keeps lots of page data as JSON inside a data-xxx="..." attribute."""
    m = re.search(r"\b%s=(\"|')(.*?)\1" % re.escape(attr), doc, re.S)
    if not m:
        return None
    try:
        return json.loads(html.unescape(m.group(2)))
    except ValueError:
        return None


def meta(doc, prop):
    for pat in (
        r'<meta[^>]+(?:property|name)=["\']%s["\'][^>]*content=["\']([^"\']*)["\']',
        r'<meta[^>]+content=["\']([^"\']*)["\'][^>]*(?:property|name)=["\']%s["\']',
    ):
        m = re.search(pat % re.escape(prop), doc, re.I)
        if m:
            return clean(m.group(1))
    return None


def platform_of(url):
    host = urlparse(url).netloc.lower()
    for key, name in (
        ("instagram.com", "instagram_url"), ("facebook.com", "facebook_url"), ("fb.com", "facebook_url"),
        ("spotify.com", "spotify_url"), ("youtube.com", "youtube_url"), ("youtu.be", "youtube_url"),
    ):
        if key in host:
            return name
    if any(k in host for k in ("twitter.com", "x.com", "tiktok.com", "threads.net", "bsky.app", "mastodon")):
        return None  # not stored: the site has no field for these
    return "website_url" if "bandcamp.com" not in host else None


def parse_band_page(doc, base):
    """Band-level info from the artist's /music page."""
    out = {"name": None, "location": None, "bio": None, "image_url": None,
           "instagram_url": None, "facebook_url": None, "spotify_url": None, "youtube_url": None, "website_url": None}
    out["name"] = meta(doc, "og:site_name") or meta(doc, "og:title")
    m = re.search(r'<p[^>]*id="bio-text"[^>]*>(.*?)</p>', doc, re.S)
    if m:
        out["bio"] = text_of(m.group(1)) or None
    m = re.search(r'class="location[^"]*"[^>]*>(.*?)</span>', doc, re.S)
    if m:
        out["location"] = text_of(m.group(1)) or None
    # full-size photo: the link wrapped around the band photo, else the thumbnail itself
    m = re.search(r'<a[^>]+class="popupImage"[^>]+href="([^"]+)"[^>]*>\s*<img[^>]+class="band-photo"', doc, re.S)
    if m:
        out["image_url"] = m.group(1)
    else:
        m = re.search(r'<img[^>]*class="[^"]*band-photo[^"]*"[^>]*>', doc)
        if m:
            s = re.search(r'(?:data-original|src)="([^"]+)"', m.group(0))
            out["image_url"] = s.group(1) if s else None
    out["image_url"] = out["image_url"] or meta(doc, "og:image")
    m = re.search(r'<(?:ul|ol)[^>]*id="band-links"[^>]*>(.*?)</(?:ul|ol)>', doc, re.S)
    if m:
        for href in re.findall(r'href="([^"]+)"', m.group(1)):
            href = html.unescape(href)
            if "external_link_exit" in href:
                href = parse_qs(urlparse(href).query).get("url", [href])[0]
            href = unquote(href)
            href = re.sub(r"^https?://(m|mobile)\.facebook\.com", "https://www.facebook.com", href)
            key = platform_of(href)
            if key and not out[key]:
                out[key] = href
    return out


def parse_music_grid(doc, base):
    """List of {title, url, type, artist} for every release on the /music page."""
    items = []
    seen = set()

    def add(url, title, kind, artist):
        url = urljoin(base, url.split("#")[0].split("?")[0])
        if url in seen or not re.search(r"/(album|track)/", url):
            return
        seen.add(url)
        items.append({"title": title, "url": url, "type": kind or ("track" if "/track/" in url else "album"), "artist": artist})

    data = attr_json(doc, "data-client-items")
    if isinstance(data, list):
        for it in data:
            if it.get("page_url"):
                add(it["page_url"], it.get("title"), it.get("type"), it.get("artist"))
    # plain HTML grid (also a fallback if the JSON changes shape)
    for m in re.finditer(r'<li[^>]*class="[^"]*music-grid-item[^"]*"[^>]*>(.*?)</li>', doc, re.S):
        block = m.group(1)
        h = re.search(r'href="([^"]+)"', block)
        t = re.search(r'<p class="title">(.*?)</p>', block, re.S)
        a = re.search(r'class="artist-override"[^>]*>(.*?)</', block, re.S)
        if h:
            add(html.unescape(h.group(1)), text_of(t.group(1)).split("\n")[0] if t else None, None, text_of(a.group(1)) if a else None)
    if not items:
        for href in re.findall(r'href="(/(?:album|track)/[^"#?]+)"', doc):
            add(href, None, None, None)
    return items


def parse_date(s):
    if not s:
        return None
    for fmt in ("%d %b %Y %H:%M:%S GMT", "%d %b %Y", "%Y-%m-%d", "%B %d, %Y"):
        try:
            return datetime.strptime(s.strip(), fmt).date()
        except ValueError:
            pass
    return None


def parse_release_page(doc, url):
    tr = attr_json(doc, "data-tralbum") or {}
    cur = tr.get("current") or {}
    title = cur.get("title") or (meta(doc, "og:title") or "").split(", by ")[0] or None
    artist = tr.get("artist") or cur.get("artist")
    if not artist:
        m = re.search(r", by (.+)$", meta(doc, "og:title") or "")
        artist = m.group(1) if m else None
    kind = tr.get("item_type") or cur.get("type") or ("track" if "/track/" in url else "album")
    item_id = cur.get("id") or tr.get("id")
    # official embed player id: prefer the page's own og:video tag
    ov = meta(doc, "og:video") or ""
    m = re.search(r"(album|track)=(\d+)", ov)
    if m:
        embed = "https://bandcamp.com/EmbeddedPlayer/%s=%s/" % (m.group(1), m.group(2))
    elif item_id:
        embed = "https://bandcamp.com/EmbeddedPlayer/%s=%s/" % (kind if kind in ("album", "track") else "album", item_id)
    else:
        embed = None
    art_id = tr.get("art_id") or cur.get("art_id")
    cover = ("https://f4.bcbits.com/img/a%s_5.jpg" % art_id) if art_id else meta(doc, "og:image")
    rd = parse_date(cur.get("release_date")) or parse_date(cur.get("publish_date"))
    tracks = []
    for t in tr.get("trackinfo") or []:
        dur = t.get("duration")
        tracks.append({"n": t.get("track_num"), "title": t.get("title"), "seconds": round(dur) if isinstance(dur, (int, float)) else None})
    return {
        "title": title, "artist": artist, "type": kind, "url": url,
        "released_date": rd.isoformat() if rd else None,
        "released_text": rd.strftime("%d %B %Y").lstrip("0") if rd else None,
        "cover_url": cover, "embed_url": embed,
        "about": (cur.get("about") or "").replace("\r\n", "\n").strip() or None,
        "credits": (cur.get("credits") or "").replace("\r\n", "\n").strip() or None,
        "tracks": tracks,
    }


# --------------------------------------------------------------------- SQL
def q(v):
    return "null" if v is None else "'" + str(v).replace("'", "''") + "'"


def write_sql(path, bands, releases):
    L = ["-- Generated by bandcamp_crawl.py. Run in Supabase SQL Editor AFTER 03-featured-and-crawl.sql.",
         "-- Fills blanks only: nothing you have already edited is overwritten.", ""]
    for b in bands:
        L.append(
            "update public.bands set bio=coalesce(nullif(bio,''),%s), location=coalesce(nullif(location,''),%s), "
            "instagram_url=coalesce(instagram_url,%s), facebook_url=coalesce(facebook_url,%s), spotify_url=coalesce(spotify_url,%s), "
            "youtube_url=coalesce(youtube_url,%s), website_url=coalesce(website_url,%s), "
            "bandcamp_image_url=coalesce(bandcamp_image_url,%s) where slug=%s;" % (
                q(b["bio"]), q(b["location"]), q(b["instagram_url"]), q(b["facebook_url"]), q(b["spotify_url"]),
                q(b["youtube_url"]), q(b["website_url"]), q(b["image_url"]), q(b["slug"])))
    L.append("")
    for r in releases:
        match = "(bandcamp_url=%s or (lower(title)=lower(%s) and lower(coalesce(artist_text,''))=lower(%s)) or (lower(title)=lower(%s) and artist_text='[artist unknown]'))" % (q(r["url"]), q(r["title"]), q(r["artist"]), q(r["title"]))
        tracks = json.dumps(r["tracks"], ensure_ascii=False) if r["tracks"] else None
        L.append("insert into public.releases (title,artist_text,type,released_text,released_date,bandcamp_url,cover_url,embed_url,description,tracks) "
                 "select %s,%s,%s,%s,%s::date,%s,%s,%s,%s,%s::jsonb where not exists (select 1 from public.releases where %s);" % (
                     q(r["title"]), q(r["artist"]), q((r["type"] or "").capitalize() or None), q(r["released_text"]), q(r["released_date"]),
                     q(r["url"]), q(r["cover_url"]), q(r["embed_url"]), q(r["about"]), q(tracks), match))
        L.append("update public.releases set "
                 "artist_text=case when artist_text='[artist unknown]' then %s else artist_text end, "
                 "bandcamp_url=case when bandcamp_url is null or bandcamp_url like '%%/music' then %s else bandcamp_url end, "
                 "cover_url=coalesce(cover_url,%s), embed_url=coalesce(embed_url,%s), description=coalesce(description,%s), "
                 "tracks=coalesce(tracks,%s::jsonb), released_date=coalesce(released_date,%s::date), released_text=coalesce(released_text,%s) "
                 "where %s;" % (q(r["artist"]), q(r["url"]), q(r["cover_url"]), q(r["embed_url"]), q(r["about"]), q(tracks),
                                q(r["released_date"]), q(r["released_text"]), match))
        rmatch = "(r.bandcamp_url=%s or (lower(r.title)=lower(%s) and lower(coalesce(r.artist_text,''))=lower(%s)) or (lower(r.title)=lower(%s) and r.artist_text='[artist unknown]'))" % (q(r["url"]), q(r["title"]), q(r["artist"]), q(r["title"]))
        for slug in r["band_slugs"]:
            L.append("insert into public.release_bands (release_id, band_id) select r.id, b.id from public.releases r, public.bands b "
                     "where %s and b.slug=%s on conflict do nothing;" % (rmatch, q(slug)))
        L.append("")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(L))


# ------------------------------------------------------- browser import
def _untok(s):
    if s is None:
        return None
    return str(s).replace("[eq]", "=").replace("[amp]", "&").replace("[q]", "?")


_MONTHS = ["january", "february", "march", "april", "may", "june", "july", "august",
           "september", "october", "november", "december"]


def _date(s):
    """'2025-06-01' or '28 Aug 2026' -> (iso, '28 August 2026')."""
    s = (s or "").strip()
    m = re.match(r"^(\d{4})-(\d{2})-(\d{2})", s)
    if m:
        y, mo, d = int(m.group(1)), int(m.group(2)), int(m.group(3))
    else:
        m = re.match(r"^(\d{1,2}) ([A-Za-z]{3,9}) (\d{4})", s)
        if not m:
            return None, None
        d, y = int(m.group(1)), int(m.group(3))
        mo = [x[:3] for x in _MONTHS].index(m.group(2)[:3].lower()) + 1
    return "%04d-%02d-%02d" % (y, mo, d), "%d %s %d" % (d, _MONTHS[mo - 1].capitalize(), y)


def _clean_bio(s):
    s = re.sub(r"\s+", " ", _untok(s) or "").strip()
    if not s or "... more" in s or s.endswith("..."):
        return None  # Bandcamp truncated it: leave the bio for the band to supply
    return s


def _clean_insta(u):
    if not u:
        return None
    u = u.split("?")[0].replace("/profilecard/", "/").replace("http://", "https://")
    return u.rstrip("/") + "/" if "instagram.com/" in u else u


def import_browser_json(path, bands_csv, out_dir, sql_path):
    """Turn data/crawl/browser_raw.jsonl (collected through a real browser) into CSVs + SQL."""
    name_to_slug = {b["name"].strip().lower(): b["slug"] for b in read_bands(bands_csv)}
    band_rows, merged = [], {}
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if not line:
            continue
        rec = json.loads(line)
        slug, origin, d = rec["slug"], rec["origin"], rec["d"]
        b = d["b"]
        img = _untok(b.get("image_url"))
        if img and re.search(r"/img/a\d+_", img):
            img = None  # that is album art, not a band photo
        band_rows.append({
            "slug": slug, "name": _untok(b.get("name")), "location": _untok(b.get("location")),
            "bio": _clean_bio(b.get("bio")), "image_url": img,
            "instagram_url": _clean_insta(_untok(b.get("instagram_url"))),
            "facebook_url": _untok(b.get("facebook_url")), "spotify_url": _untok(b.get("spotify_url")),
            "youtube_url": _untok(b.get("youtube_url")), "website_url": _untok(b.get("website_url"))})
        bname = _untok(b.get("name"))
        for r in d["r"]:
            r = list(r) + [None] * (8 - len(r))
            title, artist, kind, href, dt, rid, art, about = r[:8]
            title = _untok(title)
            if not title or kind not in ("a", "t") or not rid:
                continue
            iso, text = _date(dt)
            artist = _untok(artist) or bname
            url = href if href.startswith("http") else origin + href
            key = (title.strip().lower(), iso)
            slugs = [slug]
            for nm in re.split(r"\s*(?:/|&| x | and )\s*", artist):
                s2 = name_to_slug.get(nm.strip().lower())
                if s2 and s2 not in slugs:
                    slugs.append(s2)
            if key in merged:  # same release listed on two bands' pages (a split)
                m = merged[key]
                for s2 in slugs:
                    if s2 not in m["band_slugs"]:
                        m["band_slugs"].append(s2)
                if artist.lower() not in m["artist"].lower():
                    m["artist"] += " / " + artist
                continue
            artid = str(art or "")
            cover = ("https://f4.bcbits.com/img/a%s_5.jpg" % artid[1:].zfill(10)) if artid.startswith("a") else None
            merged[key] = {
                "title": title, "artist": artist, "type": "Album" if kind == "a" else "Track",
                "released_text": text, "released_date": iso, "url": url, "cover_url": cover,
                "embed_url": "https://bandcamp.com/EmbeddedPlayer/%s=%s/" % ("album" if kind == "a" else "track", rid),
                "about": (_untok(about) or "").strip() or None, "tracks": None, "band_slugs": slugs}
    releases = sorted(merged.values(), key=lambda x: (x["band_slugs"][0], x["released_date"] or ""), reverse=False)
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "bands.csv"), "w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(band_rows[0].keys()))
        w.writeheader(); w.writerows(band_rows)
    with open(os.path.join(out_dir, "releases.csv"), "w", encoding="utf-8-sig", newline="") as f:
        cols = ["title", "artist", "band_slugs", "type", "released_text", "released_date", "url", "cover_url", "embed_url", "about"]
        w = csv.DictWriter(f, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for r in releases:
            w.writerow(dict(r, band_slugs=",".join(r["band_slugs"])))
    write_sql(sql_path, band_rows, releases)
    print("Imported %d bands and %d releases (same title+date on two bands = one release)." % (
        len(band_rows), len(releases)))
    print("  CSVs:", out_dir)
    print("  SQL :", sql_path)


# -------------------------------------------------------------------- main
def read_bands(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
        return [r for r in csv.DictReader(f) if (r.get("bandcamp_url") or "").strip()]


def parse_file(path):
    doc = open(path, encoding="utf-8", errors="replace").read()
    print("file:", path, "(%d bytes)" % len(doc))
    tr = attr_json(doc, "data-tralbum")
    if isinstance(tr, dict) and (tr.get("current") or tr.get("trackinfo")):
        print("looks like a RELEASE page:")
        print(json.dumps(parse_release_page(doc, "https://example.bandcamp.com/album/x"), indent=2, ensure_ascii=False))
    else:
        print("looks like an ARTIST page:")
        print(json.dumps(parse_band_page(doc, "https://example.bandcamp.com/"), indent=2, ensure_ascii=False))
        grid = parse_music_grid(doc, "https://example.bandcamp.com/")
        print("releases found in the grid: %d" % len(grid))
        for g in grid:
            print("  -", g["title"], g["url"])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--bands-csv", default=os.path.join(HERE, "data", "bands.csv"))
    ap.add_argument("--out", default=os.path.join(HERE, "data", "crawl"))
    ap.add_argument("--sql", default=os.path.join(HERE, "supabase", "04-crawl-import.sql"))
    ap.add_argument("--only", help="a single band slug")
    ap.add_argument("--delay", type=float, default=2.0, help="seconds between requests (default 2)")
    ap.add_argument("--refresh", action="store_true", help="ignore the cache and fetch again")
    ap.add_argument("--label", action="store_true", help="also crawl the label page https://socksonrecords.bandcamp.com")
    ap.add_argument("--import-json", help="import releases collected through a real browser (data/crawl/browser_raw.jsonl)")
    ap.add_argument("--parse-file", help="parse a saved Bandcamp HTML file and print what was found, then stop")
    a = ap.parse_args()

    if a.parse_file:
        return parse_file(a.parse_file)
    if a.import_json:
        return import_browser_json(a.import_json, a.bands_csv, a.out, a.sql)

    bands = read_bands(a.bands_csv)
    if a.only:
        bands = [b for b in bands if b["slug"] == a.only]
    if not bands:
        sys.exit("No bands to crawl. Check --bands-csv / --only.")
    os.makedirs(a.out, exist_ok=True)
    fx = Fetcher(os.path.join(a.out, "cache"), a.delay, a.refresh)

    band_rows, releases, problems = [], {}, []
    targets = [(b["slug"], b["name"], b["bandcamp_url"]) for b in bands]
    if a.label:
        targets.append((None, "Socks On Records", "https://socksonrecords.bandcamp.com/"))
    name_to_slug = {b["name"].strip().lower(): b["slug"] for b in read_bands(a.bands_csv)}

    for slug, name, url in targets:
        p = urlparse(url)
        base = "%s://%s" % (p.scheme, p.netloc)
        print("\n== %s  (%s)" % (name, base))
        try:
            doc = fx.get(base + "/music")
        except Exception as e:
            problems.append((name, str(e)))
            print("   !!", e)
            continue
        info = parse_band_page(doc, base)
        if slug:
            info["slug"] = slug
            band_rows.append(info)
        grid = parse_music_grid(doc, base)
        if not grid and ("/album/" in url or "/track/" in url):
            grid = [{"title": None, "url": url.split("#")[0], "type": None, "artist": None}]
        print("   %d release(s) listed" % len(grid))
        for g in grid:
            try:
                rdoc = fx.get(g["url"])
                r = parse_release_page(rdoc, g["url"])
            except Exception as e:
                problems.append((g["url"], str(e)))
                print("   !!", e)
                continue
            r["title"] = r["title"] or g["title"]
            r["artist"] = r["artist"] or g["artist"]
            if not r["title"]:
                problems.append((g["url"], "no title found"))
                continue
            existing = releases.setdefault(r["url"], dict(r, band_slugs=[]))
            slugs = [slug] if slug else []
            if not slugs and r["artist"]:
                slugs = [name_to_slug[x.strip().lower()] for x in re.split(r",|&| and | x |;", r["artist"]) if x.strip().lower() in name_to_slug]
            for s in slugs:
                if s not in existing["band_slugs"]:
                    existing["band_slugs"].append(s)
            print("   - %-40s %s  %s" % ((r["title"] or "")[:40], r["released_date"] or "no date", "embed ok" if r["embed_url"] else "NO EMBED"))

    rel_list = sorted(releases.values(), key=lambda r: r["released_date"] or "", reverse=True)

    with open(os.path.join(a.out, "bands_crawled.csv"), "w", encoding="utf-8-sig", newline="") as f:
        cols = ["slug", "name", "location", "bio", "image_url", "instagram_url", "facebook_url", "spotify_url", "youtube_url", "website_url"]
        w = csv.DictWriter(f, cols, extrasaction="ignore")
        w.writeheader()
        w.writerows(band_rows)
    with open(os.path.join(a.out, "releases_crawled.csv"), "w", encoding="utf-8-sig", newline="") as f:
        cols = ["title", "artist", "band_slugs", "type", "released_date", "released_text", "url", "cover_url", "embed_url", "about"]
        w = csv.writer(f)
        w.writerow(cols)
        for r in rel_list:
            w.writerow([r["title"], r["artist"], ";".join(r["band_slugs"]), r["type"], r["released_date"], r["released_text"],
                        r["url"], r["cover_url"], r["embed_url"], r["about"]])
    with open(os.path.join(a.out, "crawl.json"), "w", encoding="utf-8") as f:
        json.dump({"bands": band_rows, "releases": rel_list, "problems": problems}, f, indent=2, ensure_ascii=False)
    os.makedirs(os.path.dirname(os.path.abspath(a.sql)), exist_ok=True)
    write_sql(a.sql, band_rows, rel_list)

    print("\nDone. %d bands, %d releases, %d problem(s)." % (len(band_rows), len(rel_list), len(problems)))
    for what, why in problems:
        print("  problem:", what, "-", why)
    print("Look over:  %s" % a.out)
    print("Then paste into Supabase:  %s" % a.sql)


if __name__ == "__main__":
    main()
