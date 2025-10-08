import 'package:flutter/material.dart';

/// Creates a right-to-left slide page transition.
PageRouteBuilder slideRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

/// App-wide color constants
class AppColors {
  static const Color primaryBackground = Color(0xFF201E1A);
  static const Color primaryGreen = Color(0xFFCDEDC6);
  static const Color lightGreen = Color(0xFFEDFDDE);
  static const Color darkGreen = Color(0xFF0E2B1C);
  static const Color secondaryBackground = Color(0xFF2A2723);
}
