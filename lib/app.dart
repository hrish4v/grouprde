import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'services/debug_log.dart';
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

Widget _splash() => Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏍️', style: TextStyle(fontSize: 64)),
                    SizedBox(height: 16),
                    Text(AppConfig.appName,
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text('build: ${AppConfig.buildTag}',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(height: 24),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
            const _DebugPanel(),
          ],
        ),
      ),
    );

/// Shows the live in-app log at the bottom of the loading screen so we can see
/// exactly where startup stalls.
class _DebugPanel extends StatelessWidget {
  const _DebugPanel();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: DebugLog.tick,
      builder: (context, _, __) {
        final lines = DebugLog.lines;
        return Container(
          width: double.infinity,
          height: 200,
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24),
          ),
          child: ListView(
            reverse: true,
            children: [
              for (final line in lines.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(line,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF7CFC7C))),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  // Create the auth stream ONCE and keep it stable. Recreating it on every
  // rebuild caused the loading loop (StreamBuilder re-subscribed → the authed
  // subtree was torn down and reloaded endlessly).
  Stream<User?>? _authStream;

  @override
  void initState() {
    super.initState();
    if (AppConfig.isFirebase) {
      _authStream = FirebaseAuth.instance.authStateChanges();
    }
  }

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
      stream: _authStream,
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
    try {
      await context.read<AppState>().ensureLoaded(widget.uid);
    } catch (_) {
      // ensureLoaded already captures errors; never let this hang the UI.
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!_loaded) return _splash();

    // If the profile load failed (e.g. Firestore unreachable), show the error
    // rather than freezing — with a retry.
    if (state.lastError != null && !state.isOnboarded) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text('Couldn’t load your data',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(state.lastError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    state.clearError();
                    setState(() => _loaded = false);
                    _load();
                  },
                  child: const Text('Try again'),
                ),
                TextButton(
                  onPressed: () {
                    state.clearError();
                    setState(() {});
                  },
                  child: const Text('Continue to profile setup'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return state.isOnboarded ? const HomeShell() : const OnboardingScreen();
  }
}
