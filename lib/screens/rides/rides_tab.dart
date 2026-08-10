import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/enums.dart';
import '../../models/ride.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../groups/groups_tab.dart';
import 'ride_detail_screen.dart';

class RidesTab extends StatelessWidget {
  const RidesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final myGroupIds = state.myGroups.map((g) => g.id).toSet();
    final rides = state.rides
        .where((r) =>
            myGroupIds.contains(r.groupId) &&
            r.status != RideStatus.completed)
        .toList()
      ..sort((a, b) => (a.plannedStart ?? DateTime(2100))
          .compareTo(b.plannedStart ?? DateTime(2100)));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hey ${state.profile?.name.split(' ').first ?? 'rider'} 👋',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            Text('Ready to ride?',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.6))),
          ],
        ),
      ),
      body: rides.isEmpty
          ? EmptyState(
              emoji: '🏍️',
              title: 'No rides planned',
              subtitle:
                  'Head to a group and plan your next trip. Your upcoming '
                  'rides show up here.',
              action: ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GroupsTab())),
                child: const Text('Go to groups'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final r in rides) _RideCard(ride: r, state: state),
              ],
            ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Ride ride;
  final AppState state;
  const _RideCard({required this.ride, required this.state});

  @override
  Widget build(BuildContext context) {
    final group = state.groups.firstWhere((g) => g.id == ride.groupId,
        orElse: () => state.groups.first);
    final isLive = ride.status == RideStatus.active;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => RideDetailScreen(rideId: ride.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(ride.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  if (isLive)
                    const StatusPill(text: 'LIVE', color: AppTheme.statusOk)
                  else
                    StatusPill(
                        text: ride.routeType.split('-').first,
                        color: AppTheme.accent),
                ],
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.place_outlined, size: 15),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('${ride.startName} → ${ride.destinationName}',
                      style: TextStyle(color: Colors.white.withOpacity(0.75))),
                ),
              ]),
              const SizedBox(height: 4),
              Text('👥 ${group.name}',
                  style: TextStyle(
                      fontSize: 12.5, color: Colors.white.withOpacity(0.55))),
              const SizedBox(height: 14),
              Row(
                children: [
                  _mini('📍 ${ride.plannedDistanceKm.round()} km'),
                  const SizedBox(width: 10),
                  _mini(
                      '⏱️ ${ride.plannedDurationMin ~/ 60}h ${ride.plannedDurationMin % 60}m'),
                  const SizedBox(width: 10),
                  _mini('🛑 ${ride.breakpoints.length} stops'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mini(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(t, style: const TextStyle(fontSize: 12)),
      );
}
