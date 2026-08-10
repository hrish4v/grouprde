import 'package:uuid/uuid.dart';

import '../models/breakpoint.dart';
import '../models/enums.dart';
import '../models/geo.dart';
import '../models/group.dart';
import '../models/ride.dart';
import '../models/ride_history.dart';
import '../data/repository.dart';

/// Seeds a friendly starter experience on first launch so the app never feels
/// empty: one demo group, one planned ride (Bangalore -> Coorg with the exact
/// breakpoints from the product spec), and one past ride in history.
class DemoSeed {
  static const _uuid = Uuid();

  /// Names of simulated riding buddies used during rides in local mode.
  static const buddyNames = ['Rahul', 'Ananya', 'Vikram', 'Meera', 'Arjun'];
  static const buddyEmojis = ['🏍️', '🛵', '🏍️', '🏍️', '🛵'];

  static Future<void> seedIfEmpty(Repository repo, String ownerId) async {
    final groups = await repo.getGroups();
    if (groups.isNotEmpty) return;

    final group = RiderGroup(
      id: _uuid.v4(),
      name: 'Weekend Warriors',
      description: 'Bangalore-based weekend riders. Twisties & filter coffee.',
      imageEmoji: '🏔️',
      privacy: GroupPrivacy.private,
      joinCode: 'RIDE42',
      memberIds: [ownerId, 'buddy_0', 'buddy_1', 'buddy_2'],
      adminIds: [ownerId],
      createdBy: ownerId,
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
    );
    await repo.saveGroup(group);

    // Bangalore -> Coorg planned ride with spec breakpoints.
    const blr = GeoPoint(12.9716, 77.5946);
    const coorg = GeoPoint(12.3375, 75.8069);
    final ride = Ride(
      id: _uuid.v4(),
      groupId: group.id,
      title: 'Coorg Monsoon Run',
      startName: 'Bangalore',
      startPoint: blr,
      destinationName: 'Coorg',
      destinationPoint: coorg,
      routeType: 'Scenic',
      plannedDistanceKm: 295,
      plannedDurationMin: 401,
      organizerId: ownerId,
      leaderId: ownerId,
      sweepId: 'buddy_0',
      participantIds: [ownerId, 'buddy_0', 'buddy_1', 'buddy_2'],
      plannedStart: DateTime.now().add(const Duration(days: 3)),
      breakpoints: [
        Breakpoint(
            id: _uuid.v4(),
            type: BreakpointType.fuel,
            name: 'Ramanagara — Fuel Stop',
            location: const GeoPoint(12.7209, 77.2807),
            distanceFromStartKm: 72,
            plannedDurationMin: 10),
        Breakpoint(
            id: _uuid.v4(),
            type: BreakpointType.food,
            name: 'Maddur — Breakfast',
            location: const GeoPoint(12.5847, 77.0430),
            distanceFromStartKm: 122,
            plannedDurationMin: 30,
            notes: 'Maddur vada is mandatory.'),
        Breakpoint(
            id: _uuid.v4(),
            type: BreakpointType.photo,
            name: 'Coffee Estate Viewpoint',
            location: const GeoPoint(12.4200, 75.9500),
            distanceFromStartKm: 242,
            plannedDurationMin: 15),
      ],
      routePoints: _lerpRoute(blr, coorg, 24),
    );
    await repo.saveRide(ride);

    // A past ride in history.
    await repo.saveHistory(RideHistory(
      id: _uuid.v4(),
      rideId: _uuid.v4(),
      title: 'Nandi Hills Sunrise',
      startName: 'Bangalore',
      destinationName: 'Nandi Hills',
      distanceKm: 122,
      durationMin: 214,
      riderCount: 6,
      breakpointCount: 3,
      avgSpeedKmh: 48,
      maxSpeedKmh: 92,
      actualRoute: _lerpRoute(
          const GeoPoint(12.9716, 77.5946), const GeoPoint(13.3702, 77.6835), 16),
      timeline: const [
        '05:10 — Ride started from Bangalore',
        '05:55 — Fuel stop at Devanahalli',
        '06:40 — Reached Nandi Hills for sunrise',
        '08:30 — Breakfast at the base',
        '10:45 — Ride completed',
      ],
      photoEmojis: const ['🌄', '🏍️', '☕', '📸', '🏔️'],
      completedAt: DateTime.now().subtract(const Duration(days: 12)),
    ));
  }

  /// Simple interpolated route between two points (stand-in for a Directions
  /// API polyline until a real Google Maps key + Directions call is wired in).
  static List<GeoPoint> _lerpRoute(GeoPoint a, GeoPoint b, int steps) {
    final pts = <GeoPoint>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      // add a gentle sine wiggle so it reads like a road, not a straight line
      final wig = 0.06 * (t) * (1 - t);
      pts.add(GeoPoint(
        a.lat + (b.lat - a.lat) * t + wig * (i.isEven ? 1 : -1),
        a.lng + (b.lng - a.lng) * t,
      ));
    }
    return pts;
  }

  static List<GeoPoint> lerpRoute(GeoPoint a, GeoPoint b, int steps) =>
      _lerpRoute(a, b, steps);
}
