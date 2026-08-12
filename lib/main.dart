import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'services/debug_log.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DebugLog.add('main start (build ${AppConfig.buildTag})');

  if (AppConfig.isFirebase) {
    try {
      DebugLog.add('Firebase.initializeApp…');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      DebugLog.add('Firebase init OK');
      FirebaseAuth.instance.authStateChanges().listen((u) {
        DebugLog.add(u == null
            ? 'authState: signed OUT'
            : 'authState: signed IN (${u.uid.substring(0, 6)}…)');
      });
    } catch (e) {
      DebugLog.add('Firebase init FAILED: $e');
    }
  }

  final appState = AppState();
  appState.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const GroupRideApp(),
    ),
  );
}
