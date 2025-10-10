import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sendgrid_email_service.dart';

class OtpService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SendGridEmailService emailService;

  OtpService({required this.emailService});

  String _generateOtp() {
    final random = Random.secure();
    return List.generate(4, (_) => random.nextInt(10)).join();
  }

  Future<void> sendOtpToCurrentUser({required String toEmail}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final otp = _generateOtp();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));

    await _db.collection('emailOtps').doc(user.uid).set({
      'email': toEmail,
      'otp': otp,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'verified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await emailService.sendOtpEmail(toEmail: toEmail, otpCode: otp);
  }

  Future<bool> verifyOtp({required String code}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final docRef = _db.collection('emailOtps').doc(user.uid);
    final snap = await docRef.get();
    if (!snap.exists) return false;

    final data = snap.data()!;
    final storedOtp = data['otp'] as String?;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (storedOtp == null || expiresAt == null) return false;
    if (DateTime.now().isAfter(expiresAt)) return false;
    if (storedOtp != code) return false;

    // Mark verified in otp doc
    await docRef.update({'verified': true});

    // Mark Firebase user as verified flag in Firestore `users/{uid}`
    await _db.collection('users').doc(user.uid).set({'emailVerified': true}, SetOptions(merge: true));

    // For Firebase Auth emailVerified still false (since not using link). Keep auth guard using Firestore flag.
    return true;
  }

  Stream<bool> verificationStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream<bool>.empty();
    }
    return _db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((s) => (s.data()?['emailVerified'] as bool?) ?? false);
  }
}


