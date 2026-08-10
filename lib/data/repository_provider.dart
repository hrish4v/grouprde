import '../config/app_config.dart';
import 'local_repository.dart';
import 'repository.dart';

/// Returns the active [Repository] implementation for the configured backend.
///
/// Today this returns [LocalRepository]. To go live with Firebase:
///   1. Follow SETUP.md (add firebase deps + google-services.json).
///   2. Add a FirebaseRepository (reference impl in
///      docs/firebase_repository.dart.reference) to lib/data/.
///   3. Set AppConfig.backend = BackendMode.firebase.
///   4. Return FirebaseRepository() from the firebase branch below.
Repository createRepository() {
  switch (AppConfig.backend) {
    case BackendMode.local:
      return LocalRepository();
    case BackendMode.firebase:
      // return FirebaseRepository();  // enable after SETUP.md
      return LocalRepository();
  }
}
