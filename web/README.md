# Posture Trainer Web

A browser-based version of the Posture Trainer app that avoids iOS certificate renewal and App Store publishing.

This version is also set up as a Progressive Web App (PWA), so it can be installed to your phone/computer from the browser.

## Run

Open `web/index.html` directly in your browser, or serve this folder with any static server.

Example:

```bash
cd web
python3 -m http.server 8080
```

Then open http://localhost:8080.

## Install As App (PWA)

- In Safari (iPhone/iPad): Share -> Add to Home Screen.
- In Chromium browsers (Chrome/Edge): click the `Install App` button in the top bar.
- The app uses `manifest.webmanifest` and `service-worker.js` for installability and offline shell caching.

## Feature Parity

- Program start/reset and current-week tracking
- Customizable schedule weeks (add/edit/reorder/delete)
- Session timer with live progress and quick completion
- Manual session logging with date and notes
- History editing and deletion
- Streak and weekly progress calculations
- Daily micro-check checklist
- Local persistence with `localStorage`
- Browser notification support for daily and micro-check reminders
- PWA install flow and offline shell support

## Browser Note

Background reminders depend on browser support:

- Foreground fallback: reminders always work while the app tab is open.
- Background-capable path: if the browser supports service-worker sync APIs, reminders can be checked in the background at browser-defined intervals.
- Exact minute-perfect background delivery is not guaranteed by browsers the way native iOS scheduling is.
