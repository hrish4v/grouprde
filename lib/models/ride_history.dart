import 'geo.dart';

/// A completed ride's saved summary. This is what survives after a ride ends
/// (live positions are discarded for privacy; only the aggregate remains).
class RideHistory {
  final String id;
  final String rideId;
  final String title;
  final String startName;
  final String destinationName;
  final double distanceKm;
  final int durationMin;
  final int riderCount;
  final int breakpointCount;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final List<GeoPoint> actualRoute;
  final List<String> timeline; // human-readable ride events
  final List<String> photoEmojis; // stand-in for ride memories
  final DateTime completedAt;

  RideHistory({
    required this.id,
    required this.rideId,
    required this.title,
    required this.startName,
    required this.destinationName,
    required this.distanceKm,
    required this.durationMin,
    required this.riderCount,
    required this.breakpointCount,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.actualRoute,
    required this.timeline,
    required this.photoEmojis,
    required this.completedAt,
  });

  String get durationLabel {
    final h = durationMin ~/ 60;
    final m = durationMin % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rideId': rideId,
        'title': title,
        'startName': startName,
        'destinationName': destinationName,
        'distanceKm': distanceKm,
        'durationMin': durationMin,
        'riderCount': riderCount,
        'breakpointCount': breakpointCount,
        'avgSpeedKmh': avgSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
        'actualRoute': actualRoute.map((e) => e.toJson()).toList(),
        'timeline': timeline,
        'photoEmojis': photoEmojis,
        'completedAt': completedAt.toIso8601String(),
      };

  factory RideHistory.fromJson(Map<String, dynamic> j) => RideHistory(
        id: j['id'] as String,
        rideId: j['rideId'] as String,
        title: j['title'] as String,
        startName: j['startName'] as String,
        destinationName: j['destinationName'] as String,
        distanceKm: (j['distanceKm'] as num).toDouble(),
        durationMin: (j['durationMin'] as num).toInt(),
        riderCount: (j['riderCount'] as num).toInt(),
        breakpointCount: (j['breakpointCount'] as num).toInt(),
        avgSpeedKmh: (j['avgSpeedKmh'] as num).toDouble(),
        maxSpeedKmh: (j['maxSpeedKmh'] as num).toDouble(),
        actualRoute: (j['actualRoute'] as List)
            .map((e) => GeoPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        timeline: (j['timeline'] as List).map((e) => e as String).toList(),
        photoEmojis:
            (j['photoEmojis'] as List).map((e) => e as String).toList(),
        completedAt: DateTime.parse(j['completedAt'] as String),
      );
}
