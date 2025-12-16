import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/colors.dart'; // Ensure you have your colors file
import 'wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait 3 seconds, then move to Wrapper
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pumpkinOrange, // #FF6D30
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. LOGO
            // Since it's 4:1 (Wide), we add padding so it doesn't touch the edges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: Image.asset(
                'assets/logo.png',
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 2. TEXT
            const Text(
              "Pulangkan barang ke pemiliknya",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            
            const SizedBox(height: 50), // Visual balance
            
            // Optional: Loading Indicator at bottom
            const CircularProgressIndicator(
              color: Colors.white, 
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}