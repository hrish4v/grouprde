import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../state/app_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bike;
  late final TextEditingController _phone;
  late final TextEditingController _emName;
  late final TextEditingController _emPhone;
  late final TextEditingController _bio;
  late double _speed;
  late String _emoji;

  static const _emojis = ['🏍️', '🛵', '🏁', '👑', '🦅', '🐺', '🔥', '⚡'];

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile!;
    _name = TextEditingController(text: p.name);
    _bike = TextEditingController(text: p.bikeModel);
    _phone = TextEditingController(text: p.phone);
    _emName = TextEditingController(text: p.emergencyContactName);
    _emPhone = TextEditingController(text: p.emergencyContactPhone);
    _bio = TextEditingController(text: p.bio);
    _speed = p.preferredSpeed.toDouble();
    _emoji = p.photoEmoji ?? '🏍️';
  }

  @override
  void dispose() {
    _name.dispose();
    _bike.dispose();
    _phone.dispose();
    _emName.dispose();
    _emPhone.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final p = state.profile!;
    p
      ..name = _name.text.trim()
      ..bikeModel = _bike.text.trim()
      ..phone = _phone.text.trim()
      ..emergencyContactName = _emName.text.trim()
      ..emergencyContactPhone = _emPhone.text.trim()
      ..bio = _bio.text.trim()
      ..preferredSpeed = _speed.round()
      ..photoEmoji = _emoji;
    await state.updateProfile(p);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile'), actions: [
        TextButton(onPressed: _save, child: const Text('Save')),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  child: Text(e, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _f(_name, 'Name'),
          const SizedBox(height: 14),
          _f(_bike, 'Bike model'),
          const SizedBox(height: 14),
          _f(_phone, 'Phone', keyboard: TextInputType.phone),
          const SizedBox(height: 14),
          _f(_bio, 'Bio', maxLines: 2),
          const SizedBox(height: 20),
          Text('Preferred speed: ${_speed.round()} km/h',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _speed,
            min: 30,
            max: 120,
            divisions: 18,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _speed = v),
          ),
          const SizedBox(height: 8),
          _f(_emName, 'Emergency contact name'),
          const SizedBox(height: 14),
          _f(_emPhone, 'Emergency contact phone',
              keyboard: TextInputType.phone),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _save, child: const Text('Save changes')),
        ],
      ),
    );
  }

  Widget _f(TextEditingController c, String label,
      {TextInputType? keyboard, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}
