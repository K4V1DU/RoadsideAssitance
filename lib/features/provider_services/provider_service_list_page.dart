import 'package:flutter/material.dart';

import '../../entities/provider_service.dart';
import '../_share/navbar/app_bottom_nav_bar_provider_v2.dart';
import 'add_provider_service_page.dart';

enum _ServiceAction { edit, remove }

class ProviderServiceListPage extends StatefulWidget {
  final String providerId;
  const ProviderServiceListPage({super.key, required this.providerId});

  @override
  State<ProviderServiceListPage> createState() => _ProviderServiceListPageState();
}

class _ProviderServiceListPageState extends State<ProviderServiceListPage> {
  late Future<List<ProviderService>> _servicesFuture;

  @override
  void initState() { super.initState(); _servicesFuture = fetchProviderServices(widget.providerId); }
  Future<void> _refresh() async { setState(() => _servicesFuture = fetchProviderServices(widget.providerId)); await _servicesFuture; }

  Future<void> _add() async {
    final result = await Navigator.of(context).push<ProviderService>(MaterialPageRoute(builder: (_) => AddProviderServicePage(providerId: widget.providerId)));
    if (result != null) await _refresh();
  }

  Future<void> _menu(ProviderService service) async {
    final action = await showModalBottomSheet<_ServiceAction>(context: context, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit'), onTap: () => Navigator.pop(context, _ServiceAction.edit)), ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Remove', style: TextStyle(color: Colors.red)), onTap: () => Navigator.pop(context, _ServiceAction.remove)), const SizedBox(height: 8)])));
    if (!mounted || action == null) return;
    if (action == _ServiceAction.edit) {
      final result = await Navigator.of(context).push<ProviderService>(MaterialPageRoute(builder: (_) => AddProviderServicePage(providerId: widget.providerId, serviceToEdit: service)));
      if (result != null) await _refresh();
    } else {
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Remove service?'), content: Text('This will remove ${service.displayLabel}.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red)))]));
      if (confirmed == true) { await deleteProviderService(service.id); if (mounted) await _refresh(); }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Services')),
    body: FutureBuilder<List<ProviderService>>(future: _servicesFuture, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: TextButton(onPressed: _refresh, child: const Text('Could not load services. Try again')));
      final services = snapshot.data ?? [];
      return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.all(20), children: [if (services.isEmpty) ...[_emptyState()] else ...services.map(_tile), const SizedBox(height: 12), OutlinedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add Service'))]));
    }),
    bottomNavigationBar: const AppBottomNavBarProviderV2(activeIndex: 1),
  );

  Widget _emptyState() => const Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Column(children: [Icon(Icons.miscellaneous_services_rounded, size: 90, color: Colors.grey), SizedBox(height: 16), Text('Your services will appear here', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('Add the services customers can book from you.', textAlign: TextAlign.center)]));

  Widget _tile(ProviderService service) => Card(child: ListTile(leading: service.serviceType.iconAsset.isEmpty ? const Icon(Icons.store) : Image.asset(service.serviceType.iconAsset, width: 36, errorBuilder: (_, __, ___) => const Icon(Icons.build)), title: Text(service.title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(service.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: IconButton(onPressed: () => _menu(service), icon: const Icon(Icons.more_vert))));
}
