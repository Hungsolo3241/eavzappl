import 'dart:io';

import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';

import 'homeScreen/home_screen.dart'; // Added import

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized

  await Firebase.initializeApp(); // Initialize Firebase

  Get.put(AuthenticationController()); // Initialize AuthenticationController

  // Check if Firebase has already been initialized
  if (Firebase.apps.isEmpty) {
    if (Platform.isAndroid) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyBz0limZkm4u8KRp-qCnKLX8l1N7HvVeBQ",
            authDomain: "eavzappl-32891.firebaseapp.com",
            projectId: "eavzappl-32891",
            storageBucket: "eavzappl-32891.firebasestorage.app",
            messagingSenderId: "884472216905",
            appId: "1:884472216905:web:21026ec4ef01278436ae98",
            measurementId: "G-FP2ZLTCB9N"
        )
      );
    } else {
      // For other platforms, you might still need a default initialization
      // if they don't auto-initialize.
      await Firebase.initializeApp();
    }
  }
  // If Firebase.apps is not empty, it means Firebase was likely auto-initialized (e.g., on Android)
  // or initialized by a previous call, so we don't call initializeApp again.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context)
  {
    return GetMaterialApp(
      title: 'eavzappl',
      debugShowCheckedModeBanner: false,
      // Determine initial route based on auth state
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // Listen to authentication state changes
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          // Show a loading indicator while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold( // Or a dedicated splash screen widget
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // If snapshot has data and the user object is not null, user is logged in
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen(); // Go to HomeScreen
          } else {
            // User is not logged in
            return const LoginScreen(); // Go to LoginScreen
          }
        },
      ),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
    );
  }
}
