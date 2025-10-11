import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'pin_screen.dart';
import 'homepage_screen.dart';

class PinVerificationScreen extends StatefulWidget {
  final String reason;
  final VoidCallback? onSuccess;

  const PinVerificationScreen({
    super.key,
    required this.reason,
    this.onSuccess,
  });

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF201E1A),
      body: PinScreen(
        mode: PinMode.verify,
        title: 'Enter PIN',
        subtitle: widget.reason,
        onSuccess: () {
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomepageScreen()),
            );
          }
        },
        onCancel: () {
          Navigator.of(context).pop(false);
        },
      ),
    );
  }
}