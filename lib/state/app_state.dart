import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../data/repository.dart';
import '../data/repository_provider.dart';
import '../models/enums.dart';
import '../models/group.dart';
import '../models/ride.dart';
import '../models/ride_history.dart';
import '../models/rider_profile.dart';
import '../services/debug_log.dart';
import '../services/demo_seed.dart';
import '../services/location_service.dart';
import 'auth_service.dart';

/// Top-level app state: current rider, groups, rides, history. Backed by the
/// active [Repository] (local now, Firebase-ready later).
class AppState extends ChangeNotifier {
  final Repository repo = createRepository();
  final LocationService location = LocationService();
  final _uuid = const Uuid();

  bool _ready = false;
  bool get ready => _ready;

  RiderProfile? _profile;
  RiderProfile? get profile => _profile;
  bool get isOnboarded => _profile != null;

  List<RiderGroup> groups = [];
  List<Ride> rides = [];
  List<RideHistory> history = [];

  String? _loadedUid;

  /// Last backend error surfaced to the UI (e.g. Firestore unreachable), so the
  /// app can show it instead of freezing.
  String? lastError;
  void clearError() {
    lastError = null;
    notifyListeners();
  }

  Future<void> init() async {
    DebugLog.add('AppState.init start (${AppConfig.backend.name})');
    await repo.init();
    DebugLog.add('repo.init done');
    if (AppConfig.isLocal) {
      _profile = await repo.getProfile();
      if (_profile != null) {
        await DemoSeed.seedIfEmpty(repo, _profile!.id);
        await refreshAll();
      }
    }
    // In Firebase mode the profile is loaded after sign-in via ensureLoaded().
    // fire and forget — don't block UI on permission
    location.ensurePermission();
    _ready = true;
    DebugLog.add('AppState ready');
    notifyListeners();
  }

  /// Firebase mode: load the signed-in user's profile + data once.
  /// Never hangs — reads time out, and errors are captured in [lastError]
  /// instead of freezing the UI.
  Future<void> ensureLoaded(String uid) async {
    if (_loadedUid == uid && _profile != null) return;
    _loadedUid = uid;
    lastError = null;
    DebugLog.add('ensureLoaded: start');
    try {
      _profile =
          await repo.getProfile().timeout(const Duration(seconds: 12));
      DebugLog.add(
          'ensureLoaded: getProfile -> ${_profile == null ? "null (new user)" : "existing profile"}');
      if (_profile != null) {
        await refreshAll().timeout(const Duration(seconds: 12));
        DebugLog.add('ensureLoaded: refreshAll done');
      }
    } on TimeoutException {
      lastError =
          'Timed out reaching the database (12s). Check internet / Firestore rules.';
      _profile = null;
      DebugLog.add('ensureLoaded: TIMEOUT');
    } catch (e) {
      lastError = 'Database error: $e';
      _profile = null;
      DebugLog.add('ensureLoaded: ERROR $e');
    }
    DebugLog.add('ensureLoaded: done (profile=${_profile != null})');
    notifyListeners();
  }

  /// Firebase mode: sign out and clear state.
  Future<void> signOut() async {
    await AuthService().signOut();
    _profile = null;
    _loadedUid = null;
    groups = [];
    rides = [];
    history = [];
    notifyListeners();
  }

  Future<void> refreshAll() async {
    groups = await repo.getGroups();
    rides = await repo.getRides();
    history = await repo.getHistory();
    notifyListeners();
  }

