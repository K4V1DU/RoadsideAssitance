import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../entities/app_user.dart';

class ProviderProfilePage extends StatelessWidget {
  final String uid;
  const ProviderProfilePage({super.key, required this.uid});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(future: FirebaseFirestore.instance.collection('users').doc(uid).get(), builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      final user = snapshot.hasData && snapshot.data!.exists ? userFromMap(uid, snapshot.data!.data()!) : null;
      return ListView(padding: const EdgeInsets.all(24), children: [CircleAvatar(radius: 42, backgroundImage: user?.profileImagePath.isNotEmpty == true ? NetworkImage(user!.profileImagePath) : null, child: user?.profileImagePath.isNotEmpty == true ? null : const Icon(Icons.person, size: 42)), const SizedBox(height: 16), Center(child: Text(user?.name ?? 'Provider', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), const SizedBox(height: 24), ListTile(leading: const Icon(Icons.phone), title: Text(user?.phoneNumber ?? 'No phone number')), ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Service provider account')), const SizedBox(height: 20), OutlinedButton.icon(onPressed: () => _signOut(context), icon: const Icon(Icons.logout), label: const Text('Sign out'))]);
    }),
  );
}
