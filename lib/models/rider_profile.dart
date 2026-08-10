/// A rider's persistent profile and cumulative stats.
class RiderProfile {
  final String id;
  String name;
  String? photoEmoji; // simple avatar (emoji) — no image backend needed locally
  String phone;
  String bikeModel;
  int preferredSpeed; // km/h
  String emergencyContactName;
  String emergencyContactPhone;
  String bio;

  // cumulative stats
  int totalRides;
  double totalKm;
  int destinations;
  double longestRideKm;
  int groupsJoined;
  int ridesOrganized;

  RiderProfile({
    required this.id,
    required this.name,
    this.photoEmoji = '🏍️',
    this.phone = '',
    this.bikeModel = '',
    this.preferredSpeed = 60,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.bio = '',
    this.totalRides = 0,
    this.totalKm = 0,
    this.destinations = 0,
    this.longestRideKm = 0,
    this.groupsJoined = 0,
    this.ridesOrganized = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photoEmoji': photoEmoji,
        'phone': phone,
        'bikeModel': bikeModel,
        'preferredSpeed': preferredSpeed,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'bio': bio,
        'totalRides': totalRides,
        'totalKm': totalKm,
        'destinations': destinations,
        'longestRideKm': longestRideKm,
        'groupsJoined': groupsJoined,
        'ridesOrganized': ridesOrganized,
      };

  factory RiderProfile.fromJson(Map<String, dynamic> j) => RiderProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        photoEmoji: j['photoEmoji'] as String? ?? '🏍️',
        phone: j['phone'] as String? ?? '',
        bikeModel: j['bikeModel'] as String? ?? '',
        preferredSpeed: (j['preferredSpeed'] as num?)?.toInt() ?? 60,
        emergencyContactName: j['emergencyContactName'] as String? ?? '',
        emergencyContactPhone: j['emergencyContactPhone'] as String? ?? '',
        bio: j['bio'] as String? ?? '',
        totalRides: (j['totalRides'] as num?)?.toInt() ?? 0,
        totalKm: (j['totalKm'] as num?)?.toDouble() ?? 0,
        destinations: (j['destinations'] as num?)?.toInt() ?? 0,
        longestRideKm: (j['longestRideKm'] as num?)?.toDouble() ?? 0,
        groupsJoined: (j['groupsJoined'] as num?)?.toInt() ?? 0,
        ridesOrganized: (j['ridesOrganized'] as num?)?.toInt() ?? 0,
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
