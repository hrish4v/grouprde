import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/group.dart';
import '../models/ride.dart';
import '../models/ride_history.dart';
import '../models/rider_profile.dart';
import 'repository.dart';

/// On-device persistence using SharedPreferences with JSON encoding.
/// Fully functional offline; this is what the shipped placeholder APK runs on.
class LocalRepository implements Repository {
  static const _kProfile = 'gr_profile';
  static const _kGroups = 'gr_groups';
  static const _kRides = 'gr_rides';
  static const _kHistory = 'gr_history';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<void> init() async {
    await _p;
  }

  // ---------- Profile ----------
  @override
  Future<RiderProfile?> getProfile() async {
    final s = (await _p).getString(_kProfile);
    if (s == null) return null;
    return RiderProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);
  }

  @override
  Future<void> saveProfile(RiderProfile profile) async {
    await (await _p).setString(_kProfile, jsonEncode(profile.toJson()));
  }

  // ---------- Groups ----------
  @override
  Future<List<RiderGroup>> getGroups() async {
    final list = (await _p).getStringList(_kGroups) ?? [];
    return list
        .map((s) => RiderGroup.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<RiderGroup?> getGroup(String id) async {
    final groups = await getGroups();
    for (final g in groups) {
      if (g.id == id) return g;
    }
    return null;
  }

  @override
  Future<void> saveGroup(RiderGroup group) async {
    final groups = await getGroups();
    final idx = groups.indexWhere((g) => g.id == group.id);
    if (idx >= 0) {
      groups[idx] = group;
    } else {
      groups.add(group);
    }
    await _writeGroups(groups);
  }

  @override
  Future<void> deleteGroup(String id) async {
    final groups = await getGroups()
      ..removeWhere((g) => g.id == id);
    await _writeGroups(groups);
  }

  @override
  Future<RiderGroup?> findGroupByCode(String code) async {
    final norm = code.trim().toUpperCase();
    for (final g in await getGroups()) {
      if (g.joinCode.toUpperCase() == norm) return g;
    }
    return null;
  }

  Future<void> _writeGroups(List<RiderGroup> groups) async {
    await (await _p).setStringList(
        _kGroups, groups.map((g) => jsonEncode(g.toJson())).toList());
  }

  // ---------- Rides ----------
  @override
  Future<List<Ride>> getRides({String? groupId}) async {
    final list = (await _p).getStringList(_kRides) ?? [];
    var rides = list
        .map((s) => Ride.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    if (groupId != null) {
      rides = rides.where((r) => r.groupId == groupId).toList();
    }
    return rides;
  }

  @override
  Future<Ride?> getRide(String id) async {
    for (final r in await getRides()) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<void> saveRide(Ride ride) async {
    final rides = await getRides();
    final idx = rides.indexWhere((r) => r.id == ride.id);
    if (idx >= 0) {
      rides[idx] = ride;
    } else {
      rides.add(ride);
    }
    await _writeRides(rides);
  }

  @override
  Future<void> deleteRide(String id) async {
    final rides = await getRides()
      ..removeWhere((r) => r.id == id);
    await _writeRides(rides);
  }

  Future<void> _writeRides(List<Ride> rides) async {
    await (await _p).setStringList(
        _kRides, rides.map((r) => jsonEncode(r.toJson())).toList());
  }

  // ---------- History ----------
  @override
  Future<List<RideHistory>> getHistory() async {
    final list = (await _p).getStringList(_kHistory) ?? [];
    final h = list
        .map((s) => RideHistory.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    h.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return h;
  }

  @override
  Future<void> saveHistory(RideHistory history) async {
    final all = await getHistory()..insert(0, history);
    await (await _p).setStringList(
        _kHistory, all.map((e) => jsonEncode(e.toJson())).toList());
  }
}
