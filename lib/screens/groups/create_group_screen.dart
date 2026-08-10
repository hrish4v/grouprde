import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import 'group_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _emoji = '🏍️';
  GroupPrivacy _privacy = GroupPrivacy.private;
  bool _approval = false;
  bool _saving = false;

  static const _emojis = ['🏍️', '🏔️', '🔥', '🦅', '🐺', '🏁', '⚡', '🌄'];

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Give your group a name')));
      return;
    }
    setState(() => _saving = true);
    final g = await context.read<AppState>().createGroup(
          name: _name.text.trim(),
          description: _desc.text.trim(),
          emoji: _emoji,
          privacy: _privacy,
          approvalRequired: _approval,
        );
    if (!mounted) return;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => GroupDetailScreen(groupId: g.id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Group icon',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
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
          TextField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Group name', hintText: 'e.g. Weekend Warriors')),
          const SizedBox(height: 14),
          TextField(
              controller: _desc,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Description (optional)')),
          const SizedBox(height: 20),
          Card(
            child: Column(children: [
              SwitchListTile(
                value: _privacy == GroupPrivacy.private,
                activeColor: AppTheme.primary,
                title: const Text('Private group'),
                subtitle: const Text('Only people with the code can join'),
                onChanged: (v) => setState(() => _privacy =
                    v ? GroupPrivacy.private : GroupPrivacy.public),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _approval,
                activeColor: AppTheme.primary,
                title: const Text('Approval required'),
                subtitle: const Text('Admins approve new members'),
                onChanged: (v) => setState(() => _approval = v),
              ),
            ]),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _saving ? null : _create,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Create group'),
          ),
        ],
      ),
    );
  }
}
