import 'enums.dart';

/// A riding community. Members join permanently (vs. a temporary ride group).
class RiderGroup {
  final String id;
  String name;
  String description;
  String imageEmoji;
  GroupPrivacy privacy;
  bool approvalRequired;
  final String joinCode; // short code / QR payload
  List<String> memberIds;
  List<String> adminIds;
  final String createdBy;
  final DateTime createdAt;

  RiderGroup({
    required this.id,
    required this.name,
    this.description = '',
    this.imageEmoji = '🏍️',
    this.privacy = GroupPrivacy.private,
    this.approvalRequired = false,
    required this.joinCode,
    required this.memberIds,
    required this.adminIds,
    required this.createdBy,
    required this.createdAt,
  });

  bool isAdmin(String riderId) => adminIds.contains(riderId);
  int get memberCount => memberIds.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imageEmoji': imageEmoji,
        'privacy': privacy.name,
        'approvalRequired': approvalRequired,
        'joinCode': joinCode,
        'memberIds': memberIds,
        'adminIds': adminIds,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RiderGroup.fromJson(Map<String, dynamic> j) => RiderGroup(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        imageEmoji: j['imageEmoji'] as String? ?? '🏍️',
        privacy: GroupPrivacy.values
            .firstWhere((e) => e.name == j['privacy'], orElse: () => GroupPrivacy.private),
        approvalRequired: j['approvalRequired'] as bool? ?? false,
        joinCode: j['joinCode'] as String,
        memberIds: (j['memberIds'] as List).map((e) => e as String).toList(),
        adminIds: (j['adminIds'] as List).map((e) => e as String).toList(),
        createdBy: j['createdBy'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
