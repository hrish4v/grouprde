import 'package:geolocator/geolocator.dart';

import '../models/geo.dart';

/// Thin wrapper over geolocator with graceful fallbacks so the app never
/// hard-fails when GPS/permissions are unavailable (e.g. on an emulator).
class LocationService {
  /// Default fallback location (central Bengaluru) used when a real fix isn't
  /// available. Keeps maps and simulation working everywhere.
  static const GeoPoint fallback = GeoPoint(12.9716, 77.5946);

  bool _permissionOk = false;
  bool get permissionGranted => _permissionOk;

  /// Requests permission and returns true if usable.
  Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _permissionOk = false;
        return false;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      _permissionOk = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      return _permissionOk;
    } catch (_) {
      _permissionOk = false;
      return false;
    }
  }

  /// Best-effort current location. Falls back to [fallback] on any failure.
  Future<GeoPoint> current() async {
    try {
      if (!_permissionOk) {
        final ok = await ensurePermission();
        if (!ok) return fallback;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return GeoPoint(pos.latitude, pos.longitude);
    } catch (_) {
      return fallback;
    }
  }

  /// Live position stream. Returns null if unavailable so callers can fall back
  /// to simulated movement.
  Stream<Position>? positionStream() {
    if (!_permissionOk) return null;
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
