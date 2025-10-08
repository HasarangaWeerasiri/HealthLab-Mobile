import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_utils.dart';
import 'content_preference_screen.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  Future<void> _saveUsername() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);
    try {
      final username = _usernameController.text.trim().toLowerCase();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if username already exists
      final usernameQuery = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username)
          .get();
      
      if (usernameQuery.exists) {
        setState(() => _submitting = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already taken')),
        );
        return;
      }

      // Save username to usernames collection
      await FirebaseFirestore.instance
          .collection('usernames')
          .doc(username)
          .set({'userId': user.uid, 'createdAt': FieldValue.serverTimestamp()});

      // Save user profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'username': username,
        'email': user.email,
        'displayName': user.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        slideRoute(const ContentPreferenceScreen()),
      );
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 16),
              const Text(
                'Choose a username',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "This will be your unique identity in HealthLab. You can use letters, numbers, or underscores.",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    final username = value.trim();
                    if (username.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (username.length > 20) {
                      return 'Username must be less than 20 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
                      return 'Only letters, numbers, and underscores allowed';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter username',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: AppColors.primaryBackground,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _saveUsername,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    foregroundColor: AppColors.lightGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _submitting 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      ) 
                    : const Text('continue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
