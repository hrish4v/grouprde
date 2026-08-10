import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../state/app_state.dart';

/// First-run rider profile creation. (Firebase Auth slots in here later — this
/// screen becomes the post-sign-in "complete your profile" step.)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bike = TextEditingController();
  final _phone = TextEditingController();
  final _emName = TextEditingController();
  final _emPhone = TextEditingController();
  double _speed = 60;
  String _emoji = '🏍️';
  bool _saving = false;

  static const _emojis = ['🏍️', '🛵', '🏁', '👑', '🦅', '🐺', '🔥', '⚡'];

  @override
  void dispose() {
    _name.dispose();
    _bike.dispose();
    _phone.dispose();
    _emName.dispose();
    _emPhone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<AppState>().createProfile(
          name: _name.text.trim(),
          bikeModel: _bike.text.trim(),
          phone: _phone.text.trim(),
          preferredSpeed: _speed.round(),
          emergencyName: _emName.text.trim(),
          emergencyPhone: _emPhone.text.trim(),
          emoji: _emoji,
        );
    // Gate rebuilds automatically via provider.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 12),
              const Text('🏍️', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text('Welcome to GroupRide',
                  style:
                      TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(AppConfig.tagline,
                  style: TextStyle(color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 24),
              _label('Choose your avatar'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _emojis.map((e) {
                  final sel = e == _emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.primary.withOpacity(0.25)
                            : AppTheme.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: sel ? AppTheme.primary : Colors.transparent,
                            width: 2),
                      ),
                      child:
                          Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _field(_name, 'Name', 'e.g. Hrishav Raj',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 14),
              _field(_bike, 'Bike model', 'e.g. KTM RC 457',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null),
              const SizedBox(height: 14),
              _field(_phone, 'Phone (optional)', '+91…',
                  keyboard: TextInputType.phone),
              const SizedBox(height: 20),
              _label('Preferred cruising speed: ${_speed.round()} km/h'),
              Slider(
                value: _speed,
                min: 30,
                max: 120,
                divisions: 18,
                activeColor: AppTheme.primary,
                label: '${_speed.round()}',
                onChanged: (v) => setState(() => _speed = v),
              ),
              const SizedBox(height: 8),
              _label('Emergency contact'),
              const SizedBox(height: 8),
              _field(_emName, 'Contact name', 'e.g. Dad'),
              const SizedBox(height: 14),
              _field(_emPhone, 'Contact phone', '+91…',
                  keyboard: TextInputType.phone),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Create rider profile'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(
          fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8)));

  Widget _field(TextEditingController c, String label, String hint,
      {String? Function(String?)? validator, TextInputType? keyboard}) {
    return TextFormField(
      controller: c,
      validator: validator,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
