/// Central configuration + backend-mode detection for GroupRide.
///
/// The app ships in LOCAL mode (fully functional, on-device persistence and a
/// simulated riding group so live tracking is demoable). Dropping in a real
/// Firebase config + Google Maps key flips it toward "live" with no code
/// changes beyond what SETUP.md describes.
class AppConfig {
  AppConfig._();

  /// App display name.
  static const String appName = 'GroupRide';
  static const String tagline = 'Plan together. Ride together. Stay together.';

  /// ---- Google Maps ----
  /// The real key lives in android/app/src/main/AndroidManifest.xml.
  /// Until you add a real key, map tiles render grey but every other feature
  /// (markers, routes, drawing) works. This flag only drives in-app hints.
  static const String mapsKeyPlaceholder = 'YOUR_GOOGLE_MAPS_API_KEY';

  /// ---- Backend mode ----
  /// LOCAL: no network backend. Data is stored on-device; other riders in a
  /// ride are simulated so you can see the live-tracking experience solo.
  ///
  /// FIREBASE: activated once you follow SETUP.md (add firebase deps +
  /// google-services.json and set [backend] to BackendMode.firebase).
  static const BackendMode backend = BackendMode.firebase;

  static bool get isLocal => backend == BackendMode.local;
  static bool get isFirebase => backend == BackendMode.firebase;

  /// When true, the app simulates a small group of nearby riders during a ride
  /// so a single user can experience live tracking, separation alerts, etc.
  static const bool simulateRidersInLocalMode = true;
}

enum BackendMode { local, firebase }
