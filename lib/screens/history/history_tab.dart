import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'ride_summary_screen.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final history = state.history;
    final totalKm = history.fold<double>(0, (s, h) => s + h.distanceKm);

    return Scaffold(
      appBar: AppBar(title: const Text('Ride history')),
      body: history.isEmpty
          ? const EmptyState(
              emoji: '🗺️',
              title: 'No rides yet',
              subtitle:
                  'Once you complete a ride, its summary and route are saved '
                  'here as a permanent memory.',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                        child: StatTile(
                            emoji: '🏁',
                            value: '${history.length}',
                            label: 'Rides')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: StatTile(
                            emoji: '📍',
                            value: '${totalKm.round()}',
                            label: 'Total km')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: StatTile(
                            emoji: '🏔️',
                            value: '${history.length}',
                            label: 'Trips')),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionHeader('Past rides'),
                ...history.map((h) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    RideSummaryScreen(history: h))),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const EmojiAvatar('🏍️', size: 48),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(h.title,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${h.startName} → ${h.destinationName}',
                                        style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.65),
                                            fontSize: 13)),
                                    const SizedBox(height: 6),
                                    Text(
                                        '📍 ${h.distanceKm.round()} km · ⏱️ ${h.durationLabel} · 👥 ${h.riderCount}  ·  ${DateFormat('d MMM').format(h.completedAt)}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white
                                                .withOpacity(0.5))),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}
