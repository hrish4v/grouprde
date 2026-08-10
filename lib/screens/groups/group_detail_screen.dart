import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/theme.dart';
import '../../models/enums.dart';
import '../../models/group.dart';
import '../../models/ride.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../rides/create_ride_screen.dart';
import '../rides/ride_detail_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    RiderGroup? group;
    for (final g in state.groups) {
      if (g.id == groupId) group = g;
    }
    if (group == null) {
      return const Scaffold(body: Center(child: Text('Group not found')));
    }
    final g = group;
    final rides = state.ridesForGroup(g.id)
      ..sort((a, b) => (b.plannedStart ?? b.createdAtFallback)
          .compareTo(a.plannedStart ?? a.createdAtFallback));
    final isAdmin = g.isAdmin(state.profile!.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'invite') _showInvite(context, g);
              if (v == 'leave') {
                await context.read<AppState>().leaveGroup(g.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'invite', child: Text('Invite / QR')),
              const PopupMenuItem(value: 'leave', child: Text('Leave group')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CreateRideScreen(groupId: g.id))),
        icon: const Icon(Icons.add_road),
        label: const Text('Plan ride'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              EmojiAvatar(g.imageEmoji, size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.description.isEmpty ? g.name : g.description,
                        style: TextStyle(color: Colors.white.withOpacity(0.8))),
                    const SizedBox(height: 8),
                    Row(children: [
                      StatusPill(
                          text: g.privacy == GroupPrivacy.private
                              ? 'Private'
                              : 'Public',
                          color: AppTheme.accent,
                          icon: g.privacy == GroupPrivacy.private
                              ? Icons.lock_outline
                              : Icons.public),
                      const SizedBox(width: 8),
                      if (isAdmin)
                        const StatusPill(
                            text: 'Admin',
                            color: AppTheme.primary,
                            icon: Icons.star_outline),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showInvite(context, g),
            icon: const Icon(Icons.qr_code_2),
            label: Text('Invite code:  ${g.joinCode}'),
          ),
          const SizedBox(height: 20),
          const SectionHeader('Planned rides'),
          if (rides.where((r) => r.status != RideStatus.completed).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No rides planned yet. Tap "Plan ride" to start.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6))),
            )
          else
            ...rides
                .where((r) => r.status != RideStatus.completed)
                .map((r) => _RideRow(ride: r)),
          const SizedBox(height: 20),
          SectionHeader('Members (${g.memberCount})'),
          ...g.memberIds.map((mid) => _memberTile(context, state, g, mid)),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _memberTile(
      BuildContext context, AppState state, RiderGroup g, String mid) {
    final isSelf = mid == state.profile!.id;
    final name = isSelf
        ? '${state.profile!.name} (you)'
        : _buddyName(mid);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: EmojiAvatar(isSelf ? (state.profile!.photoEmoji ?? '🏍️') : '🏍️',
            size: 40),
        title: Text(name),
        subtitle: Text(g.adminIds.contains(mid) ? '👑 Admin' : 'Rider'),
      ),
    );
  }

  String _buddyName(String id) {
    const names = {
      'buddy_0': 'Rahul',
      'buddy_1': 'Ananya',
      'buddy_2': 'Vikram',
      'buddy_3': 'Meera',
    };
    return names[id] ?? 'Rider';
  }

  void _showInvite(BuildContext context, RiderGroup g) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Invite to ${g.name}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: QrImageView(
                data: 'grouprde://join/${g.joinCode}',
                size: 200,
              ),
            ),
            const SizedBox(height: 20),
            SelectableText(g.joinCode,
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6)),
            const SizedBox(height: 8),
            Text('Share this code or QR with riders to join.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

class _RideRow extends StatelessWidget {
  final Ride ride;
  const _RideRow({required this.ride});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => RideDetailScreen(rideId: ride.id))),
        leading: const EmojiAvatar('🏁', size: 42),
        title: Text(ride.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '${ride.startName} → ${ride.destinationName}  ·  ${ride.plannedDistanceKm.round()} km'),
        trailing: ride.status == RideStatus.active
            ? const StatusPill(text: 'LIVE', color: AppTheme.statusOk)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

extension on Ride {
  DateTime get createdAtFallback => startedAt ?? DateTime(2020);
}
