#!/usr/bin/env bash
# Scaffolds the Android platform folder around the committed lib/ + pubspec.yaml
# and applies GroupRide's manifest (permissions + Google Maps key slot).
#
# Safe to run locally or in CI. It never clobbers lib/ or pubspec.yaml.
set -euo pipefail

echo "==> Backing up sources"
cp pubspec.yaml /tmp/gr_pubspec.yaml.bak
rm -rf /tmp/gr_lib.bak && cp -r lib /tmp/gr_lib.bak

echo "==> Scaffolding Android platform files (flutter create)"
flutter create --platforms=android --org com.grouprde --project-name grouprde .

echo "==> Restoring committed sources"
cp /tmp/gr_pubspec.yaml.bak pubspec.yaml
rm -rf lib && cp -r /tmp/gr_lib.bak lib

echo "==> Applying GroupRide AndroidManifest"
cp android_overrides/AndroidManifest.xml android/app/src/main/AndroidManifest.xml

echo "==> Ensuring minSdk >= 23 (google_maps_flutter / geolocator)"
if [ -f android/app/build.gradle.kts ]; then
  sed -i 's/minSdk = flutter.minSdkVersion/minSdk = 23/' android/app/build.gradle.kts || true
  sed -i 's/minSdkVersion = flutter.minSdkVersion/minSdk = 23/' android/app/build.gradle.kts || true
fi
if [ -f android/app/build.gradle ]; then
  sed -i 's/minSdkVersion flutter.minSdkVersion/minSdkVersion 23/' android/app/build.gradle || true
fi

echo "==> Optional: inject Google Maps key from env MAPS_API_KEY"
if [ "${MAPS_API_KEY:-}" != "" ]; then
  sed -i "s/YOUR_GOOGLE_MAPS_API_KEY/${MAPS_API_KEY}/" android/app/src/main/AndroidManifest.xml
  echo "    injected."
else
  echo "    none provided; map tiles will render grey (all else works)."
fi

echo "==> flutter pub get"
flutter pub get
echo "==> Done. You can now run: flutter build apk --release"
