const CACHE_NAME = "posture-web-cache-v2";
const APP_SHELL = [
  "./",
  "./index.html",
  "./styles.css",
  "./app.js",
  "./manifest.webmanifest",
  "./icons/app-icon.svg",
];

const DB_NAME = "posture-web-db";
const DB_STORE = "settings";
const DB_KEY = "reminders";

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map((key) => {
      if (key !== CACHE_NAME) return caches.delete(key);
      return Promise.resolve();
    }));
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;

  event.respondWith((async () => {
    const sameOrigin = new URL(event.request.url).origin === self.location.origin;

    if (event.request.mode === "navigate") {
      try {
        const networkResponse = await fetch(event.request);
        const cache = await caches.open(CACHE_NAME);
        cache.put("./index.html", networkResponse.clone());
        return networkResponse;
      } catch {
        const fallback = await caches.match("./index.html");
        return fallback || Response.error();
      }
    }

    if (sameOrigin) {
      const cached = await caches.match(event.request);
      const fetchPromise = fetch(event.request)
        .then(async (networkResponse) => {
          const cache = await caches.open(CACHE_NAME);
          cache.put(event.request, networkResponse.clone());
          return networkResponse;
        })
        .catch(() => null);

      if (cached) {
        event.waitUntil(fetchPromise);
        return cached;
      }

      const networkResponse = await fetchPromise;
      if (networkResponse) return networkResponse;
    }

    return fetch(event.request);
  })());
});

self.addEventListener("message", (event) => {
  if (!event.data || event.data.type !== "UPDATE_REMINDER_SETTINGS") return;
  event.waitUntil(setReminderSettings(event.data.payload));
});

self.addEventListener("periodicsync", (event) => {
  if (event.tag !== "posture-reminders") return;
  event.waitUntil(checkAndNotify());
});

self.addEventListener("sync", (event) => {
  if (event.tag !== "posture-reminders-sync") return;
  event.waitUntil(checkAndNotify());
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil((async () => {
    const allClients = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
    if (allClients.length > 0) {
      await allClients[0].focus();
      return;
    }
    await self.clients.openWindow("./index.html");
  })());
});

async function checkAndNotify() {
  const settings = await getReminderSettings();
  if (!settings) return;

  const now = new Date();
  const minuteStamp = [
    now.getFullYear(),
    now.getMonth() + 1,
    now.getDate(),
    now.getHours(),
    now.getMinutes(),
  ].join("-");

  if (settings.lastSentStamp === minuteStamp) return;

  const shouldDaily = settings.remindersEnabled
    && now.getHours() === settings.reminderHour
    && now.getMinutes() === settings.reminderMinute;

  const shouldMicro = settings.microCheckRemindersEnabled
    && [10, 14, 17].includes(now.getHours())
    && now.getMinutes() === 0;

  if (!shouldDaily && !shouldMicro) return;

  if (shouldDaily) {
    await self.registration.showNotification("Posture Trainer", {
      body: "Time for your posture training session.",
      tag: "posture-daily-reminder",
    });
  }

  if (shouldMicro) {
    await self.registration.showNotification("Posture Check", {
      body: "Quick scan: feet, pelvis, ribcage, shoulders, chin.",
      tag: "posture-micro-reminder",
    });
  }

  await setReminderSettings({ ...settings, lastSentStamp: minuteStamp });
}

function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, 1);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(DB_STORE)) {
        db.createObjectStore(DB_STORE);
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function setReminderSettings(payload) {
  const db = await openDB();
  await new Promise((resolve, reject) => {
    const tx = db.transaction(DB_STORE, "readwrite");
    tx.objectStore(DB_STORE).put(payload, DB_KEY);
    tx.oncomplete = resolve;
    tx.onerror = () => reject(tx.error);
  });
  db.close();
}

async function getReminderSettings() {
  const db = await openDB();
  const value = await new Promise((resolve, reject) => {
    const tx = db.transaction(DB_STORE, "readonly");
    const req = tx.objectStore(DB_STORE).get(DB_KEY);
    req.onsuccess = () => resolve(req.result || null);
    req.onerror = () => reject(req.error);
  });
  db.close();
  return value;
}
