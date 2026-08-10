import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/enums.dart';
import '../../models/ride.dart';
import '../../models/rider_live_state.dart';
import '../../state/app_state.dart';
import '../../state/ride_session.dart';
import '../../widgets/common.dart';
import '../../widgets/map_utils.dart';
import '../history/ride_summary_screen.dart';
import 'quick_actions.dart';

class RideModeScreen extends StatefulWidget {
  final String rideId;
  const RideModeScreen({super.key, required this.rideId});

  @override
  State<RideModeScreen> createState() => _RideModeScreenState();
}

class _RideModeScreenState extends State<RideModeScreen> {
  RideSession? _session;
  Ride? _ride;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final state = context.read<AppState>();
    Ride? ride;
    for (final r in state.rides) {
      if (r.id == widget.rideId) ride = r;
    }
    if (ride == null) return;
    ride.status = RideStatus.active;
    ride.startedAt = DateTime.now();
    await state.saveRide(ride);
    final session = RideSession(
        ride: ride, self: state.profile!, location: state.location);
    session.start();
    setState(() {
      _ride = ride;
      _session = session;
    });
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null || _ride == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ChangeNotifierProvider.value(
      value: _session!,
      child: _RideModeBody(ride: _ride!),
    );
  }
}

class _RideModeBody extends StatefulWidget {
  final Ride ride;
  const _RideModeBody({required this.ride});

  @override
  State<_RideModeBody> createState() => _RideModeBodyState();
}

class _RideModeBodyState extends State<_RideModeBody> {
  GoogleMapController? _map;
  bool _fitted = false;

  Color _healthColor(GroupHealth h) {
    switch (h) {
      case GroupHealth.ok:
        return AppTheme.statusOk;
      case GroupHealth.warn:
        return AppTheme.statusWarn;
      case GroupHealth.danger:
        return AppTheme.statusDanger;
    }
  }

  String _healthLabel(GroupHealth h, int behind) {
    switch (h) {
      case GroupHealth.ok:
        return '🟢 Group OK';
      case GroupHealth.warn:
        return behind > 0
            ? '🟡 $behind rider${behind > 1 ? 's' : ''} falling behind'
            : '🟡 Attention needed';
      case GroupHealth.danger:
        return '🔴 Rider needs assistance';
    }
  }

  double _hueFor(RiderLiveState r) {
    if (r.isSelf) return BitmapDescriptor.hueAzure;
    switch (r.status) {
      case RiderConnectionStatus.behind:
      case RiderConnectionStatus.wrongRoute:
        return BitmapDescriptor.hueRed;
      case RiderConnectionStatus.slow:
      case RiderConnectionStatus.stopped:
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueGreen;
    }
  }

  Future<void> _endRide() async {
    final session = context.read<RideSession>();
    final appState = context.read<AppState>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('End ride?'),
        content: const Text(
            'This finishes the ride, saves a summary to History, and stops '
            'live tracking for everyone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep riding')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusDanger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('End ride')),
        ],
      ),
    );
    if (confirm != true) return;
    final history = session.finish();
    await appState.completeRide(history, widget.ride);
    if (!mounted) return;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => RideSummaryScreen(history: history)));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<RideSession>();
    final riders = session.riders;
    final health = session.health;

    // fit camera once
    if (!_fitted && _map != null && riders.isNotEmpty) {
      _fitted = true;
      final pts = riders.map((r) => r.position).toList()
        ..add(widget.ride.destinationPoint);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _map?.animateCamera(CameraUpdate.newLatLngBounds(boundsOf(pts), 70));
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _endRide();
      },
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                  target: widget.ride.startPoint.latLng, zoom: 9),
              onMapCreated: (c) => _map = c,
              markers: {
                for (final r in riders)
                  Marker(
                    markerId: MarkerId(r.riderId),
                    position: r.position.latLng,
                    icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(r)),
                    infoWindow: InfoWindow(
                        title: '${r.role.emoji} ${r.name}',
                        snippet:
                            '${r.speedKmh.round()} km/h · ${r.status.label}'),
                    rotation: r.headingDeg,
                    flat: true,
                  ),
                Marker(
                    markerId: const MarkerId('dest'),
                    position: widget.ride.destinationPoint.latLng,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueViolet),
                    infoWindow: InfoWindow(
                        title: '🏁 ${widget.ride.destinationName}')),
              },
              polylines: {
                if (widget.ride.routePoints.isNotEmpty)
                  Polyline(
                      polylineId: const PolylineId('route'),
                      points: toLatLngs(widget.ride.routePoints),
                      color: AppTheme.primary.withOpacity(0.7),
                      width: 5),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              padding: const EdgeInsets.only(top: 210, bottom: 220),
            ),

            // top dashboard
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _Dashboard(
                  ride: widget.ride,
                  session: session,
                  healthColor: _healthColor(health),
                  healthLabel: _healthLabel(health, session.ridersBehind),
                  onEnd: _endRide,
                ),
              ),
            ),

            // emergency banner
            if (session.emergencies.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 240,
                child: _EmergencyBanner(session: session),
              ),

            // bottom quick actions
            Align(
              alignment: Alignment.bottomCenter,
              child: QuickActionsBar(session: session),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final Ride ride;
  final RideSession session;
  final Color healthColor;
  final String healthLabel;
  final VoidCallback onEnd;
  const _Dashboard({
    required this.ride,
    required this.session,
    required this.healthColor,
    required this.healthLabel,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final next = session.nextStop;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${ride.startName} → ${ride.destinationName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                        '${session.coveredKm.round()} / ${session.totalKm.round()} km · ${session.elapsedLabel}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onEnd,
                style:
                    TextButton.styleFrom(foregroundColor: AppTheme.statusDanger),
                icon: const Icon(Icons.stop_circle_outlined, size: 20),
                label: const Text('End'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: session.totalKm == 0
                  ? 0.0
                  : (session.coveredKm / session.totalKm).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white12,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: healthColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(healthLabel,
                        style: TextStyle(
                            color: healthColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _stat('${session.activeRiders}', 'active'),
              const SizedBox(width: 10),
              _stat('${session.riders.length}', 'riders'),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(next.type.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Next: ${next.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text('${session.distanceToNextStopKm.round()} km',
                    style: TextStyle(color: Colors.white.withOpacity(0.7))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String v, String l) => Column(
        children: [
          Text(v,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(l,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ],
      );
}

class _EmergencyBanner extends StatelessWidget {
  final RideSession session;
  const _EmergencyBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    final e = session.emergencies.first;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.statusDanger,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🚨', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${e.emergencyType?.label ?? 'Emergency'} — ${e.riderName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.white)),
                if (e.location != null)
                  Text('📍 ${e.location}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => session.resolveRequest(e.id),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }
}
