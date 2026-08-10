import 'package:flutter/material.dart';

/// Types of planned stops along a route.
enum BreakpointType {
  fuel,
  tea,
  food,
  scenic,
  photo,
  hotel,
  service,
  hospital,
  parking,
  start,
  destination;

  String get label {
    switch (this) {
      case BreakpointType.fuel:
        return 'Fuel';
      case BreakpointType.tea:
        return 'Tea / Coffee';
      case BreakpointType.food:
        return 'Food';
      case BreakpointType.scenic:
        return 'Scenic';
      case BreakpointType.photo:
        return 'Photo';
      case BreakpointType.hotel:
        return 'Hotel';
      case BreakpointType.service:
        return 'Bike Service';
      case BreakpointType.hospital:
        return 'Hospital';
      case BreakpointType.parking:
        return 'Parking';
      case BreakpointType.start:
        return 'Start';
      case BreakpointType.destination:
        return 'Destination';
    }
  }

  String get emoji {
    switch (this) {
      case BreakpointType.fuel:
        return '⛽';
      case BreakpointType.tea:
        return '☕';
      case BreakpointType.food:
        return '🍛';
      case BreakpointType.scenic:
        return '🏞️';
      case BreakpointType.photo:
        return '📸';
      case BreakpointType.hotel:
        return '🏨';
      case BreakpointType.service:
        return '🔧';
      case BreakpointType.hospital:
        return '🏥';
      case BreakpointType.parking:
        return '🅿️';
      case BreakpointType.start:
        return '🚩';
      case BreakpointType.destination:
        return '🏁';
    }
  }
}

/// One-tap requests riders can broadcast during a ride.
enum QuickRequestType {
  breakRequest,
  fuel,
  food,
  water,
  bikeIssue,
  stop,
  emergency;

  String get label {
    switch (this) {
      case QuickRequestType.breakRequest:
        return 'Break';
      case QuickRequestType.fuel:
        return 'Need Fuel';
      case QuickRequestType.food:
        return 'Need Food';
      case QuickRequestType.water:
        return 'Water';
      case QuickRequestType.bikeIssue:
        return 'Bike Issue';
      case QuickRequestType.stop:
        return 'Stop';
      case QuickRequestType.emergency:
        return 'Emergency';
    }
  }

  String get emoji {
    switch (this) {
      case QuickRequestType.breakRequest:
        return '🛑';
      case QuickRequestType.fuel:
        return '⛽';
      case QuickRequestType.food:
        return '🍛';
      case QuickRequestType.water:
        return '💧';
      case QuickRequestType.bikeIssue:
        return '🔧';
      case QuickRequestType.stop:
        return '✋';
      case QuickRequestType.emergency:
        return '🚨';
    }
  }

  String message(String rider) {
    switch (this) {
      case QuickRequestType.breakRequest:
        return '$rider has requested a break';
      case QuickRequestType.fuel:
        return '$rider needs fuel';
      case QuickRequestType.food:
        return '$rider requests a food stop';
      case QuickRequestType.water:
        return '$rider needs a water break';
      case QuickRequestType.bikeIssue:
        return '$rider has reported a bike issue';
      case QuickRequestType.stop:
        return '$rider requests the group to stop';
      case QuickRequestType.emergency:
        return '$rider has triggered an EMERGENCY alert';
    }
  }

  bool get isCritical => this == QuickRequestType.emergency;
}

/// Live connectivity / motion state of a rider during a ride.
enum RiderConnectionStatus {
  moving,
  slow,
  stopped,
  behind,
  wrongRoute,
  disconnected;

  String get label {
    switch (this) {
      case RiderConnectionStatus.moving:
        return 'Moving';
      case RiderConnectionStatus.slow:
        return 'Slow';
      case RiderConnectionStatus.stopped:
        return 'Stopped';
      case RiderConnectionStatus.behind:
        return 'Falling behind';
      case RiderConnectionStatus.wrongRoute:
        return 'Off route';
      case RiderConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  Color get color {
    switch (this) {
      case RiderConnectionStatus.moving:
        return const Color(0xFF2ECC71);
      case RiderConnectionStatus.slow:
        return const Color(0xFFF5A623);
      case RiderConnectionStatus.stopped:
        return const Color(0xFFF5A623);
      case RiderConnectionStatus.behind:
        return const Color(0xFFF5A623);
      case RiderConnectionStatus.wrongRoute:
        return const Color(0xFFE74C3C);
      case RiderConnectionStatus.disconnected:
        return const Color(0xFF95A5A6);
    }
  }
}

enum RideStatus { planned, active, completed, cancelled }

enum RiderRole {
  leader,
  sweep,
  member;

  String get label {
    switch (this) {
      case RiderRole.leader:
        return 'Ride Leader';
      case RiderRole.sweep:
        return 'Sweep Rider';
      case RiderRole.member:
        return 'Rider';
    }
  }

  String get emoji {
    switch (this) {
      case RiderRole.leader:
        return '👑';
      case RiderRole.sweep:
        return '🛡️';
      case RiderRole.member:
        return '🏍️';
    }
  }
}

enum EmergencyType {
  accident,
  breakdown,
  medical,
  lost,
  other;

  String get label {
    switch (this) {
      case EmergencyType.accident:
        return 'Accident';
      case EmergencyType.breakdown:
        return 'Bike Breakdown';
      case EmergencyType.medical:
        return 'Medical Emergency';
      case EmergencyType.lost:
        return 'Lost Rider';
      case EmergencyType.other:
        return 'Other';
    }
  }
}

enum GroupPrivacy { public, private }
