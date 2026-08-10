import 'breakpoint.dart';
import 'enums.dart';
import 'geo.dart';

/// A planned or active trip.
class Ride {
  final String id;
  final String groupId;
  String title;
  String startName;
  GeoPoint startPoint;
  String destinationName;
  GeoPoint destinationPoint;
  List<Breakpoint> breakpoints;

  /// Polyline of the chosen route (encoded/decoded as list of points).
  List<GeoPoint> routePoints;
  String routeType; // Fastest / Shortest / Scenic / Motorcycle-friendly
  double plannedDistanceKm;
  int plannedDurationMin;

  RideStatus status;
  final String organizerId;
  String leaderId;
  String? sweepId;
  List<String> participantIds;

  DateTime? plannedStart;
  DateTime? startedAt;
  DateTime? endedAt;

  Ride({
    required this.id,
    required this.groupId,
    required this.title,
    required this.startName,
    required this.startPoint,
    required this.destinationName,
    required this.destinationPoint,
    List<Breakpoint>? breakpoints,
    List<GeoPoint>? routePoints,
    this.routeType = 'Motorcycle-friendly',
    this.plannedDistanceKm = 0,
    this.plannedDurationMin = 0,
    this.status = RideStatus.planned,
    required this.organizerId,
    required this.leaderId,
    this.sweepId,
    List<String>? participantIds,
    this.plannedStart,
    this.startedAt,
    this.endedAt,
  })  : breakpoints = breakpoints ?? [],
        routePoints = routePoints ?? [],
        participantIds = participantIds ?? [];

  /// All stops in order: start, waypoints (by distance), destination.
  List<Breakpoint> get orderedStops {
    final mid = [...breakpoints]
      ..sort((a, b) => a.distanceFromStartKm.compareTo(b.distanceFromStartKm));
    return [
      Breakpoint(
          id: 'start',
          type: BreakpointType.start,
          name: startName,
          location: startPoint,
          distanceFromStartKm: 0),
      ...mid,
      Breakpoint(
          id: 'dest',
          type: BreakpointType.destination,
          name: destinationName,
          location: destinationPoint,
          distanceFromStartKm: plannedDistanceKm),
    ];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'title': title,
        'startName': startName,
        'startPoint': startPoint.toJson(),
        'destinationName': destinationName,
        'destinationPoint': destinationPoint.toJson(),
        'breakpoints': breakpoints.map((e) => e.toJson()).toList(),
        'routePoints': routePoints.map((e) => e.toJson()).toList(),
        'routeType': routeType,
        'plannedDistanceKm': plannedDistanceKm,
        'plannedDurationMin': plannedDurationMin,
        'status': status.name,
        'organizerId': organizerId,
        'leaderId': leaderId,
        'sweepId': sweepId,
        'participantIds': participantIds,
        'plannedStart': plannedStart?.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
      };

  factory Ride.fromJson(Map<String, dynamic> j) => Ride(
        id: j['id'] as String,
        groupId: j['groupId'] as String,
        title: j['title'] as String,
        startName: j['startName'] as String,
        startPoint: GeoPoint.fromJson(j['startPoint'] as Map<String, dynamic>),
        destinationName: j['destinationName'] as String,
        destinationPoint:
            GeoPoint.fromJson(j['destinationPoint'] as Map<String, dynamic>),
        breakpoints: (j['breakpoints'] as List)
            .map((e) => Breakpoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        routePoints: (j['routePoints'] as List? ?? [])
            .map((e) => GeoPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        routeType: j['routeType'] as String? ?? 'Motorcycle-friendly',
        plannedDistanceKm: (j['plannedDistanceKm'] as num?)?.toDouble() ?? 0,
        plannedDurationMin: (j['plannedDurationMin'] as num?)?.toInt() ?? 0,
        status: RideStatus.values
            .firstWhere((e) => e.name == j['status'], orElse: () => RideStatus.planned),
        organizerId: j['organizerId'] as String,
        leaderId: j['leaderId'] as String,
        sweepId: j['sweepId'] as String?,
        participantIds:
            (j['participantIds'] as List).map((e) => e as String).toList(),
        plannedStart: j['plannedStart'] != null
            ? DateTime.parse(j['plannedStart'] as String)
            : null,
        startedAt: j['startedAt'] != null
            ? DateTime.parse(j['startedAt'] as String)
            : null,
        endedAt: j['endedAt'] != null
            ? DateTime.parse(j['endedAt'] as String)
            : null,
      );
}
