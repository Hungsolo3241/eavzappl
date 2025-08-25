import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Ensure this is imported
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'homeScreen/home_screen.dart';

// Import App Check
import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Simplest Firebase Initialization.
  // This relies on your project's `google-services.json` (for Android)
  // or `GoogleService-Info.plist` (for iOS) being correctly set up
  // and providing all necessary Firebase options.
  // The Firebase SDK should handle cases where native initialization already occurred.
  await Firebase.initializeApp();

  // Activate Firebase App Check AFTER Firebase.initializeApp()
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      // appleProvider: AppleProvider.appAttest, // For iOS, if you implement it
    );
    print('Firebase App Check activated successfully.');
  } catch (e) {
    print('Error activating Firebase App Check: $e');
    // It's crucial to handle App Check activation failure in a real app.
    // For now, this just prints the error.
  }

  // Initialize your GetX controllers AFTER Firebase and App Check are ready.
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
