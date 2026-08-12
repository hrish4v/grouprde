import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/ride_history.dart';
import '../../widgets/common.dart';
import '../../widgets/map_utils.dart';

class RideSummaryScreen extends StatelessWidget {
  final RideHistory history;
  final bool justFinished;
  const RideSummaryScreen(
      {super.key, required this.history, this.justFinished = false});

  @override
  Widget build(BuildContext context) {
    final h = history;
    return Scaffold(
      appBar: AppBar(
        title: Text(justFinished ? 'Ride complete 🎉' : h.title),
        leading: justFinished
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context)
                    .popUntil((route) => route.isFirst))
            : null,
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 220,
            child: h.actualRoute.length < 2
                ? Container(
                    color: AppTheme.cardDark,
                    child: const Center(child: Text('No route recorded')))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                        target: h.actualRoute.first.latLng, zoom: 8),
                    style: kLightMapStyle,
                    onMapCreated: (c) async {
                      await Future.delayed(const Duration(milliseconds: 300));
                      c.animateCamera(CameraUpdate.newLatLngBounds(
                          boundsOf(h.actualRoute), 50));
                    },
                    markers: {
                      Marker(
                          markerId: const MarkerId('s'),
                          position: h.actualRoute.first.latLng,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen)),
                      Marker(
                          markerId: const MarkerId('e'),
                          position: h.actualRoute.last.latLng,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed)),
                    },
                    polylines: {
                      Polyline(
                          polylineId: const PolylineId('r'),
                          points: toLatLngs(h.actualRoute),
                          color: AppTheme.primary,
                          width: 7),
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
                Text('${h.startName} → ${h.destinationName}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                Text(DateFormat('EEE, d MMM yyyy · h:mm a').format(h.completedAt),
                    style: TextStyle(color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                  children: [
                    StatTile(
                        emoji: '📍',
                        value: '${h.distanceKm.round()}',
                        label: 'km'),
                    StatTile(
                        emoji: '⏱️', value: h.durationLabel, label: 'duration'),
                    StatTile(
                        emoji: '👥',
                        value: '${h.riderCount}',
                        label: 'riders'),
                    StatTile(
                        emoji: '🛑',
                        value: '${h.breakpointCount}',
                        label: 'stops'),
                    StatTile(
                        emoji: '📊',
                        value: '${h.avgSpeedKmh.round()}',
                        label: 'avg km/h'),
                    StatTile(
                        emoji: '⚡',
                        value: '${h.maxSpeedKmh.round()}',
                        label: 'max km/h'),
                  ],
                ),
                const SizedBox(height: 22),
                const SectionHeader('Ride memories'),
                Wrap(
                  spacing: 10,
                  children: h.photoEmojis
                      .map((e) => Container(
                            width: 58,
                            height: 58,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                Text(e, style: const TextStyle(fontSize: 26)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 22),
                const SectionHeader('Timeline'),
                ...h.timeline.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4, right: 10),
                            child: Icon(Icons.circle,
                                size: 8, color: AppTheme.primary),
                          ),
                          Expanded(child: Text(t)),
                        ],
                      ),
                    )),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
