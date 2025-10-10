import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_utils.dart';
import '../services/auth_service.dart';
import 'content_preference_screen.dart';

class UsernameScreen extends StatefulWidget {
  final bool isGoogleSignUp;
  
  const UsernameScreen({super.key, this.isGoogleSignUp = false});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String _passwordStrength = '';
  Color _passwordStrengthColor = Colors.grey;
  String? _usernameValidationError;
  bool _isCheckingUsername = false;

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = '';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    int score = 0;
    String strength = '';
    Color color = Colors.grey;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    // Determine strength
    if (score < 3) {
      strength = 'Weak';
      color = Colors.red;
    } else if (score < 5) {
      strength = 'Medium';
      color = Colors.orange;
    } else {
      strength = 'Strong';
      color = Colors.green;
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthColor = color;
    });
  }

  Future<void> _saveUsername() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _submitting = true);
    try {
      final username = _usernameController.text.trim();
      final user = FirebaseAuth.instance.currentUser;
      final authService = AuthService();
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate username format
      final validationError = authService.validateUsername(username);
      if (validationError != null) {
        setState(() => _submitting = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationError)),
        );
        return;
      }

      // Check if user already has a username (prevent overwriting)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists && userDoc.data()?['username'] != null) {
        setState(() => _submitting = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already have a username. Please sign in instead.')),
        );
        return;
      }

      // Check if username already exists using AuthService
      final isTaken = await authService.isUsernameTaken(username);
      if (isTaken) {
        setState(() => _submitting = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This username is already taken. Please choose a different one.')),
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

      // If this is a Google sign-up, update the password
      if (widget.isGoogleSignUp && _passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text);
      }

      // Update local storage with username
      await authService.updateUsername(username);

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
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _usernameValidationError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    // Validate format first
    final authService = AuthService();
    final formatError = authService.validateUsername(username);
    
    if (formatError != null) {
      setState(() {
        _usernameValidationError = formatError;
        _isCheckingUsername = false;
      });
      return;
    }

    // Check availability after a delay to avoid too many requests
    setState(() {
      _isCheckingUsername = true;
      _usernameValidationError = null;
    });

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_usernameController.text.trim() == username && mounted) {
        try {
          final isTaken = await authService.isUsernameTaken(username);
          if (mounted) {
            setState(() {
              _isCheckingUsername = false;
              _usernameValidationError = isTaken ? 'Username is already taken' : null;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isCheckingUsername = false;
              _usernameValidationError = 'Error checking username availability';
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    _passwordController.dispose();
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
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Username is required';
                            }
                            if (_usernameValidationError != null) {
                              return _usernameValidationError;
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
                              borderSide: BorderSide(
                                color: _usernameValidationError != null 
                                    ? Colors.red 
                                    : Colors.white.withOpacity(0.25),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: _usernameValidationError != null 
                                    ? Colors.red 
                                    : AppColors.primaryGreen,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                            suffixIcon: _isCheckingUsername
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : _usernameValidationError == null && 
                                  _usernameController.text.trim().isNotEmpty
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : null,
                          ),
                        ),
                        if (_usernameValidationError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _usernameValidationError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.isGoogleSignUp) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        onChanged: _checkPasswordStrength,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Create password',
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
                      if (_passwordStrength.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Password strength: ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _passwordStrength,
                              style: TextStyle(
                                color: _passwordStrengthColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_submitting || 
                             _usernameValidationError != null || 
                             _isCheckingUsername || 
                             _usernameController.text.trim().isEmpty) 
                      ? null 
                      : _saveUsername,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_submitting || 
                                     _usernameValidationError != null || 
                                     _isCheckingUsername || 
                                     _usernameController.text.trim().isEmpty)
                        ? AppColors.darkGreen.withOpacity(0.5)
                        : AppColors.darkGreen,
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
