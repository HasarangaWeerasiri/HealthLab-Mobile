import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../utils/app_utils.dart';
import 'username_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      if (user != null && user.emailVerified) {
        _pollTimer?.cancel();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          slideRoute(const UsernameScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.sendEmailVerification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification email sent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 8),
              const Text(
                'Email verification',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text('Enter the 4-digit code sent to\n${widget.email}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 24),
              Row(
                children: List.generate(4, (index) {
                  return Container(
                    margin: EdgeInsets.only(right: index == 3 ? 0 : 12),
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Text("Didn't get the code? ", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  GestureDetector(
                    onTap: _resend,
                    child: const Text('Resend Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
