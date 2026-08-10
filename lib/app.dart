import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
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

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.ready) {
      return const Scaffold(
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
    }
    return state.isOnboarded ? const HomeShell() : const OnboardingScreen();
  }
}
