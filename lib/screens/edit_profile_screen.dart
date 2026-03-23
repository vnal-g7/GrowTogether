import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/app_utils.dart';
import '../services/challenge_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final ChallengeService _challengeService = ChallengeService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseDatabase.instance.ref('users').child(user.uid).get();
    if (!snapshot.exists || snapshot.value == null) return;

    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    _nameController.text = data['name']?.toString() ?? '';
    _ageController.text = data['age']?.toString() ?? '';
    _photoUrlController.text = data['profilePic']?.toString() ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppUtils.showSnack(context, 'Name cannot be empty', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _challengeService.updateProfile(
        uid: user.uid,
        name: name,
        age: int.tryParse(_ageController.text.trim()),
        profilePic: _photoUrlController.text.trim(),
      );
      if (!mounted) return;
      AppUtils.showSnack(context, 'Profile updated');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppUtils.showSnack(context, 'Failed to update profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 54,
              backgroundImage: _photoUrlController.text.trim().isNotEmpty ? NetworkImage(_photoUrlController.text.trim()) : null,
              child: _photoUrlController.text.trim().isEmpty ? const Icon(Icons.person, size: 54) : null,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _photoUrlController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Profile Photo URL', prefixIcon: Icon(Icons.link)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
