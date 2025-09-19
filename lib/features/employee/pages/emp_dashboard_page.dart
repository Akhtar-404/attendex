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
  bool _isCheckedIn = false; // Track check-in status

  Map<String, dynamic>? _shift; // Store the assigned shift

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
        _shift = shifts.first; // Store the whole shift object
      }
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

  // --- Shift time logic ---
  bool _isWithinShift() {
    if (_shift == null) return false;
    final now = DateTime.now();
    final startParts = (_shift!['start'] as String).split(':');
    final endParts = (_shift!['end'] as String).split(':');
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );
    return now.isAfter(start) && now.isBefore(end);
  }

  Future<void> _doCheckIn() async {
    if (_me == null || _zoneId == null || _shiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zone/shift or location not ready')),
      );
      return;
    }
    // Only allow check-in during shift time
    if (!_isWithinShift()) {
      final s = _shift;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Check-in only allowed during shift: ${s?['start']} - ${s?['end']}',
          ),
        ),
      );
      return;
    }
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
      setState(() {
        _isCheckedIn = true;
      });
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
    if (!_isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must check in before checking out!')),
      );
      return;
    }
    if (_me == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location not ready')));
      return;
    }
    // Only allow check-out during shift time
    if (!_isWithinShift()) {
      final s = _shift;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Check-out only allowed during shift: ${s?['start']} - ${s?['end']}',
          ),
        ),
      );
      return;
    }
    try {
      final r = await _api.checkOut(lat: _me!.latitude, lng: _me!.longitude);
      if (!mounted) return;
      setState(() {
        _isCheckedIn = false;
      });
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // ATTENDEX title at top center
          Text(
            'ATTENDEX',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 40), // <-- space between title and map
          // Map box (large square, centered)
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.10),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.13),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(9),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _roundedGlowingMap(),
            ),
          ),
          const SizedBox(height: 61),

          // Shift time box with horizontal padding
          if (_shift != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(
                    0.06,
                  ), // subtle blue background
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.blueAccent, // outlined border
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.18),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Shift Time',
                      style: TextStyle(
                        color: Color(0xFF0D47A1), // dark blue
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_shift!['start']} - ${_shift!['end']}',
                      style: const TextStyle(
                        color: Color(0xFF0D47A1), // dark blue
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 33),

          // Buttons row (wide, spaced, rounded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 41,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.13),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      onPressed: _loading ? null : _doCheckIn,
                      child: const Text(
                        'Check-in',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1.1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 41,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blueAccent, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.10),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: _loading ? null : _doCheckOut,
                      child: const Text(
                        'Check-out',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1.1,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
