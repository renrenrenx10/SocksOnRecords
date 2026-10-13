/* Socks On Records: private page-view counter. No cookies, no IP address stored. Shown to admins in Admin > Traffic. */
(function () {
  var ENDPOINT = 'https://xnbkdgmojfupjerqorcw.supabase.co/rest/v1/page_views';
  var KEY = 'sb_publishable__XrZLQTrqwf9xeLBn5xI7w_vVgFJzCf';
  try {
    if (!/^(www\.)?socksonrecords\.uk$/i.test(location.hostname)) return;                 // only the real site
    if (navigator.doNotTrack === '1' || window.doNotTrack === '1') return;                // respect Do Not Track
    if (navigator.webdriver || /bot|crawl|spider|slurp|preview|headless|lighthouse|facebookexternalhit|whatsapp|telegram|discord/i.test(navigator.userAgent)) return;
    if (localStorage.getItem('sor_no_track')) return;                                      // set from Admin > Traffic
  } catch (e) { /* storage blocked: carry on */ }

  var sid = null;
  try {
    sid = sessionStorage.getItem('sor_s');
    if (!sid) {
      var a = new Uint8Array(9); crypto.getRandomValues(a);
      sid = Array.prototype.map.call(a, function (b) { return ('0' + b.toString(16)).slice(-2); }).join('');
      sessionStorage.setItem('sor_s', sid);
    }
  } catch (e) { /* no session code: each view then counts as its own visitor */ }

  var w = window.innerWidth || 1024, device = w < 700 ? 'mobile' : w < 1100 ? 'tablet' : 'desktop';

  function ref() {
    try {
      var q = new URLSearchParams(location.search), u = q.get('utm_source') || q.get('ref');
      if (u) return String(u).toLowerCase().slice(0, 60);
      if (!document.referrer) return null;
      var h = new URL(document.referrer).hostname.replace(/^www\./, '').toLowerCase();
      return (h && !/(^|\.)socksonrecords\.uk$/.test(h)) ? h.slice(0, 60) : null;
    } catch (e) { return null; }
  }

  // one clean path for both the static pages (/band/x/) and the app (#/band/x)
  function path() {
    var p = location.pathname.replace(/index\.html$/, ''), h = location.hash;
    if (p === '/' && /^#\/./.test(h)) p = '/' + h.slice(2).split('?')[0].replace(/\/+$/, '') + '/';
    if (p === '/home/') p = '/';
    return (p || '/').toLowerCase().slice(0, 120);
  }

  var last = null, first = true;
  function send() {
    var p = path();
    if (p === last) return;
    last = p;
    var body = JSON.stringify({ path: p, ref: first ? ref() : null, session_id: sid, device: device });
    first = false;
    try {
      fetch(ENDPOINT, { method: 'POST', keepalive: true, headers: { apikey: KEY, 'Content-Type': 'application/json', Prefer: 'return=minimal' }, body: body }).catch(function () {});
    } catch (e) {}
  }
  send();
  window.addEventListener('hashchange', send);
})();
