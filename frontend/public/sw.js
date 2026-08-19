// Minimal service worker: registering one is required for "Add to Home
// Screen" installability. No caching strategy yet (a later-phase concern);
// this just passes all requests straight through to the network.
self.addEventListener("install", () => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", () => {
  // Intentionally not calling event.respondWith(): let the browser handle
  // the request normally. Registering a fetch listener (even a no-op one)
  // is part of what makes the browser treat this as an installable PWA.
});
