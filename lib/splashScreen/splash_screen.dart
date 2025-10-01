import 'dart:async';
import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/homeScreen/home_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _setupNavigationListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  void _setupNavigationListeners() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      // Find the controller *after* the auth state has changed.
      final profileController = Get.find<ProfileController>();

      // This listener will fire once upon app start, and again on login/logout.
      if (user != null) {
        // User is logged in.
        // First, check if the profile is ALREADY initialized. This handles the race condition
        if (profileController.isInitialized.value) {
          Get.offAll(() => const HomeScreen());
        } else {
          // Otherwise, listen for the change.
          _profileSubscription = profileController.isInitialized.listen((isInitialized) {
            if (isInitialized) {
              Get.offAll(() => const HomeScreen());
              _profileSubscription?.cancel(); // Clean up the listener.
            }
          });
        }
      } else {
        // User is not logged in, go to login screen.
        Get.offAll(() => const LoginScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Keeps the Scaffold itself transparent
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Container( // New Container to provide a background for BoxFit.contain
        color: Colors.black, // Background color for empty areas
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(
                'images/loginSplashScreen.jpeg',
                fit: BoxFit.contain, // Changed from BoxFit.cover
              ),
            ),
            // Align widget for the CircularProgressIndicator at the bottom
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 50.0), // Adjust as needed
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
