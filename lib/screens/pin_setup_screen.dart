import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'pin_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isForFingerprintSetup;

  const PinSetupScreen({
    super.key,
    this.isForFingerprintSetup = false,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _createdPin;
  bool _isCreatingPin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF201E1A),
      body: _isCreatingPin
          ? PinScreen(
              key: const ValueKey('create_pin'),
              mode: PinMode.create,
              title: widget.isForFingerprintSetup 
                  ? 'Set Up PIN for Fingerprint'
                  : 'Create PIN',
              subtitle: widget.isForFingerprintSetup
                  ? 'Create a PIN to enable fingerprint authentication'
                  : 'Create a 4-digit PIN for secure app access',
              onPinCreated: (pin) {
                setState(() {
                  _createdPin = pin;
                });
              },
              onSuccess: () {
                // Move to confirmation step
                setState(() {
                  _isCreatingPin = false;
                });
              },
              onCancel: () {
                Navigator.of(context).pop(false);
              },
            )
          : PinScreen(
              key: const ValueKey('confirm_pin'),
              mode: PinMode.confirm,
              title: 'Confirm PIN',
              subtitle: 'Re-enter your PIN to confirm',
              initialPin: _createdPin,
              onSuccess: () {
                // Show success message and return
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isForFingerprintSetup
                          ? 'PIN set up successfully! You can now enable fingerprint authentication.'
                          : 'PIN set up successfully!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop(true);
              },
              onCancel: () {
                setState(() {
                  _isCreatingPin = true;
                });
              },
            ),
    );
  }
}