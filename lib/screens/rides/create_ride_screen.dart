import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/breakpoint.dart';
import '../../models/enums.dart';
import '../../models/geo.dart';
import '../../models/ride.dart';
import '../../services/demo_seed.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/map_utils.dart';
import 'ride_detail_screen.dart';

enum _PlaceMode { start, destination, breakpoint }

/// Preset locations so a ride can be planned without a Places API key.
const _presets = <String, GeoPoint>{
  'Bangalore': GeoPoint(12.9716, 77.5946),
  'Coorg': GeoPoint(12.3375, 75.8069),
  'Mysore': GeoPoint(12.2958, 76.6394),
  'Chikmagalur': GeoPoint(13.3161, 75.7720),
  'Ooty': GeoPoint(11.4064, 76.6932),
  'Gokarna': GeoPoint(14.5479, 74.3188),
};

class CreateRideScreen extends StatefulWidget {
  final String groupId;
  const CreateRideScreen({super.key, required this.groupId});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _title = TextEditingController();
  GoogleMapController? _map;

  _PlaceMode _mode = _PlaceMode.start;
  String _routeType = 'Motorcycle-friendly';

  String _startName = '';
  GeoPoint? _start;
  String _destName = '';
  GeoPoint? _dest;
  final List<Breakpoint> _breaks = [];
  List<GeoPoint> _route = [];
  double _distanceKm = 0;

  static const _routeTypes = [
    'Fastest',
    'Shortest',
    'Scenic',
    'Motorcycle-friendly'
  ];

  @override
  void dispose() {
    _title.dispose();
    _map?.dispose();
    super.dispose();
  }

  void _onTap(LatLng ll) {
    final p = ll.geo;
    setState(() {
      switch (_mode) {
        case _PlaceMode.start:
          _start = p;
          _startName = _startName.isEmpty ? 'Start point' : _startName;
          break;
        case _PlaceMode.destination:
          _dest = p;
          _destName = _destName.isEmpty ? 'Destination' : _destName;
          break;
        case _PlaceMode.breakpoint:
          _addBreakpointDialog(p);
          return;
      }
      _recomputeRoute();
    });
  }

  void _applyPreset(String name, GeoPoint p) {
    setState(() {
      if (_mode == _PlaceMode.start ||
          (_start == null && _mode != _PlaceMode.breakpoint)) {
        _start = p;
        _startName = name;
      } else {
        _dest = p;
        _destName = name;
      }
      _recomputeRoute();
    });
    _fit();
  }

  void _recomputeRoute() {
    if (_start != null && _dest != null) {
      _route = DemoSeed.lerpRoute(_start!, _dest!, 24);
      double d = 0;
      for (var i = 1; i < _route.length; i++) {
        d += _route[i - 1].distanceKm(_route[i]);
      }
      _distanceKm = d;
      for (final b in _breaks) {
        b.distanceFromStartKm = _start!.distanceKm(b.location);
      }
      _breaks.sort(
          (a, b) => a.distanceFromStartKm.compareTo(b.distanceFromStartKm));
    }
  }

