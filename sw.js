// SiteRunner Live — Service Worker v2
// Network first — always gets fresh updates
// Falls back to cache only if offline

const CACHE = "taver-scheduler-v3";
const OFFLINE_ASSETS = ["/", "/index.html", "/staff.html", "/docket.html", "/timesheet.html", "/manifest.json"];

// Install — cache essential files
self.addEventListener("install", e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll(OFFLINE_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// Activate — delete old caches immediately
self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Fetch — network first, cache fallback
self.addEventListener("fetch", e => {
  // Only handle same-origin requests
  if (!e.request.url.startsWith(self.location.origin)) return;
  // Skip non-GET
  if (e.request.method !== "GET") return;

  e.respondWith(
    fetch(e.request)
      .then(res => {
        // Got a fresh response — update cache and return it
        if (res && res.status === 200) {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return res;
      })
      .catch(() => {
        // Offline — serve from cache
        return caches.match(e.request)
          .then(cached => cached || caches.match("/index.html"));
      })
  );
});
