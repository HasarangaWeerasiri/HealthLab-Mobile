import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../utils/app_utils.dart';
import 'username_screen.dart';
import 'package:flutter/services.dart';
import '../services/otp_service.dart';
import '../services/sendgrid_email_service.dart';
import '../utils/email_config.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _pollTimer;
  final TextEditingController _c1 = TextEditingController();
  final TextEditingController _c2 = TextEditingController();
  final TextEditingController _c3 = TextEditingController();
  final TextEditingController _c4 = TextEditingController();
  bool _verifying = false;
  late final OtpService _otpService;

  @override
  void initState() {
    super.initState();
    _otpService = OtpService(
      emailService: SendGridEmailService(
        apiKey: EmailConfig.sendGridApiKey,
        fromEmail: EmailConfig.senderEmail,
        fromName: EmailConfig.senderName,
      ),
    );
    _startPolling();
    // Attempt initial send to ensure user receives a code if arriving directly
    // Ignore errors here; user can tap Resend Code
    _otpService.sendOtpToCurrentUser(toEmail: widget.email).catchError((_) {});
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
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    _c4.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    try {
      await _otpService.sendOtpToCurrentUser(toEmail: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send code: $e')),
      );
    }
  }

  Future<void> _verify() async {
    final code = (_c1.text + _c2.text + _c3.text + _c4.text).trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 4-digit code')),
      );
      return;
    }
    setState(() => _verifying = true);
    try {
      final ok = await _otpService.verifyOtp(code: code);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushAndRemoveUntil(
          slideRoute(const UsernameScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or expired code')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
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
                children: <Widget>[
                  _otpBox(_c1),
                  const SizedBox(width: 12),
                  _otpBox(_c2),
                  const SizedBox(width: 12),
                  _otpBox(_c3),
                  const SizedBox(width: 12),
                  _otpBox(_c4),
                ],
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    foregroundColor: AppColors.lightGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _verifying
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(TextEditingController controller) {
    return SizedBox(
      height: 56,
      width: 56,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.primaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
          ),
        ),
        onChanged: (v) {
          if (v.length == 1) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }
}
