import 'package:flutter/material.dart';

import '../../entities/app_user.dart';
import '../_share/navbar/app_bottom_nav_bar_provider_v2.dart';

class ProviderDashboardPage extends StatefulWidget {
  final UserType userType;
  final String userName;
  final String locationLabel;
  final String profileImagePath;

  const ProviderDashboardPage({super.key, this.userType = UserType.assistanceProvider, this.userName = 'Provider', this.locationLabel = 'Current location', this.profileImagePath = ''});

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> {
  bool _hasIncomingRequest = true;
  void _respond(bool accepted) { setState(() => _hasIncomingRequest = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accepted ? 'Dispatch accepted' : 'Dispatch declined'))); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F7F8),
    body: SafeArea(child: RefreshIndicator(onRefresh: () async {}, child: ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [CircleAvatar(radius: 21, backgroundImage: widget.profileImagePath.isEmpty ? null : NetworkImage(widget.profileImagePath), child: widget.profileImagePath.isEmpty ? const Icon(Icons.person) : null), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.userName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), Text(widget.locationLabel, style: const TextStyle(color: Colors.grey))])), const Icon(Icons.notifications_none)]),
      const SizedBox(height: 20),
      if (_hasIncomingRequest) _requestCard(),
      if (_hasIncomingRequest) const SizedBox(height: 22),
      const Text("TODAY'S SUMMARY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Row(children: [_summary('Completed', '2 Jobs'), const SizedBox(width: 12), _summary('Earnings', 'LKR 23,950', accent: true)]),
      const SizedBox(height: 22),
      const Text("TODAY'S COMPLETED LOG", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      _job('Flat bed', 'Smpath', 'LKR 12,100'), _job('Wheel lifter', 'Ayesha', 'LKR 11,850'),
    ]))),
    bottomNavigationBar: const AppBottomNavBarProviderV2(activeIndex: 0),
  );

  Widget _requestCard() => Card(
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Color(0xFFE30613)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NEW URGENT DISPATCH', style: TextStyle(color: Color(0xFFE30613), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Clutch Failure · Nuwan', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('LKR 2,340', style: TextStyle(color: Color(0xFFE30613), fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          const Text('Colombo 03 · 3.2 km away'),
          const SizedBox(height: 8),
          const Text('Suzuki Alto · WP CAA-9081'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _respond(false), child: const Text('Decline'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () => _respond(true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE30613), foregroundColor: Colors.white), child: const Text('Accept'))),
          ]),
        ],
      ),
    ),
  );
  Widget _summary(String label, String value, {bool accent = false}) => Expanded(
    child: Card(
      color: accent ? const Color(0xFFFDECEE) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: accent ? const Color(0xFFE30613) : Colors.black)),
          ],
        ),
      ),
    ),
  );

  Widget _job(String truck, String customer, String amount) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.star, color: Color(0xFFE30613))),
      title: Text('$truck · $customer'),
      subtitle: Text('Today · $amount'),
      trailing: const Text('Completed', style: TextStyle(color: Colors.green)),
    ),
  );
}