  // ---------- Profile ----------
  Future<void> createProfile({
    required String name,
    required String bikeModel,
    String phone = '',
    int preferredSpeed = 60,
    String emergencyName = '',
    String emergencyPhone = '',
    String emoji = '🏍️',
  }) async {
    // In Firebase mode the profile id must be the auth uid so it maps to
    // profiles/{uid}. In local mode a random id is fine.
    final id = AppConfig.isFirebase
        ? (AuthService().uid ?? _uuid.v4())
        : _uuid.v4();
    final p = RiderProfile(
      id: id,
      name: name,
      bikeModel: bikeModel,
      phone: phone,
      preferredSpeed: preferredSpeed,
      emergencyContactName: emergencyName,
      emergencyContactPhone: emergencyPhone,
      photoEmoji: emoji,
    );
    await repo.saveProfile(p);
    _profile = p;
    _loadedUid = id;
    if (AppConfig.isLocal) {
      await DemoSeed.seedIfEmpty(repo, p.id);
    }
    await refreshAll();
  }

  Future<void> updateProfile(RiderProfile p) async {
    await repo.saveProfile(p);
    _profile = p;
    notifyListeners();
  }

  // ---------- Groups ----------
  List<RiderGroup> get myGroups {
    final id = _profile?.id;
    if (id == null) return [];
    return groups.where((g) => g.memberIds.contains(id)).toList();
  }

  Future<RiderGroup> createGroup({
    required String name,
    String description = '',
    String emoji = '🏍️',
    GroupPrivacy privacy = GroupPrivacy.private,
    bool approvalRequired = false,
  }) async {
    final id = _profile!.id;
    final g = RiderGroup(
      id: _uuid.v4(),
      name: name,
      description: description,
      imageEmoji: emoji,
      privacy: privacy,
      approvalRequired: approvalRequired,
      joinCode: _makeCode(),
      memberIds: [id],
      adminIds: [id],
      createdBy: id,
      createdAt: DateTime.now(),
    );
    await repo.saveGroup(g);
    _profile!.groupsJoined += 1;
    await repo.saveProfile(_profile!);
    await refreshAll();
    return g;
  }

  /// Returns null if no group matches the code.
  Future<RiderGroup?> joinGroupByCode(String code) async {
    final g = await repo.findGroupByCode(code);
    if (g == null) return null;
    final id = _profile!.id;
    if (!g.memberIds.contains(id)) {
      g.memberIds.add(id);
      await repo.saveGroup(g);
      _profile!.groupsJoined += 1;
      await repo.saveProfile(_profile!);
    }
    await refreshAll();
    return g;
  }

  Future<void> leaveGroup(String groupId) async {
    final g = await repo.getGroup(groupId);
    if (g == null) return;
    g.memberIds.remove(_profile!.id);
    if (g.memberIds.isEmpty) {
      await repo.deleteGroup(groupId);
    } else {
      await repo.saveGroup(g);
    }
    await refreshAll();
  }

  // ---------- Rides ----------
  List<Ride> ridesForGroup(String groupId) =>
      rides.where((r) => r.groupId == groupId).toList();

  Future<void> saveRide(Ride ride) async {
    final isNew = await repo.getRide(ride.id) == null;
    await repo.saveRide(ride);
    if (isNew && ride.organizerId == _profile?.id) {
      _profile!.ridesOrganized += 1;
      await repo.saveProfile(_profile!);
    }
    await refreshAll();
  }

  Future<void> deleteRide(String id) async {
    await repo.deleteRide(id);
    await refreshAll();
  }

  // ---------- History ----------
  Future<void> completeRide(RideHistory h, Ride ride) async {
    await repo.saveHistory(h);
    ride.status = RideStatus.completed;
    ride.endedAt = DateTime.now();
    await repo.saveRide(ride);
    // update rider stats
    if (_profile != null) {
      _profile!.totalRides += 1;
      _profile!.totalKm += h.distanceKm;
      _profile!.destinations += 1;
      if (h.distanceKm > _profile!.longestRideKm) {
        _profile!.longestRideKm = h.distanceKm;
      }
      await repo.saveProfile(_profile!);
    }
    await refreshAll();
  }

  String newId() => _uuid.v4();

  String _makeCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    var code = '';
    var seed = now;
    for (var i = 0; i < 6; i++) {
      code += chars[seed % chars.length];
      seed = seed ~/ chars.length + 7;
    }
    return code;
  }
}
