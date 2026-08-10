import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/breakpoint.dart';
import '../../models/enums.dart';
import '../../models/ride.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/map_utils.dart';
import '../ride_mode/ride_mode_screen.dart';

class RideDetailScreen extends StatelessWidget {
  final String rideId;
  const RideDetailScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    Ride? ride;
    for (final r in state.rides) {
      if (r.id == rideId) ride = r;
    }
    if (ride == null) {
      return const Scaffold(body: Center(child: Text('Ride not found')));
    }
    final r = ride;
    final stops = r.orderedStops;

    return Scaffold(
      appBar: AppBar(
        title: Text(r.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                await context.read<AppState>().deleteRide(r.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete ride')),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 240,
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: r.startPoint.latLng, zoom: 7),
              onMapCreated: (c) async {
                await Future.delayed(const Duration(milliseconds: 300));
                final pts = [
                  r.startPoint,
                  r.destinationPoint,
                  ...r.breakpoints.map((b) => b.location)
                ];
                if (pts.length >= 2) {
                  c.animateCamera(
                      CameraUpdate.newLatLngBounds(boundsOf(pts), 50));
                }
              },
              markers: {
                Marker(
                    markerId: const MarkerId('s'),
                    position: r.startPoint.latLng,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen)),
                Marker(
                    markerId: const MarkerId('d'),
                    position: r.destinationPoint.latLng,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed)),
                ...r.breakpoints.map((b) => Marker(
                    markerId: MarkerId(b.id),
                    position: b.location.latLng,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange))),
              },
              polylines: {
                if (r.routePoints.isNotEmpty)
                  Polyline(
                      polylineId: const PolylineId('r'),
                      points: toLatLngs(r.routePoints),
                      color: AppTheme.primary,
                      width: 5),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: StatTile(
                            value: '${r.plannedDistanceKm.round()} km',
                            label: 'Distance',
                            emoji: '📍')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: StatTile(
                            value:
                                '${r.plannedDurationMin ~/ 60}h ${r.plannedDurationMin % 60}m',
                            label: 'Est. time',
                            emoji: '⏱️')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: StatTile(
                            value: r.routeType.split('-').first,
                            label: 'Route',
                            emoji: '🛣️')),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionHeader('Route & stops'),
                _timeline(stops),
                const SizedBox(height: 20),
                const SectionHeader('Roles'),
                Card(
                  child: Column(children: [
                    ListTile(
                      leading: const Text('👑', style: TextStyle(fontSize: 22)),
                      title: const Text('Ride Leader'),
                      subtitle: Text(r.leaderId == state.profile!.id
                          ? '${state.profile!.name} (you)'
                          : 'Assigned'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Text('🛡️', style: TextStyle(fontSize: 22)),
                      title: const Text('Sweep Rider'),
                      subtitle: Text(r.sweepId == null
                          ? 'Not assigned'
                          : 'Stays at the back'),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                if (r.status == RideStatus.completed)
                  const InfoBanner(
                      icon: Icons.check_circle_outline,
                      color: AppTheme.statusOk,
                      text: 'This ride is completed. See it in History.')
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.statusOk,
                          padding: const EdgeInsets.symmetric(vertical: 18)),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  RideModeScreen(rideId: r.id))),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start ride',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(List<Breakpoint> stops) {
    return Column(
      children: [
        for (var i = 0; i < stops.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.5)),
                      ),
                      child: Text(stops[i].type.emoji,
                          style: const TextStyle(fontSize: 16)),
                    ),
                    if (i != stops.length - 1)
                      Expanded(
                        child: Container(
                            width: 2,
                            color: Colors.white24,
                            margin: const EdgeInsets.symmetric(vertical: 2)),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stops[i].name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        Text(
                          '${stops[i].type.label} · ${stops[i].distanceFromStartKm.round()} km from start',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withOpacity(0.6)),
                        ),
                        if (stops[i].notes.isNotEmpty)
                          Text(stops[i].notes,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
