import 'dart:io';

import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart'; // Added import

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'eavzappl',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black
      ),
      debugShowCheckedModeBanner: false,
      home: LoginScreen( ),
    );
  }
}
