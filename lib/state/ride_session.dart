import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../models/breakpoint.dart';
import '../models/enums.dart';
import '../models/geo.dart';
import '../models/quick_request.dart';
import '../models/ride.dart';
import '../models/ride_history.dart';
import '../models/rider_live_state.dart';
import '../models/rider_profile.dart';
import '../services/demo_seed.dart';
import '../services/location_service.dart';

/// Walks a polyline by cumulative distance so simulated riders move along the
/// actual planned route rather than in a straight line.
class _RoutePath {
  final List<GeoPoint> points;
  final List<double> _cum = [];
  double totalKm = 0;

  _RoutePath(this.points) {
    _cum.add(0);
    for (var i = 1; i < points.length; i++) {
      totalKm += points[i - 1].distanceKm(points[i]);
      _cum.add(totalKm);
    }
  }

  GeoPoint pointAt(double km) {
    if (points.isEmpty) return LocationService.fallback;
    if (km <= 0) return points.first;
    if (km >= totalKm) return points.last;
    for (var i = 1; i < points.length; i++) {
      if (_cum[i] >= km) {
        final seg = _cum[i] - _cum[i - 1];
        final t = seg == 0 ? 0.0 : (km - _cum[i - 1]) / seg;
        final a = points[i - 1];
        final b = points[i];
        return GeoPoint(a.lat + (b.lat - a.lat) * t, a.lng + (b.lng - a.lng) * t);
      }
    }
    return points.last;
  }

  double headingAt(double km) {
    final a = pointAt(km);
    final b = pointAt(math.min(km + 0.5, totalKm));
    return a.bearingTo(b);
  }
}

class _SimRider {
  final RiderLiveState state;
  double progressKm;
  double speedKmh;
  final double lateralBias; // slight lane offset for visual separation
  _SimRider(this.state, this.progressKm, this.speedKmh, this.lateralBias);
}

/// Drives an active ride: live positions (simulated in local mode), separation
/// detection, quick requests and emergencies, and produces a [RideHistory] on
/// completion. Per the privacy model, all live state is discarded on end().
class RideSession extends ChangeNotifier {
  final Ride ride;
  final RiderProfile self;
  final LocationService location;

  final _uuid = const Uuid();
  final _rng = math.Random(7);
  late final _RoutePath _path;

  final List<_SimRider> _sim = [];
  final List<QuickRequest> requests = [];
  final List<String> _timeline = [];

  Timer? _timer;
  int _ticks = 0;
  double _maxSpeed = 0;
  final DateTime _startedAt = DateTime.now();
  bool _ended = false;

  RideSession(
      {required this.ride, required this.self, required this.location}) {
    _path = _RoutePath(ride.routePoints.isNotEmpty
        ? ride.routePoints
        : DemoSeed.lerpRoute(ride.startPoint, ride.destinationPoint, 24));
    _buildRiders();
    _addTimeline('Ride started from ${ride.startName}');
  }

  // ---- public views ----
  List<RiderLiveState> get riders => _sim.map((s) => s.state).toList();
  RiderLiveState get me => _sim.firstWhere((s) => s.state.isSelf).state;
  List<QuickRequest> get activeRequests =>
      requests.where((r) => !r.resolved).toList().reversed.toList();
  List<QuickRequest> get emergencies => requests
      .where((r) => r.type == QuickRequestType.emergency && !r.resolved)
      .toList();

  double get coveredKm {
    final leader = _sim.firstWhere(
        (s) => s.state.role == RiderRole.leader,
        orElse: () => _sim.first);
    return leader.progressKm.clamp(0, _path.totalKm).toDouble();
  }

  double get totalKm => ride.plannedDistanceKm > 0
      ? ride.plannedDistanceKm
      : _path.totalKm;

  int get activeRiders => _sim
      .where((s) => s.state.status != RiderConnectionStatus.disconnected)
      .length;

  int get ridersBehind => _sim
      .where((s) => s.state.status == RiderConnectionStatus.behind)
      .length;

  Duration get elapsed => DateTime.now().difference(_startedAt);

  /// Overall group health used by the dashboard banner.
  GroupHealth get health {
    if (emergencies.isNotEmpty) return GroupHealth.danger;
    if (ridersBehind > 0 ||
        activeRequests.any((r) => r.type == QuickRequestType.bikeIssue)) {
      return GroupHealth.warn;
    }
    return GroupHealth.ok;
  }

  Breakpoint? get nextStop {
    final covered = coveredKm;
    for (final s in ride.orderedStops) {
      if (s.type == BreakpointType.start) continue;
      if (s.distanceFromStartKm >= covered - 1) return s;
    }
    return null;
  }

  double get distanceToNextStopKm {
    final s = nextStop;
    if (s == null) return 0;
    return (s.distanceFromStartKm - coveredKm).clamp(0, totalKm).toDouble();
  }