  Future<void> _fit() async {
    if (_map == null) return;
    final pts = [
      if (_start != null) _start!,
      if (_dest != null) _dest!,
      ..._breaks.map((b) => b.location),
    ];
    if (pts.length < 2) return;
    await _map!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsOf(pts), 60));
  }

  Future<void> _addBreakpointDialog(GeoPoint p) async {
    BreakpointType type = BreakpointType.fuel;
    final nameCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('Add stop'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BreakpointType.values
                    .where((t) =>
                        t != BreakpointType.start &&
                        t != BreakpointType.destination)
                    .map((t) {
                  final sel = t == type;
                  return GestureDetector(
                    onTap: () => setD(() => type = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.primary.withOpacity(0.25)
                            : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                sel ? AppTheme.primary : Colors.transparent),
                      ),
                      child: Text('${t.emoji} ${t.label}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Name (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add')),
          ],
        ),
      ),
    );
    if (result == true) {
      setState(() {
        _breaks.add(Breakpoint(
          id: context.read<AppState>().newId(),
          type: type,
          name: nameCtrl.text.trim().isEmpty
              ? type.label
              : nameCtrl.text.trim(),
          location: p,
        ));
        _recomputeRoute();
      });
    }
  }

  Set<Marker> _markers() {
    final m = <Marker>{};
    if (_start != null) {
      m.add(Marker(
        markerId: const MarkerId('start'),
        position: _start!.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Start: $_startName'),
      ));
    }
    if (_dest != null) {
      m.add(Marker(
        markerId: const MarkerId('dest'),
        position: _dest!.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destination: $_destName'),
      ));
    }
    for (final b in _breaks) {
      m.add(Marker(
        markerId: MarkerId(b.id),
        position: b.location.latLng,
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: '${b.type.emoji} ${b.name}'),
      ));
    }
    return m;
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _start == null || _dest == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add a title, a start and a destination')));
      return;
    }
    final state = context.read<AppState>();
    final ride = Ride(
      id: state.newId(),
      groupId: widget.groupId,
      title: _title.text.trim(),
      startName: _startName,
      startPoint: _start!,
      destinationName: _destName,
      destinationPoint: _dest!,
      routeType: _routeType,
      plannedDistanceKm: double.parse(_distanceKm.toStringAsFixed(1)),
      plannedDurationMin: (_distanceKm / 55 * 60).round(),
      organizerId: state.profile!.id,
      leaderId: state.profile!.id,
      participantIds: [state.profile!.id],
      breakpoints: _breaks,
      routePoints: _route,
    );
    await state.saveRide(ride);
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => RideDetailScreen(rideId: ride.id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan a ride'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Ride title', hintText: 'e.g. Coorg Monsoon Run'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _modeChip('🚩 Start', _PlaceMode.start),
                const SizedBox(width: 8),
                _modeChip('🏁 End', _PlaceMode.destination),
                const SizedBox(width: 8),
                _modeChip('📍 Stop', _PlaceMode.breakpoint),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                      target: LatLng(12.9716, 77.5946), zoom: 7),
                  onMapCreated: (c) => _map = c,
                  onTap: _onTap,
                  markers: _markers(),
                  polylines: _route.isEmpty
                      ? {}
                      : {
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: toLatLngs(_route),
                            color: AppTheme.primary,
                            width: 5,
                          )
                        },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _presets.entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  label: Text(e.key),
                                  backgroundColor:
                                      AppTheme.cardDark.withOpacity(0.95),
                                  onPressed: () =>
                                      _applyPreset(e.key, e.value),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _panel(),
        ],
      ),
    );
  }

  Widget _modeChip(String label, _PlaceMode mode) {
    final sel = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppTheme.primary : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : Colors.white70,
                  fontSize: 13)),
        ),
      ),
    );
  }

  Widget _panel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 210),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_start != null && _dest != null)
            Row(
              children: [
                Expanded(
                    child: StatTile(
                        value: '${_distanceKm.round()} km',
                        label: 'Distance')),
                const SizedBox(width: 10),
                Expanded(
                    child: StatTile(
                        value:
                            '${((_distanceKm / 55 * 60) / 60).floor()}h ${((_distanceKm / 55 * 60) % 60).round()}m',
                        label: 'Est. time')),
                const SizedBox(width: 10),
                Expanded(
                    child: StatTile(
                        value: '${_breaks.length}', label: 'Stops')),
              ],
            )
          else
            const InfoBanner(
                text:
                    'Pick a preset or tap the map to set Start and End. Map '
                    'tiles stay grey until a Google Maps API key is added — '
                    'placing points still works.'),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _routeTypes.map((t) {
                final sel = t == _routeType;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: sel,
                    selectedColor: AppTheme.primary,
                    onSelected: (_) => setState(() => _routeType = t),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
