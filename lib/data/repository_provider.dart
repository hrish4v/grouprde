import '../config/app_config.dart';
import 'firebase_repository.dart';
import 'local_repository.dart';
import 'repository.dart';

/// Returns the active [Repository] implementation for the configured backend.
/// LOCAL  -> on-device storage (offline demo).
/// FIREBASE -> Firestore, shared across all signed-in riders.
Repository createRepository() {
  switch (AppConfig.backend) {
    case BackendMode.local:
      return LocalRepository();
    case BackendMode.firebase:
      return FirebaseRepository();
  }
}
