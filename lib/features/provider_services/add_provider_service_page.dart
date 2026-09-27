import 'package:flutter/material.dart';

import '../../entities/app_user.dart';
import '../../entities/provider_service.dart';

class AddProviderServicePage extends StatefulWidget {
  final String providerId;
  final ProviderService? serviceToEdit;

  const AddProviderServicePage({super.key, required this.providerId, this.serviceToEdit});

  @override
  State<AddProviderServicePage> createState() => _AddProviderServicePageState();
}

class _AddProviderServicePageState extends State<AddProviderServicePage> {
  late ProviderServiceType _selectedType;
  late Map<String, TextEditingController> _controllers;
  GeoLocation _location = const GeoLocation(latitude: 0, longitude: 0);
  bool _locationConfirmed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.serviceToEdit;
    _selectedType = existing?.serviceType ?? ProviderServiceType.towTruck;
    _location = existing?.location ?? _location;
    _locationConfirmed = existing != null;
    _controllers = _controllersFor(_selectedType, existing?.fields);
  }

  Map<String, TextEditingController> _controllersFor(ProviderServiceType type, [Map<String, String>? values]) {
    final config = providerServiceFormConfig[type]!;
    return {for (final field in config.fields) field.key: TextEditingController(text: values?[field.key] ?? _controllers[field.key]?.text ?? '')};
  }

  void _changeType(ProviderServiceType type) {
    if (type == _selectedType) return;
    final old = _controllers;
    final next = _controllersFor(type);
    setState(() { _selectedType = type; _controllers = next; });
    for (final controller in old.values) { controller.dispose(); }
  }

  @override
  void dispose() { for (final controller in _controllers.values) { controller.dispose(); } super.dispose(); }

  Future<void> _save() async {
    final config = providerServiceFormConfig[_selectedType]!;
    final fields = {for (final field in config.fields) field.key: _controllers[field.key]!.text.trim()};
    if (fields.values.any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in every field')));
      return;
    }
    setState(() => _isSaving = true);
    final service = ProviderService(id: widget.serviceToEdit?.id ?? '', providerId: widget.providerId, serviceType: _selectedType, fields: fields, location: _location);
    try {
      late final ProviderService saved;
      if (widget.serviceToEdit == null) {
        saved = await addProviderService(service);
      } else {
        await updateProviderService(service);
        saved = service;
      }
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save service. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = providerServiceFormConfig[_selectedType]!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceToEdit == null ? 'Add Service' : 'Edit Service')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Service Type', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: ProviderServiceType.values.map((type) => ChoiceChip(label: Text(type.label), selected: type == _selectedType, onSelected: (_) => _changeType(type))).toList()),
        const SizedBox(height: 24),
        const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(onTap: () => setState(() => _locationConfirmed = true), child: Container(height: 120, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.location_pin, size: 34, color: _locationConfirmed ? const Color(0xFFE30613) : Colors.grey), Text(_locationConfirmed ? 'Location selected' : 'Tap to set location')]))) ,
        const SizedBox(height: 18),
        ...config.fields.map((field) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: _controllers[field.key], keyboardType: field.inputType == ServiceFieldInputType.number ? TextInputType.number : field.inputType == ServiceFieldInputType.multiline ? TextInputType.multiline : TextInputType.text, maxLines: field.inputType == ServiceFieldInputType.multiline ? 3 : 1, decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder())))),
        const SizedBox(height: 12),
        SizedBox(height: 52, child: ElevatedButton(onPressed: _isSaving ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE30613), foregroundColor: Colors.white), child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm'))),
      ])),
    );
  }
}
