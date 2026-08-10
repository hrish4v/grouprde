# 🏍️ GroupRide

**Plan together. Ride together. Stay together.**

GroupRide is a Flutter app for motorcycle riders who travel in groups — trip
planning, group management, live rider tracking, in‑ride coordination, safety
alerts, and ride history, all in one place. This repository is the working
MVP built from the GroupRide product spec.

> **How it runs today:** the app ships in **LOCAL mode** — fully functional and
> offline, with data saved on your device and a small group of *simulated*
> riding buddies during a ride so you can experience live tracking, separation
> alerts and quick requests solo. Dropping in a Google Maps key makes the map
> tiles load; following `SETUP.md` swaps in Firebase so you and your friends
> ride together for real.

---

## ✅ What's implemented (MVP)

- **Rider profile** — name, bike, avatar, preferred speed, emergency contact, and cumulative stats (rides, km, destinations, badges).
- **Groups** — create communities, join by 6‑character code or QR, member lists, admin roles, invite sheet.
- **Ride planning** — pick start/destination (map tap or city presets), choose a route type (Fastest / Shortest / Scenic / Motorcycle‑friendly), and add typed **breakpoints** (⛽ fuel, 🍛 food, 📸 photo, 🏨 hotel, 🔧 service, 🏥 hospital…). Route + distance + ETA rendered on Google Maps.
- **Ride Mode (live)** — every rider on a shared map, a live **dashboard** (distance covered, elapsed, next stop, group health 🟢🟡🔴), **rider‑separation detection** (a buddy falls behind → amber alert), and leader/sweep roles.
- **Quick requests** — one‑tap 🛑 Break (with reason), ⛽ Fuel, 🍛 Food, 🔧 Bike issue, ✋ Stop, broadcast to everyone with a live feed.
- **Emergency mode** — 🚨 trigger with a category (accident / breakdown / medical / lost), shares your live location, and shows a red group‑wide banner.
- **Ride history** — automatic ride summary with route map, stats (avg/max speed, duration, riders, stops), a timeline, and “ride memories”.
- **Privacy** — live location exists only during an active ride and is discarded when the ride ends.

---

## 📱 Getting the APK (no local setup needed)

The fastest path — GitHub builds the APK for you:

1. Create a new GitHub repository and push this project to it (see below).
2. GitHub Actions runs automatically (`.github/workflows/build-apk.yml`).
3. Open the **Actions** tab → the latest run → download the **`grouprde-apk`** artifact.
4. Unzip it, copy `app-release.apk` to your Android phone, and install
   (enable “Install unknown apps” for your file manager/browser when prompted).

```bash
# from inside this project folder
git init && git add . && git commit -m "GroupRide MVP"
git branch -M main
git remote add origin https://github.com/<you>/grouprde.git
git push -u origin main
# ...then watch the Actions tab.
```

See **`SETUP.md`** for the click‑by‑click version, adding a Maps key, and going live with Firebase.

### Building locally instead (if you have Flutter installed)

```bash
bash tool/prepare_android.sh      # scaffolds android/ + applies the manifest
flutter build apk --release       # -> build/app/outputs/flutter-apk/app-release.apk
# or, to run on a connected device/emulator:
flutter run
```

---

## 🗂️ Project structure

```
lib/
  config/        app config (backend mode), theme
  models/        RiderProfile, RiderGroup, Ride, Breakpoint,
                 RiderLiveState, QuickRequest, RideHistory, enums, geo
  data/          Repository interface + LocalRepository + provider
  services/      LocationService, RideSession seed helpers
  state/         AppState (app-wide) + RideSession (live ride engine)
  screens/       auth · home · groups · rides · ride_mode · history · profile
  widgets/       shared UI + map helpers
android_overrides/AndroidManifest.xml   # permissions + Maps key slot
tool/prepare_android.sh                  # scaffolds android/ for building
.github/workflows/build-apk.yml          # CI: builds the APK artifact
docs/firebase_repository.dart.reference  # drop-in Firebase backend
SETUP.md                                 # keys + go-live guide
```

### Architecture note

All data flows through a single `Repository` interface. Today that's
`LocalRepository` (on‑device JSON). The same interface has a documented
Firebase implementation (`docs/…reference`) so going live is a matter of adding
the dependency, config, and flipping `AppConfig.backend` — no screen code
changes. Live positions in `RideSession` come from a route‑walking simulator in
local mode and from Firestore snapshots in Firebase mode.

---

## 🔑 Google Maps & 🔥 Firebase

Both need your own credentials — full walkthrough in **`SETUP.md`**. Short
version: add a Google Maps Android API key to `android_overrides/AndroidManifest.xml`
(or the `MAPS_API_KEY` GitHub secret) for map tiles; add a Firebase project +
`google-services.json` to ride live with friends.