  // ---- lifecycle ----
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _buildRiders() {
    // self
    _sim.add(_SimRider(
      RiderLiveState(
        riderId: self.id,
        name: self.name,
        avatarEmoji: self.photoEmoji ?? '🏍️',
        position: _path.pointAt(6),
        role: ride.leaderId == self.id ? RiderRole.leader : RiderRole.member,
        speedKmh: 54,
        isSelf: true,
        lastUpdate: DateTime.now(),
      ),
      6, // progress km
      54,
      0,
    ));

    if (!(AppConfig.isLocal && AppConfig.simulateRidersInLocalMode)) return;

    // simulated buddies spread around self, with a leader out front and a
    // sweep at the back.
    final count = math.min(4, DemoSeed.buddyNames.length);
    for (var i = 0; i < count; i++) {
      final isLeaderSlot = i == 0 && ride.leaderId != self.id;
      final role = i == 0
          ? (ride.leaderId == self.id ? RiderRole.member : RiderRole.leader)
          : (i == count - 1 ? RiderRole.sweep : RiderRole.member);
      final progress = 6 + (isLeaderSlot ? 0.9 : 0.0) - i * 0.5;
      _sim.add(_SimRider(
        RiderLiveState(
          riderId: 'buddy_$i',
          name: DemoSeed.buddyNames[i],
          avatarEmoji: DemoSeed.buddyEmojis[i],
          position: _path.pointAt(progress.clamp(0, _path.totalKm).toDouble()),
          role: role,
          speedKmh: 52 + _rng.nextDouble() * 6,
          lastUpdate: DateTime.now(),
        ),
        progress.clamp(0, _path.totalKm).toDouble(),
        52 + _rng.nextDouble() * 6,
        (_rng.nextDouble() - 0.5) * 0.0009,
      ));
    }
  }

  void _tick() {
    if (_ended) return;
    _ticks++;
    final dtHours = 1 / 3600.0;

    for (final s in _sim) {
      // speed jitter
      s.speedKmh += (_rng.nextDouble() - 0.5) * 4;
      s.speedKmh = s.speedKmh.clamp(0, 95).toDouble();

      // scripted separation demo: the sweep drifts back between 15-40s then
      // recovers, so the separation alert is actually visible.
      if (s.state.role == RiderRole.sweep) {
        if (_ticks > 15 && _ticks < 42) {
          s.speedKmh = 24 + _rng.nextDouble() * 6;
        }
      }

      s.progressKm += s.speedKmh * dtHours;
      s.progressKm = s.progressKm.clamp(0, _path.totalKm).toDouble();
      _maxSpeed = math.max(_maxSpeed, s.speedKmh);

      final pos = _path.pointAt(s.progressKm);
      s.state
        ..position = GeoPoint(pos.lat + s.lateralBias, pos.lng + s.lateralBias)
        ..speedKmh = s.speedKmh
        ..headingDeg = _path.headingAt(s.progressKm)
        ..lastUpdate = DateTime.now();
    }

    // leader reference + statuses
    final leader = _sim.firstWhere((s) => s.state.role == RiderRole.leader,
        orElse: () => _sim.first);
    for (final s in _sim) {
      final gap = leader.progressKm - s.progressKm;
      s.state.distanceFromLeaderKm = gap.abs();
      s.state.distanceToNextStopKm = distanceToNextStopKm;
      if (s.state.role == RiderRole.leader) {
        s.state.status = RiderConnectionStatus.moving;
      } else if (gap > 1.5) {
        s.state.status = RiderConnectionStatus.behind;
      } else if (s.state.speedKmh < 8) {
        s.state.status = RiderConnectionStatus.stopped;
      } else if (s.state.speedKmh < 25) {
        s.state.status = RiderConnectionStatus.slow;
      } else {
        s.state.status = RiderConnectionStatus.moving;
      }
    }

    // fire a one-time separation timeline note
    if (_ticks == 22) {
      final sweep = _sim.firstWhere(
          (s) => s.state.role == RiderRole.sweep,
          orElse: () => _sim.last);
      _addTimeline(
          '${sweep.state.name} fell behind the group near ${nextStop?.name ?? 'the route'}');
    }

    notifyListeners();
  }

  // ---- requests ----
  QuickRequest sendRequest(QuickRequestType type,
      {String? reasonNote, EmergencyType? emergencyType}) {
    final req = QuickRequest(
      id: _uuid.v4(),
      riderId: self.id,
      riderName: self.name,
      type: type,
      message: type.message(self.name) +
          (reasonNote != null && reasonNote.isNotEmpty ? ' ($reasonNote)' : ''),
      location: me.position,
      emergencyType: emergencyType,
      createdAt: DateTime.now(),
    );
    requests.add(req);
    _addTimeline(req.message);
    notifyListeners();
    return req;
  }

  void resolveRequest(String id) {
    final r = requests.firstWhere((e) => e.id == id,
        orElse: () => throw StateError('not found'));
    r.resolved = true;
    notifyListeners();
  }

  void _addTimeline(String note) {
    final t = elapsedLabel;
    _timeline.add('$t — $note');
  }

  String get elapsedLabel {
    final e = elapsed;
    final h = e.inHours;
    final m = e.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  // ---- end ----
  RideHistory finish() {
    _ended = true;
    _timer?.cancel();
    _addTimeline('Ride completed at ${ride.destinationName}');
    final dur = math.max(1, elapsed.inMinutes);
    final avg = coveredKm / (dur / 60.0);
    return RideHistory(
      id: _uuid.v4(),
      rideId: ride.id,
      title: ride.title,
      startName: ride.startName,
      destinationName: ride.destinationName,
      distanceKm: double.parse(coveredKm.toStringAsFixed(1)),
      durationMin: dur,
      riderCount: _sim.length,
      breakpointCount: ride.breakpoints.length,
      avgSpeedKmh: double.parse(avg.isFinite ? avg.toStringAsFixed(0) : '0'),
      maxSpeedKmh: double.parse(_maxSpeed.toStringAsFixed(0)),
      actualRoute: _path.points
          .take((_path.points.length * (coveredKm / totalKm))
              .clamp(2, _path.points.length)
              .toInt())
          .toList(),
      timeline: List<String>.from(_timeline),
      photoEmojis: const ['🏍️', '⛰️', '☕', '📸', '🌄'],
      completedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

enum GroupHealth { ok, warn, danger }
