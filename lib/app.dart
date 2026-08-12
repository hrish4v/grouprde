import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/home/home_shell.dart';
import 'state/app_state.dart';

class GroupRideApp extends StatelessWidget {
  const GroupRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _Gate(),
    );
  }
}

Widget _splash() => const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏍️', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(AppConfig.appName,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.ready) return _splash();

    // LOCAL mode: no auth, straight to profile/home.
    if (AppConfig.isLocal) {
      return state.isOnboarded ? const HomeShell() : const OnboardingScreen();
    }

    // FIREBASE mode: gate on auth state.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _splash();
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return _AuthedGate(uid: user.uid);
      },
    );
  }
}

/// After sign-in: load this user's profile + data, then route to onboarding
/// (first time) or home.
class _AuthedGate extends StatefulWidget {
  final String uid;
  const _AuthedGate({required this.uid});

  @override
  State<_AuthedGate> createState() => _AuthedGateState();
}

class _AuthedGateState extends State<_AuthedGate> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_AuthedGate old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid) {
      _loaded = false;
      _load();
    }
  }

  Future<void> _load() async {
    await context.read<AppState>().ensureLoaded(widget.uid);
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!_loaded) return _splash();
    return state.isOnboarded ? const HomeShell() : const OnboardingScreen();
  }
}
