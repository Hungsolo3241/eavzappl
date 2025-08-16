// lib/splashScreen/splash_screen.dart
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback color
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Background Image (retains previous alignment adjustment)
          Image.asset(
            'images/login_splash.jpeg',
            fit: BoxFit.cover,
            alignment: const Alignment(0.0, -0.2), // Keeps the image slightly shifted down
          ),

          // Align widget for the CircularProgressIndicator at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // Add some padding from the bottom edge
              padding: const EdgeInsets.only(bottom: 50.0), // Adjust padding as needed
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}