import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_utils.dart';
import '../services/auth_service.dart';
import 'ready_to_go_screen.dart';
import 'username_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailOrUsernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _submitting = false;

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    
    try {
      final emailOrUsername = _emailOrUsernameController.text.trim();
      final password = _passwordController.text;
      
      String? email;
      
      // Check if input is email or username
      if (emailOrUsername.contains('@')) {
        // It's an email
        email = emailOrUsername;
      } else {
        // It's a username, find the email from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: emailOrUsername)
            .limit(1)
            .get();
        
        if (userDoc.docs.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username not found')),
          );
          return;
        }
        
        email = userDoc.docs.first.data()['email'] as String?;
        if (email == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid user data')),
          );
          return;
        }
      }
      
      // Sign in with email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save login state to local storage
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final authService = AuthService();
        await authService.saveUserData(user);
      }
      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ReadyToGoScreen()),
      );
      
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email/username';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later';
          break;
        default:
          errorMessage = e.message ?? 'Sign in failed';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _submitting = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _submitting = false);
        return; // canceled
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      
      // Save login state to local storage
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final authService = AuthService();
        await authService.saveUserData(user);
        
        // Check if user has a username, if not, go to username screen
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (!userDoc.exists || userDoc.data()?['username'] == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => UsernameScreen(isGoogleSignUp: true)),
          );
          return;
        }
      }
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ReadyToGoScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Google sign-in failed')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 16),
              const Text(
                'Welcome back!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                "Let's get you signed in",
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    _Field(
                      label: 'Email or Username',
                      controller: _emailOrUsernameController,
                      keyboardType: TextInputType.text,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email or username is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: 'Password',
                      controller: _passwordController,
                      obscure: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _signInWithEmail,
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
                      : const Text(
                          'Sign In', 
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text('Or sign in with', style: TextStyle(color: Colors.white.withOpacity(0.7)))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _SocialButton(asset: 'assets/social/google.png', onTap: _submitting ? null : _continueWithGoogle),
                  const SizedBox(width: 18),
                  _SocialButton(asset: 'assets/social/facebook.png', onTap: null),
                  const SizedBox(width: 18),
                  _SocialButton(asset: 'assets/social/instagram.png', onTap: null),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;

  const _Field({
    required this.label, 
    required this.controller, 
    this.keyboardType, 
    this.obscure = false, 
    this.validator
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
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
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;
  const _SocialButton({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Widget icon = Image.asset(asset, height: 36, width: 36);
    return GestureDetector(onTap: onTap, child: icon);
  }
}
