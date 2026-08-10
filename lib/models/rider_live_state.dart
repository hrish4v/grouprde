import 'enums.dart';
import 'geo.dart';

/// The live, in-ride state of a single rider. Ephemeral — only meaningful while
/// a ride is active, and (per privacy design) discarded when the ride ends.
class RiderLiveState {
  final String riderId;
  String name;
  String avatarEmoji;
  GeoPoint position;
  double speedKmh;
  double headingDeg;
  RiderConnectionStatus status;
  RiderRole role;
  double distanceFromLeaderKm;
  double distanceToNextStopKm;
  DateTime lastUpdate;
  bool isSelf;

  RiderLiveState({
    required this.riderId,
    required this.name,
    this.avatarEmoji = '🏍️',
    required this.position,
    this.speedKmh = 0,
    this.headingDeg = 0,
    this.status = RiderConnectionStatus.moving,
    this.role = RiderRole.member,
    this.distanceFromLeaderKm = 0,
    this.distanceToNextStopKm = 0,
    required this.lastUpdate,
    this.isSelf = false,
  });

  RiderLiveState copyWith({
    GeoPoint? position,
    double? speedKmh,
    double? headingDeg,
    RiderConnectionStatus? status,
    double? distanceFromLeaderKm,
    double? distanceToNextStopKm,
    DateTime? lastUpdate,
  }) {
    return RiderLiveState(
      riderId: riderId,
      name: name,
      avatarEmoji: avatarEmoji,
      position: position ?? this.position,
      speedKmh: speedKmh ?? this.speedKmh,
      headingDeg: headingDeg ?? this.headingDeg,
      status: status ?? this.status,
      role: role,
      distanceFromLeaderKm: distanceFromLeaderKm ?? this.distanceFromLeaderKm,
      distanceToNextStopKm: distanceToNextStopKm ?? this.distanceToNextStopKm,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isSelf: isSelf,
    );
  }
}
