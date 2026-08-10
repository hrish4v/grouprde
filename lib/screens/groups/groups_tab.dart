import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/group.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'join_group_screen.dart';

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final groups = state.myGroups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Join with code',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const JoinGroupScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
        icon: const Icon(Icons.add),
        label: const Text('New group'),
      ),
      body: groups.isEmpty
          ? EmptyState(
              emoji: '👥',
              title: 'No groups yet',
              subtitle:
                  'Create a riding community or join one with an invite code.',
              action: Wrap(
                spacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateGroupScreen())),
                    child: const Text('Create group'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const JoinGroupScreen())),
                    child: const Text('Join with code'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _GroupCard(group: groups[i], state: state),
            ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final RiderGroup group;
  final AppState state;
  const _GroupCard({required this.group, required this.state});

  @override
  Widget build(BuildContext context) {
    final rides = state.ridesForGroup(group.id).length;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => GroupDetailScreen(groupId: group.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              EmojiAvatar(group.imageEmoji, size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      group.description.isEmpty
                          ? '${group.memberCount} members'
                          : group.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      _pill('👥 ${group.memberCount}'),
                      const SizedBox(width: 8),
                      _pill('🏁 $rides rides'),
                      const SizedBox(width: 8),
                      if (group.isAdmin(state.profile!.id)) _pill('👑 Admin'),
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(t, style: const TextStyle(fontSize: 11.5)),
      );
}
