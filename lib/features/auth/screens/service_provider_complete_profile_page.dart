import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../entities/app_user.dart';
import '../../../cloudinary_service.dart';
import '../../home/home_page.dart'; // TODO: replace with a real provider home page once it exists.

class ServiceProviderCompleteProfilePage extends StatefulWidget {
  final String uid;
  final String phoneNumber;

  const ServiceProviderCompleteProfilePage({
    super.key,
    required this.uid,
    required this.phoneNumber,
  });

  @override
  State<ServiceProviderCompleteProfilePage> createState() =>
      _ServiceProviderCompleteProfilePageState();
}

class _ServiceProviderCompleteProfilePageState
    extends State<ServiceProviderCompleteProfilePage> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _pickedImage;
  bool _isLoading = false;

  // Which services this provider offers. Nothing pre-selected;
  // user must pick at least one before submitting.
  final Set<ServiceType> _selectedServices = {};

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );
    if (picked != null) {
      setState(() => _pickedImage = picked);
    }
  }

  void _toggleService(ServiceType service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  Future<void> _onSubmit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service you offer'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String imageUrl = '';
    if (_pickedImage != null) {
      final uploadedUrl = await CloudinaryService.uploadImage(_pickedImage!);
      if (uploadedUrl == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed. Try again.')),
        );
        return;
      }
      imageUrl = uploadedUrl;
    }

    // currentLocation and rating default sensibly (empty location,
    // zero rating) and can be updated later once the app starts
    // tracking the provider's live position and reviews.
    final provider = AssistanceProvider(
      uid: widget.uid,
      phoneNumber: widget.phoneNumber,
      name: _nameController.text.trim(),
      profileImagePath: imageUrl,
      services: _selectedServices,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .set(provider.toMap());

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        // TODO: swap for a real provider home page (e.g.
        // AssistanceProviderHomePage) once it exists.
        builder: (_) => HomePage(
          userName: provider.name,
          profileImagePath: provider.profileImagePath,
        ),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _labelFor(ServiceType service) => switch (service) {
        ServiceType.mechanic => 'Mechanic',
        ServiceType.towTruck => 'Tow Truck',
        ServiceType.fuelDelivery => 'Fuel Delivery',
        ServiceType.flatTireChange => 'Flat Tire Change',
        ServiceType.batteryBoost => 'Battery Boost',
      };

  IconData _iconFor(ServiceType service) => switch (service) {
        ServiceType.mechanic => Icons.build_rounded,
        ServiceType.towTruck => Icons.local_shipping_rounded,
        ServiceType.fuelDelivery => Icons.local_gas_station_rounded,
        ServiceType.flatTireChange => Icons.tire_repair_rounded,
        ServiceType.batteryBoost => Icons.battery_charging_full_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        color: Colors.grey.shade200,
                      ),
                      child: CircleAvatar(
                        radius: 58,
                        backgroundColor: Colors.transparent,
                        backgroundImage: _pickedImage != null
                            ? FileImage(File(_pickedImage!.path))
                            : null,
                        child: _pickedImage == null
                            ? Icon(
                                Icons.camera_alt_rounded,
                                size: 38,
                                color: Colors.grey.shade600,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Add profile photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Center(
                  child: Text(
                    'Complete Your Provider Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tell us who you are and what services you offer',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Services you offer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select all that apply',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ServiceType.values.map((service) {
                    final isSelected = _selectedServices.contains(service);
                    return FilterChip(
                      selected: isSelected,
                      onSelected: (_) => _toggleService(service),
                      showCheckmark: false,
                      avatar: Icon(
                        _iconFor(service),
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                      label: Text(_labelFor(service)),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: const Color(0xFFE30613),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFFE30613)
                              : Colors.grey.shade300,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE30613),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
