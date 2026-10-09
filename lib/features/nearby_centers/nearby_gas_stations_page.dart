import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class _GasStation {
  final String name;
  final String? brand;
  final String? hours;
  final LatLng point;
  final double distanceKm;

  const _GasStation({
    required this.name,
    required this.brand,
    required this.hours,
    required this.point,
    required this.distanceKm,
  });
}

class NearbyGasStationsPage extends StatefulWidget {
  const NearbyGasStationsPage({super.key});

  @override
  State<NearbyGasStationsPage> createState() => _NearbyGasStationsPageState();
}

class _NearbyGasStationsPageState extends State<NearbyGasStationsPage> {
  static const Color _red = Color(0xFFE30613);
  static const LatLng _fallback = LatLng(6.9271, 79.8612); // Colombo
  static const double _cardWidth = 250;
  static const double _cardGap = 12;
  static const int _radiusMeters = 5000;

  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  final MapController _map = MapController();
  final ScrollController _list = ScrollController();

  LatLng? _user;
  bool _usingFallback = false;
  List<_GasStation> _stations = [];
  int _selected = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _list.dispose();
    _map.dispose();
    super.dispose();
  }

  /// Fresh high-accuracy GPS fix (up to 20s). If the lock is slow,
  /// falls back to the last known position. Returns null if nothing works.
  Future<LatLng?> _gps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: const Duration(seconds: 20),
          ),
        );
        return LatLng(pos.latitude, pos.longitude);
      } catch (e) {
        debugPrint('GPS fix failed: $e');
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return LatLng(last.latitude, last.longitude);
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Tries every Overpass server, and repeats the whole round once more
  /// (the first request often fails on a busy / cold server).
  Future<http.Response> _queryOverpass(String query) async {
    for (int round = 0; round < 2; round++) {
      for (final url in _endpoints) {
        try {
          final r = await http
              .post(
                Uri.parse(url),
                headers: {
                  'User-Agent': 'roadside_assitance/1.0',
                  'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: {'data': query},
              )
              .timeout(const Duration(seconds: 12));
          if (r.statusCode == 200) return r;
          debugPrint('Overpass $url -> HTTP ${r.statusCode}');
        } catch (e) {
          debugPrint('Overpass $url failed: $e');
        }
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    throw Exception('All Overpass servers failed');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final gps = await _gps();
    final user = gps ?? _fallback;

    try {
      final query = '[out:json][timeout:15];'
          '(node["amenity"="fuel"](around:$_radiusMeters,${user.latitude},${user.longitude});'
          'way["amenity"="fuel"](around:$_radiusMeters,${user.latitude},${user.longitude}););'
          'out center tags 40;';

      final res = await _queryOverpass(query);

      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final elements = (data['elements'] as List?) ?? [];
      final result = <_GasStation>[];

      for (final e in elements) {
        final m = e as Map<String, dynamic>;
        final lat = (m['lat'] ?? (m['center'] as Map?)?['lat']) as num?;
        final lon = (m['lon'] ?? (m['center'] as Map?)?['lon']) as num?;
        if (lat == null || lon == null) continue;

        final tags = (m['tags'] as Map?)?.cast<String, dynamic>() ?? {};
        final brand = tags['brand']?.toString();
        final name = (tags['name'] ?? brand ?? 'Fuel Station').toString();
        final km = Geolocator.distanceBetween(
              user.latitude,
              user.longitude,
              lat.toDouble(),
              lon.toDouble(),
            ) /
            1000;

        result.add(
          _GasStation(
            name: name,
            brand: brand,
            hours: tags['opening_hours']?.toString(),
            point: LatLng(lat.toDouble(), lon.toDouble()),
            distanceKm: km,
          ),
        );
      }

      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      if (!mounted) return;
      setState(() {
        _user = user;
        _usingFallback = gps == null;
        _stations = result.take(20).toList();
        _selected = 0;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Gas stations error: $e');
      if (!mounted) return;
      setState(() {
        _user = user;
        _usingFallback = gps == null;
        _error = 'Could not load gas stations. Please retry in a moment.';
        _loading = false;
      });
    }
  }

  void _select(int i, {bool scroll = true}) {
    setState(() => _selected = i);
    try {
      _map.move(_stations[i].point, 16);
    } catch (_) {}
    if (scroll && _list.hasClients) {
      _list.animateTo(
        i * (_cardWidth + _cardGap),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _navigate(_GasStation s) async {
    final u = _user ?? _fallback;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${u.latitude},${u.longitude}'
      '&destination=${s.point.latitude},${s.point.longitude}'
      '&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _red))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final user = _user ?? _fallback;

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(initialCenter: user, initialZoom: 14),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.roadside_assitance',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: user,
                  width: 22,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
                for (int i = 0; i < _stations.length; i++)
                  Marker(
                    point: _stations[i].point,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _select(i),
                      child: Icon(
                        Icons.local_gas_station,
                        size: i == _selected ? 44 : 34,
                        color: i == _selected ? _red : Colors.orange.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Back + refresh buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _roundButton(Icons.arrow_back_ios_new, () {
                  Navigator.of(context).pop();
                }, size: 18),
                const Spacer(),
                _roundButton(Icons.refresh, _load),
              ],
            ),
          ),
        ),

        // Bottom area
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_usingFallback)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Location unavailable. Showing stations near Colombo.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                if (_error != null)
                  _messageCard(_error!, retry: true)
                else if (_stations.isEmpty)
                  _messageCard('No gas stations found within 5 km.')
                else
                  SizedBox(
                    height: 168,
                    child: ListView.separated(
                      controller: _list,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _stations.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: _cardGap),
                      itemBuilder: (context, i) => _stationCard(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap, {double size = 22}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: size, color: Colors.black87),
      ),
    );
  }

  Widget _messageCard(String text, {bool retry = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          if (retry) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
              ),
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stationCard(int i) {
    final s = _stations[i];
    final selected = i == _selected;

    return GestureDetector(
      onTap: () => _select(i, scroll: false),
      child: Container(
        width: _cardWidth,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _red : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_gas_station, color: _red),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.near_me_outlined,
                    size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '${s.distanceKm.toStringAsFixed(1)} km away',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.hours ?? 'Hours not available',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => _navigate(s),
                icon: const Icon(Icons.navigation, size: 16),
                label: const Text(
                  'Navigate',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}