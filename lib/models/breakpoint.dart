import 'enums.dart';
import 'geo.dart';

/// A planned stop / waypoint along a ride route.
class Breakpoint {
  final String id;
  BreakpointType type;
  String name;
  GeoPoint location;
  String? expectedArrival; // free text or ISO time
  int plannedDurationMin;
  String notes;
  double distanceFromStartKm;

  Breakpoint({
    required this.id,
    required this.type,
    required this.name,
    required this.location,
    this.expectedArrival,
    this.plannedDurationMin = 15,
    this.notes = '',
    this.distanceFromStartKm = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'location': location.toJson(),
        'expectedArrival': expectedArrival,
        'plannedDurationMin': plannedDurationMin,
        'notes': notes,
        'distanceFromStartKm': distanceFromStartKm,
      };

  factory Breakpoint.fromJson(Map<String, dynamic> j) => Breakpoint(
        id: j['id'] as String,
        type: BreakpointType.values
            .firstWhere((e) => e.name == j['type'], orElse: () => BreakpointType.scenic),
        name: j['name'] as String,
        location: GeoPoint.fromJson(j['location'] as Map<String, dynamic>),
        expectedArrival: j['expectedArrival'] as String?,
        plannedDurationMin: (j['plannedDurationMin'] as num?)?.toInt() ?? 15,
        notes: j['notes'] as String? ?? '',
        distanceFromStartKm:
            (j['distanceFromStartKm'] as num?)?.toDouble() ?? 0,
      );
}
