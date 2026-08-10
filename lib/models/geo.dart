import 'dart:math' as math;

/// A lightweight lat/lng point, decoupled from the maps plugin so models stay
/// platform-agnostic and serializable.
class GeoPoint {
  final double lat;
  final double lng;

  const GeoPoint(this.lat, this.lng);

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};

  factory GeoPoint.fromJson(Map<String, dynamic> j) =>
      GeoPoint((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble());

  /// Great-circle distance in kilometres (Haversine).
  double distanceKm(GeoPoint other) {
    const r = 6371.0;
    final dLat = _rad(other.lat - lat);
    final dLng = _rad(other.lng - lng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat)) *
            math.cos(_rad(other.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Initial bearing to [other] in degrees (0-360).
  double bearingTo(GeoPoint other) {
    final dLng = _rad(other.lng - lng);
    final y = math.sin(dLng) * math.cos(_rad(other.lat));
    final x = math.cos(_rad(lat)) * math.sin(_rad(other.lat)) -
        math.sin(_rad(lat)) * math.cos(_rad(other.lat)) * math.cos(dLng);
    final brng = math.atan2(y, x) * 180 / math.pi;
    return (brng + 360) % 360;
  }

  /// Point [distanceKm] away along [bearingDeg] — used to simulate movement.
  GeoPoint offset(double distanceKm, double bearingDeg) {
    const r = 6371.0;
    final d = distanceKm / r;
    final brng = _rad(bearingDeg);
    final lat1 = _rad(lat);
    final lng1 = _rad(lng);
    final lat2 = math.asin(math.sin(lat1) * math.cos(d) +
        math.cos(lat1) * math.sin(d) * math.cos(brng));
    final lng2 = lng1 +
        math.atan2(math.sin(brng) * math.sin(d) * math.cos(lat1),
            math.cos(d) - math.sin(lat1) * math.sin(lat2));
    return GeoPoint(lat2 * 180 / math.pi, lng2 * 180 / math.pi);
  }

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  String toString() =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}
