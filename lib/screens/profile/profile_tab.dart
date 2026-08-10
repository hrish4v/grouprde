import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../models/rider_profile.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'edit_profile_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final p = state.profile;
    if (p == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EditProfileScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              EmojiAvatar(p.photoEmoji ?? '🏍️', size: 68),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('🏍️ ${p.bikeModel.isEmpty ? 'Add your bike' : p.bikeModel}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    if (p.phone.isNotEmpty)
                      Text('📞 ${p.phone}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader('Riding stats'),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: [
              StatTile(
                  emoji: '🏁',
                  value: '${p.totalRides}',
                  label: 'Rides'),
              StatTile(
                  emoji: '📍',
                  value: '${p.totalKm.round()}',
                  label: 'km travelled'),
              StatTile(
                  emoji: '🏔️',
                  value: '${p.destinations}',
                  label: 'Destinations'),
              StatTile(
                  emoji: '🛣️',
                  value: '${p.longestRideKm.round()}',
                  label: 'Longest (km)'),
              StatTile(
                  emoji: '👥',
                  value: '${p.groupsJoined}',
                  label: 'Groups'),
              StatTile(
                  emoji: '👑',
                  value: '${p.ridesOrganized}',
                  label: 'Organized'),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader('Badges'),
          _badges(p),
          const SizedBox(height: 20),
          const SectionHeader('Emergency contact'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.emergency_outlined,
                  color: AppTheme.statusDanger),
              title: Text(p.emergencyContactName.isEmpty
                  ? 'Not set'
                  : p.emergencyContactName),
              subtitle: Text(p.emergencyContactPhone.isEmpty
                  ? 'Add a contact for emergencies'
                  : p.emergencyContactPhone),
            ),
          ),
          const SizedBox(height: 20),
          InfoBanner(
            icon: Icons.cloud_off,
            color: AppTheme.accent,
            text: AppConfig.isLocal
                ? 'Running in LOCAL mode — your data lives on this device and '
                    'riding buddies are simulated during rides. Add Firebase '
                    '(see SETUP.md) to ride live with friends.'
                : 'Firebase mode active.',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _badges(RiderProfile p) {
    final badges = <List<String>>[
      if (p.totalRides >= 1) ['🏆', 'First Ride Done'],
      if (p.destinations >= 3) ['🏔️', 'Explorer'],
      if (p.ridesOrganized >= 1) ['👑', 'Ride Organizer'],
      if (p.totalKm >= 500) ['🛣️', 'Long Hauler'],
      ['🛡️', 'Safe Rider'],
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: badges
          .map((b) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(b[0], style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(b[1],
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ))
          .toList(),
    );
  }
}
