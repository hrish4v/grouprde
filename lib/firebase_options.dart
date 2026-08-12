import 'package:firebase_core/firebase_core.dart';

/// Firebase config for GroupRide (project: groupride-a8417).
///
/// Hand-authored from google-services.json. Using explicit [FirebaseOptions]
/// with initializeApp() means we do NOT need the google-services Gradle plugin
/// or a bundled google-services.json — which keeps the Android build simple.
///
/// These values (API key, app id) are safe to ship in the app — they are not
/// secrets; access is controlled by Firebase Security Rules, not by hiding them.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBrDn_uGBARCHJodWfxLmnL0YybY-pHRHc',
    appId: '1:250525914243:android:f0b65923218c134c50f7b6',
    messagingSenderId: '250525914243',
    projectId: 'groupride-a8417',
    storageBucket: 'groupride-a8417.firebasestorage.app',
  );
}
