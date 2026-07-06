import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
import '../../widgets/app_background.dart';
import '../../core/app_colors.dart';
import '../auth/login_screen.dart';
import '../home/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _goNext);
  }

  Future<void> _goNext() async {
    final token = await AuthStorage.getToken();
    if (!mounted) return;

    final nextScreen = (token != null && token.isNotEmpty)
        ? const MainScreen()
        : const LoginScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/logo.png", // غيري الاسم لو مختلف
              width: 150,
            ),
            const SizedBox(height: 20),
              const Text(
              "LUXORA",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Let The Ancient Walls Speak",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primary,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}