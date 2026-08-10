import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/enums.dart';
import '../../state/ride_session.dart';

/// The bottom action bar during a ride: one-tap requests, the live request
/// feed, and the big emergency trigger.
class QuickActionsBar extends StatelessWidget {
  final RideSession session;
  const QuickActionsBar({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final requests = session.activeRequests
        .where((r) => r.type != QuickRequestType.emergency)
        .toList();
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 12)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (requests.isNotEmpty) ...[
                _RequestFeed(session: session, requests: requests),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  _action(context, QuickRequestType.breakRequest,
                      AppTheme.statusWarn),
                  _action(context, QuickRequestType.fuel, AppTheme.accent),
                  _action(context, QuickRequestType.food, AppTheme.accent),
                  _action(
                      context, QuickRequestType.bikeIssue, AppTheme.statusWarn),
                  _action(context, QuickRequestType.stop, AppTheme.primary),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.statusDanger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _emergencySheet(context),
                  icon: const Text('🚨', style: TextStyle(fontSize: 18)),
                  label: const Text('EMERGENCY',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(
      BuildContext context, QuickRequestType type, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (type == QuickRequestType.breakRequest) {
              _breakSheet(context);
            } else {
              session.sendRequest(type);
              _toast(context, '${type.emoji} Sent: ${type.label}');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(type.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _breakSheet(BuildContext context) async {
    const reasons = ['Rest', 'Food', 'Water', 'Fuel', 'Bathroom', 'Bike issue'];
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🛑 Request a break',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Everyone in the ride is notified. Pick a reason:',
                style: TextStyle(color: Colors.white.withOpacity(0.6))),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: reasons
                  .map((r) => ActionChip(
                        label: Text(r),
                        backgroundColor: AppTheme.surfaceDark,
                        onPressed: () {
                          session.sendRequest(QuickRequestType.breakRequest,
                              reasonNote: r);
                          Navigator.pop(ctx);
                          _toast(context, '🛑 Break requested ($r)');
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _emergencySheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🚨 Trigger emergency',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.statusDanger)),
            const SizedBox(height: 6),
            Text(
                'Your live location is shared with everyone, nearby riders are '
                'highlighted, and your emergency contact can be alerted.',
                style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 16),
            ...EmergencyType.values.map((t) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('⚠️', style: TextStyle(fontSize: 20)),
                  title: Text(t.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    session.sendRequest(QuickRequestType.emergency,
                        emergencyType: t);
                    Navigator.pop(ctx);
                    _toast(context, '🚨 Emergency broadcast: ${t.label}');
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _RequestFeed extends StatelessWidget {
  final RideSession session;
  final List requests;
  const _RequestFeed({required this.session, required this.requests});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 96),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: requests.length,
        itemBuilder: (_, i) {
          final r = requests[i];
          return ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -3),
            leading: Text(r.type.emoji, style: const TextStyle(fontSize: 18)),
            title: Text(r.message, style: const TextStyle(fontSize: 13)),
            trailing: IconButton(
              icon: const Icon(Icons.check, size: 18),
              onPressed: () => session.resolveRequest(r.id),
            ),
          );
        },
      ),
    );
  }
}
