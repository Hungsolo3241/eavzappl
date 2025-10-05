// lib/screens/splash_screen.dart
// (Assuming you've moved it to a more general 'screens' folder)

import 'dart:async';
import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/homeScreen/home_screen.dart';
import 'package:eavzappl/utils/image_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription? _authSubscription;
  StreamSubscription? _profileSubscription;

  // --- START: NEW STATE VARIABLE ---
  // This will hold the randomly selected image path for this instance of the splash screen.
  late final String _selectedSplashImage;
  // --- END: NEW STATE VARIABLE ---

  @override
  void initState() {
    super.initState();

    // --- START: CHOOSE RANDOM IMAGE ---
    // Select a random image from our constants file when the screen is first initialized.
    _selectedSplashImage = ImageConstants.getRandomSplashImage();
    // --- END: CHOOSE RANDOM IMAGE ---

    _setupNavigationListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _setupNavigationListeners() {
    // This logic remains the same.
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      final profileController = Get.find<ProfileController>();

      if (user != null) {
        if (profileController.isInitialized.value) {
          Get.offAll(() => const HomeScreen());
        } else {
          _profileSubscription = profileController.isInitialized.listen((isInitialized) {
            if (isInitialized) {
              Get.offAll(() => const HomeScreen());
              _profileSubscription?.cancel();
            }
          });
        }
      } else {
        Get.offAll(() => const LoginScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set a solid background color
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // --- USE THE STATE VARIABLE TO DISPLAY THE IMAGE ---
          Image.asset(
            _selectedSplashImage,
            fit: BoxFit.cover, // Use BoxFit.cover to fill the screen
            // Add an error builder for safety
            errorBuilder: (context, error, stackTrace) {
              // If the random image fails, fall back to the original login splash
              return Image.asset(ImageConstants.loginSplash, fit: BoxFit.cover);
            },
          ),
          // --- END OF CHANGE ---
          Container(
            // Add a subtle dark overlay to ensure the progress indicator is always visible
            color: Colors.black.withOpacity(0.3),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 50.0),
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
