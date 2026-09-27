import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../home/provider_dashboard_page.dart';
import '../../profile/provider_profile_page.dart';
import '../../provider_services/provider_service_list_page.dart';

class AppBottomNavBarProviderV2 extends StatelessWidget {
  final int activeIndex;
  const AppBottomNavBarProviderV2({super.key, required this.activeIndex});

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _go(BuildContext context, int index) {
    if (index == activeIndex) return;
    if (_uid.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in again to continue.'))); return; }
    final page = switch (index) {
      0 => const ProviderDashboardPage(),
      1 => ProviderServiceListPage(providerId: _uid),
      _ => ProviderProfilePage(uid: _uid),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) => NavigationBar(selectedIndex: activeIndex, onDestinationSelected: (index) => _go(context, index), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'), NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Service'), NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'More')]);
}
