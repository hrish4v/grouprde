import 'enums.dart';
import 'geo.dart';

/// A broadcast request/alert raised by a rider during an active ride.
class QuickRequest {
  final String id;
  final String riderId;
  final String riderName;
  final QuickRequestType type;
  final String message;
  final GeoPoint? location;
  final EmergencyType? emergencyType;
  final DateTime createdAt;
  bool resolved;

  QuickRequest({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.type,
    required this.message,
    this.location,
    this.emergencyType,
    required this.createdAt,
    this.resolved = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'riderName': riderName,
        'type': type.name,
        'message': message,
        'location': location?.toJson(),
        'emergencyType': emergencyType?.name,
        'createdAt': createdAt.toIso8601String(),
        'resolved': resolved,
      };

  factory QuickRequest.fromJson(Map<String, dynamic> j) => QuickRequest(
        id: j['id'] as String,
        riderId: j['riderId'] as String,
        riderName: j['riderName'] as String,
        type: QuickRequestType.values.firstWhere((e) => e.name == j['type'],
            orElse: () => QuickRequestType.stop),
        message: j['message'] as String,
        location: j['location'] != null
            ? GeoPoint.fromJson(j['location'] as Map<String, dynamic>)
            : null,
        emergencyType: j['emergencyType'] != null
            ? EmergencyType.values.firstWhere(
                (e) => e.name == j['emergencyType'],
                orElse: () => EmergencyType.other)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
        resolved: j['resolved'] as bool? ?? false,
      );
}
