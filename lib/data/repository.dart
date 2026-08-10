import '../models/group.dart';
import '../models/ride.dart';
import '../models/ride_history.dart';
import '../models/rider_profile.dart';

/// Persistent data contract for GroupRide.
///
/// [LocalRepository] implements this on-device (SharedPreferences + JSON).
/// A Firebase implementation (Auth + Firestore) can implement the same surface
/// — see SETUP.md and docs/firebase_repository.dart.reference for the drop-in.
abstract class Repository {
  Future<void> init();

  // ---- Profile ----
  Future<RiderProfile?> getProfile();
  Future<void> saveProfile(RiderProfile profile);

  // ---- Groups ----
  Future<List<RiderGroup>> getGroups();
  Future<RiderGroup?> getGroup(String id);
  Future<void> saveGroup(RiderGroup group);
  Future<void> deleteGroup(String id);

  /// Returns the group matching a join code, or null.
  Future<RiderGroup?> findGroupByCode(String code);

  // ---- Rides ----
  Future<List<Ride>> getRides({String? groupId});
  Future<Ride?> getRide(String id);
  Future<void> saveRide(Ride ride);
  Future<void> deleteRide(String id);

  // ---- History ----
  Future<List<RideHistory>> getHistory();
  Future<void> saveHistory(RideHistory history);
}
