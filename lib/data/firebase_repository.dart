import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group.dart';
import '../models/ride.dart';
import '../models/ride_history.dart';
import '../models/rider_profile.dart';
import 'repository.dart';

/// Firestore-backed implementation of [Repository]. Groups, rides and history
/// are shared across every signed-in rider, so friends who join the same group
/// (by code) see the same rides. Live in-ride positions are handled separately
/// in RideSession (rides/{id}/live/{uid}).
///
/// Firestore layout:
///   profiles/{uid}                      -> RiderProfile
///   groups/{groupId}                    -> RiderGroup (memberIds contains uid)
///   rides/{rideId}                      -> Ride
///   history/{uid}/rides/{historyId}     -> RideHistory
class FirebaseRepository implements Repository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  @override
  Future<void> init() async {}

  // ---- Profile ----
  @override
  Future<RiderProfile?> getProfile() async {
    final doc = await _db.collection('profiles').doc(_uid).get();
    final data = doc.data();
    if (data == null) return null;
    return RiderProfile.fromJson(data);
  }

  @override
  Future<void> saveProfile(RiderProfile profile) async {
    await _db.collection('profiles').doc(profile.id).set(profile.toJson());
  }

  // ---- Groups ----
  @override
  Future<List<RiderGroup>> getGroups() async {
    final snap = await _db
        .collection('groups')
        .where('memberIds', arrayContains: _uid)
        .get();
    return snap.docs.map((d) => RiderGroup.fromJson(d.data())).toList();
  }

  @override
  Future<RiderGroup?> getGroup(String id) async {
    final d = await _db.collection('groups').doc(id).get();
    final data = d.data();
    return data == null ? null : RiderGroup.fromJson(data);
  }

  @override
  Future<void> saveGroup(RiderGroup group) async {
    await _db.collection('groups').doc(group.id).set(group.toJson());
  }

  @override
  Future<void> deleteGroup(String id) async {
    await _db.collection('groups').doc(id).delete();
  }

  @override
  Future<RiderGroup?> findGroupByCode(String code) async {
    final snap = await _db
        .collection('groups')
        .where('joinCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return RiderGroup.fromJson(snap.docs.first.data());
  }

  // ---- Rides ----
  @override
  Future<List<Ride>> getRides({String? groupId}) async {
    Query<Map<String, dynamic>> q = _db.collection('rides');
    if (groupId != null) q = q.where('groupId', isEqualTo: groupId);
    final snap = await q.get();
    return snap.docs.map((d) => Ride.fromJson(d.data())).toList();
  }

  @override
  Future<Ride?> getRide(String id) async {
    final d = await _db.collection('rides').doc(id).get();
    final data = d.data();
    return data == null ? null : Ride.fromJson(data);
  }

  @override
  Future<void> saveRide(Ride ride) async {
    await _db.collection('rides').doc(ride.id).set(ride.toJson());
  }

  @override
  Future<void> deleteRide(String id) async {
    await _db.collection('rides').doc(id).delete();
  }

  // ---- History ----
  @override
  Future<List<RideHistory>> getHistory() async {
    final snap = await _db
        .collection('history')
        .doc(_uid)
        .collection('rides')
        .orderBy('completedAt', descending: true)
        .get();
    return snap.docs.map((d) => RideHistory.fromJson(d.data())).toList();
  }

  @override
  Future<void> saveHistory(RideHistory history) async {
    await _db
        .collection('history')
        .doc(_uid)
        .collection('rides')
        .doc(history.id)
        .set(history.toJson());
  }
}
