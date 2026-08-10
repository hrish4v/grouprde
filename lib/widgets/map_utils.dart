import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/geo.dart';

/// Conversions between our platform-agnostic [GeoPoint] and the maps plugin's
/// [LatLng], plus small camera helpers.
extension GeoPointX on GeoPoint {
  LatLng get latLng => LatLng(lat, lng);
}

extension LatLngX on LatLng {
  GeoPoint get geo => GeoPoint(latitude, longitude);
}

List<LatLng> toLatLngs(List<GeoPoint> pts) =>
    pts.map((p) => p.latLng).toList();

/// Bounds that contain every point, with a small pad, for camera fitting.
LatLngBounds boundsOf(List<GeoPoint> pts) {
  double minLat = pts.first.lat, maxLat = pts.first.lat;
  double minLng = pts.first.lng, maxLng = pts.first.lng;
  for (final p in pts) {
    minLat = p.lat < minLat ? p.lat : minLat;
    maxLat = p.lat > maxLat ? p.lat : maxLat;
    minLng = p.lng < minLng ? p.lng : minLng;
    maxLng = p.lng > maxLng ? p.lng : maxLng;
  }
  const pad = 0.05;
  return LatLngBounds(
    southwest: LatLng(minLat - pad, minLng - pad),
    northeast: LatLng(maxLat + pad, maxLng + pad),
  );
}
