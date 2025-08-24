import 'dart:io'; // Keep for Platform.isAndroid

import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'homeScreen/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Define the FirebaseOptions for Android if needed
  const FirebaseOptions androidOptions = FirebaseOptions(
      apiKey: "AIzaSyBz0limZkm4u8KRp-qCnKLX8l1N7HvVeBQ",
      authDomain: "eavzappl-32891.firebaseapp.com",
      projectId: "eavzappl-32891",
      storageBucket: "eavzappl-32891.firebasestorage.app",
      messagingSenderId: "884472216905",
      appId: "1:884472216905:web:21026ec4ef01278436ae98",
      measurementId: "G-FP2ZLTCB9N"
  );

  // Initialize Firebase ONCE.
  // Pass options directly if on Android, otherwise use default initialization
  // (which relies on google-services.json for Android if no options passed,
  // or GoogleService-Info.plist for iOS, or firebase_options.dart).
  if (Platform.isAndroid) {
    await Firebase.initializeApp(options: androidOptions);
  } else {
    // For iOS and other platforms, initialize without explicit options.
    // This assumes you have GoogleService-Info.plist set up for iOS,
    // or are using `firebase_options.dart` from `flutterfire configure`.
    await Firebase.initializeApp();
  }

  // Initialize your GetX controllers after Firebase is successfully initialized.
  Get.put(AuthenticationController());
  Get.put(ProfileController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'eavzappl',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
    );
  }
}
