import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'group_detail_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    final g = await context.read<AppState>().joinGroupByCode(code);
    setState(() => _busy = false);
    if (!mounted) return;
    if (g == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No group found for that code')));
      return;
    }
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => GroupDetailScreen(groupId: g.id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a group')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),
          const Center(child: Text('🔗', style: TextStyle(fontSize: 52))),
          const SizedBox(height: 16),
          const Center(
            child: Text('Enter invite code',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 4),
            decoration: const InputDecoration(hintText: 'CODE'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : _join,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Join group'),
          ),
          const SizedBox(height: 24),
          const InfoBanner(
            text:
                'Tip: the seeded demo group "Weekend Warriors" uses the code '
                'RIDE42. A real QR scanner slots in here once you go live.',
          ),
        ],
      ),
    );
  }
}
