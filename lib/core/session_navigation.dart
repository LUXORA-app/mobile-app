import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';

class SessionNavigation {
  SessionNavigation._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _isRedirecting = false;

  static void redirectToLogin() {
    if (_isRedirecting) {
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _isRedirecting = true;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      _isRedirecting = false;
    });
  }
}
