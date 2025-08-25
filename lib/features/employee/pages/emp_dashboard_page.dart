import 'dart:async';
import 'package:attendex_app/core/http_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import '../api/employee_api.dart';
import '../utils/location_util.dart';
import '../../../core/http_error.dart';

class EmpDashboardPage extends StatefulWidget {
  const EmpDashboardPage({super.key});
  @override
  State<EmpDashboardPage> createState() => _EmpDashboardPageState();
}

class _EmpDashboardPageState extends State<EmpDashboardPage> {
  final _api = EmployeeApi();
  final _map = MapController();
  LatLng? _me, _zoneCenter;
  String? _zoneId, _shiftId;
  double _zoneRadiusM = 300;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final pos = await LocationUtil.current();
      _me = LatLng(pos.latitude, pos.longitude);
      final zones = await _api.listZones();
      final shifts = await _api.listShifts();
      print('zones: $zones');
      print('shifts: $shifts');
      // ...inside _init()...
      if (zones.isNotEmpty) {
        final z = zones.first;
        if (z['id'] != null && z['id'] != 'null') {
          _zoneId = z['id'];
          final coords = (z['center']['coordinates'] as List); // [lng,lat]
          _zoneCenter = LatLng(
            (coords[1] as num).toDouble(),
            (coords[0] as num).toDouble(),
          );
          _zoneRadiusM = ((z['radiusMeters'] as num?)?.toDouble()) ?? 30.0;
        }
      }
      if (shifts.isNotEmpty && shifts.first['id'] != 'null') {
        _shiftId = shifts.first['id'];
      }
      // ...inside _init()...
      setState(() => _loading = false);

      // Center map on your location (_me) with a reasonable zoom (e.g., 14)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_me != null) {
          _map.move(_me!, 14);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(prettyDioError(e))));
    }
  }

  Future<void> _doCheckIn() async {
    if (_me == null || _zoneId == null || _shiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zone/shift or location not ready')),
      );
      return;
    }
    // 👇 ADD THIS LINE (use debugPrint to avoid truncation)
    debugPrint(
      'check-in payload => '
      '{"zoneId":"$_zoneId","shiftId":"$_shiftId","lat":${_me!.latitude},"lng":${_me!.longitude}}',
    );

    try {
      final r = await _api.checkIn(
        zoneId: _zoneId!,
        shiftId: _shiftId!,
        lat: _me!.latitude,
        lng: _me!.longitude,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checked in • ${r['status'] ?? ''} • ${r['distance'] ?? ''} m',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(prettyDioError(e))));
    }
  }

  Future<void> _doCheckOut() async {
    if (_me == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location not ready')));
      return;
    }
    try {
      final r = await _api.checkOut(lat: _me!.latitude, lng: _me!.longitude);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checked out at ${r['checkOutTime'] ?? ''}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(prettyDioError(e))));
    }
  }

  Widget _roundedGlowingMap() {
    final mapCore = FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _zoneCenter ?? _me ?? const LatLng(20, 78),
        initialZoom: _zoneCenter != null ? 16 : 5,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.attendex.attendex_app',
        ),

        // Live blue dot + accuracy circle
        const CurrentLocationLayer(
          style: LocationMarkerStyle(
            marker: DefaultLocationMarker(
              color: Color(0xFF2F6FED),
              child: Icon(Icons.navigation, size: 12, color: Colors.white),
            ),
            markerSize: Size(40, 40),
            accuracyCircleColor: Color(0x332F6FED),
          ),
        ),

        if (_zoneCenter != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: _zoneCenter!,
                radius: _zoneRadiusM,
                color: const Color(0x112F6FED),
                borderStrokeWidth: 2,
                borderColor: const Color(0xFF2F6FED),
              ),
            ],
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final side = (w < h ? w : h) - 32;
        final sideClamped = side.clamp(280.0, 560.0);
        final mapWidget = ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            width: sideClamped,
            height: sideClamped,
            child: mapCore,
          ),
        );
        return Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x552F6FED),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
              border: Border.all(color: Color(0x22000000), width: 2),
            ),
            child: mapWidget,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ATTENDEX',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _roundedGlowingMap(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _doCheckIn,
                    child: const Text('Check-in'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _doCheckOut,
                    child: const Text('Check-out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
