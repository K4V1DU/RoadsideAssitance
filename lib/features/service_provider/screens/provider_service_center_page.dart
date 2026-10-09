import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../entities/service_center.dart';

class ProviderServiceCenterPage extends StatefulWidget {
  const ProviderServiceCenterPage({super.key});

  @override
  State<ProviderServiceCenterPage> createState() =>
      _ProviderServiceCenterPageState();
}

class _ProviderServiceCenterPageState extends State<ProviderServiceCenterPage> {
  static const Color _red = Color(0xFFE30613);
  static const Color _green = Color(0xFF1E9E4A);
  static const LatLng _fallback = LatLng(6.9271, 79.8612);

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final MapController _map = MapController();

  LatLng? _point;
  bool _is24h = false;
  int _open = 8;
  int _close = 18;
  bool _accepting = true; // true = Open, false = Closed (manual)
  bool _exists = false;

  bool _loading = true;
  bool _saving = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('service_centers').doc(_uid);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _price.dispose();
    _map.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _load() async {
    if (_uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snap = await _doc.get();
      if (snap.exists && snap.data() != null) {
        final c = ServiceCenter.fromMap(snap.id, snap.data()!);
        _name.text = c.name;
        _phone.text = c.phone;
        _address.text = c.address;
        _price.text = c.fullServicePrice.toStringAsFixed(0);
        _point = LatLng(c.latitude, c.longitude);
        _is24h = c.openHour == 0 && c.closeHour == 24;
        if (!_is24h) {
          _open = c.openHour.clamp(0, 23);
          _close = c.closeHour.clamp(1, 24);
        }
        _accepting = !c.manuallyClosed;
        _exists = true;
      }
    } catch (e) {
      _toast('Could not load your service center.');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _moveMap(LatLng p) {
    try {
      _map.move(p, 16);
    } catch (_) {}
  }

  Future<String> _addressOf(LatLng p) async {
    try {
      final list = await placemarkFromCoordinates(p.latitude, p.longitude);
      if (list.isNotEmpty) {
        final m = list.first;
        final parts = <String>[
          m.name ?? '',
          m.street ?? '',
          m.subLocality ?? '',
          m.locality ?? '',
        ].where((s) => s.trim().isNotEmpty).toSet().toList();
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (_) {}
    return '';
  }

  Future<void> _useCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _toast('Please turn on location services.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _toast('Location permission is required.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 12));
      final p = LatLng(pos.latitude, pos.longitude);
      setState(() => _point = p);
      _moveMap(p);
      final a = await _addressOf(p);
      if (mounted && a.isNotEmpty) setState(() => _address.text = a);
    } catch (_) {
      _toast('Could not get your current location.');
    }
  }

  Future<void> _findAddressOnMap() async {
    final q = _address.text.trim();
    if (q.isEmpty) {
      _toast('Type the address first.');
      return;
    }
    FocusScope.of(context).unfocus();
    try {
      final res = await locationFromAddress(q);
      if (res.isEmpty) {
        _toast('Address not found. Try a more specific address.');
        return;
      }
      final p = LatLng(res.first.latitude, res.first.longitude);
      setState(() => _point = p);
      _moveMap(p);
    } catch (_) {
      _toast('Address not found. Try a more specific address.');
    }
  }

  Future<void> _onMapTap(LatLng p) async {
    setState(() => _point = p);
    final a = await _addressOf(p);
    if (mounted && a.isNotEmpty) setState(() => _address.text = a);
  }

  /// Quick Open/Closed switch at the top. Saves immediately if the
  /// center already exists.
  Future<void> _toggleAccepting(bool v) async {
    setState(() => _accepting = v);
    if (!_exists) return;
    try {
      await _doc.update({'manuallyClosed': !v});
      _toast(v ? 'Your service center is now Open.' : 'Marked as Closed.');
    } catch (_) {
      setState(() => _accepting = !v);
      _toast('Could not update. Try again.');
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final address = _address.text.trim();
    final price = double.tryParse(_price.text.trim());

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      _toast('Name, phone and address are required.');
      return;
    }
    if (price == null || price < 0) {
      _toast('Enter a valid full service price.');
      return;
    }
    if (!_is24h && _open >= _close) {
      _toast('Closing time must be after opening time.');
      return;
    }

    setState(() => _saving = true);
    try {
      LatLng? p = _point;
      if (p == null) {
        final res = await locationFromAddress(address);
        if (res.isNotEmpty) {
          p = LatLng(res.first.latitude, res.first.longitude);
        }
      }
      if (p == null) {
        _toast('Set the location on the map or use current location.');
        return;
      }

      final data = <String, dynamic>{
        'ownerId': _uid,
        'name': name,
        'phone': phone,
        'address': address,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'fullServicePrice': price,
        'openHour': _is24h ? 0 : _open,
        'closeHour': _is24h ? 24 : _close,
        'manuallyClosed': !_accepting,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!_exists) {
        data['rating'] = 0;
        data['reviewCount'] = 0;
      }

      await _doc.set(data, SetOptions(merge: true));
      _exists = true;
      _point = p;
      _toast('Service center saved.');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('Could not save. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'My Service Center',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _red))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _statusCard(),
                const SizedBox(height: 14),
                _section('Basic details', [
                  _field(_name, 'Service center name', Icons.store_outlined),
                  const SizedBox(height: 12),
                  _field(
                    _phone,
                    'Contact number',
                    Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _price,
                    'Full service price (LKR)',
                    Icons.payments_outlined,
                    keyboard: TextInputType.number,
                  ),
                ]),
                const SizedBox(height: 14),
                _section('Location', [
                  _field(_address, 'Address', Icons.place_outlined),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: _outlineStyle(),
                          onPressed: _findAddressOnMap,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text(
                            'Find on map',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: _outlineStyle(),
                          onPressed: _useCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text(
                            'Use current',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 180,
                      child: FlutterMap(
                        mapController: _map,
                        options: MapOptions(
                          initialCenter: _point ?? _fallback,
                          initialZoom: _point == null ? 11 : 16,
                          onTap: (_, p) => _onMapTap(p),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.example.roadside_assitance',
                          ),
                          if (_point != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _point!,
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.topCenter,
                                  child: const Icon(
                                    Icons.location_on,
                                    size: 44,
                                    color: _red,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _point == null
                        ? 'Tap the map to drop a pin on your exact location.'
                        : 'Pin set. Tap the map to move it.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ]),
                const SizedBox(height: 14),
                _section('Working hours', [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: _red,
                    title: const Text('Open 24 hours'),
                    value: _is24h,
                    onChanged: (v) => setState(() => _is24h = v),
                  ),
                  if (!_is24h)
                    Row(
                      children: [
                        Expanded(
                          child: _hourDropdown(
                            'Opens',
                            _open,
                            List.generate(24, (i) => i),
                            (v) => setState(() => _open = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _hourDropdown(
                            'Closes',
                            _close,
                            List.generate(24, (i) => i + 1),
                            (v) => setState(() => _close = v),
                          ),
                        ),
                      ],
                    ),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _exists ? 'Update Service Center' : 'Save',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }

  Widget _statusCard() {
    final color = _accepting ? _green : _red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _accepting ? 'Open for customers' : 'Closed',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  _accepting
                      ? 'Shown as Open during your working hours'
                      : 'Shown as Closed to drivers right now',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: _accepting,
            activeThumbColor: _green,
            onChanged: _toggleAccepting,
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
      ),
    );
  }

  ButtonStyle _outlineStyle() => OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  Widget _hourDropdown(
    String label,
    int value,
    List<int> options,
    ValueChanged<int> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: options
          .map(
            (h) => DropdownMenuItem(
              value: h,
              child: Text(ServiceCenter.hourLabel(h)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}