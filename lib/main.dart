import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/controllers/like_controller.dart';
// Note: We can simplify the SplashScreen import now, it doesn't need to be the home
import 'package:eavzappl/authenticationScreen/login_screen.dart'; // Or WaitingScreen
import 'package:flutter/services.dart';
// This can also be simplified as you don't use the prefix elsewhere in this file for Get.put
import 'package:eavzappl/pushNotifications/push_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:eavzappl/controllers/location_controller.dart';
import 'package:eavzappl/firebase_options.dart'; // <-- THIS IS THE FIX

// The background handler must be a top-level function (outside a class).
@pragma('vm:entry-point')
Future<void> main() async { // 1. Ensure your main function is marked 'async'
  try {
    // 2. This line is CRITICAL. It ensures Flutter is ready.
    WidgetsFlutterBinding.ensureInitialized();

    // 3. This line is the ENTIRE FIX. It forces the app to WAIT
    //    until Firebase is fully initialized before doing anything else.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );

    // 4. Now that Firebase is guaranteed to be ready, initialize your controllers.
    Get.put(AuthenticationController());
    Get.put(ProfileController());
    Get.put(LikeController());
    Get.put(LocationController());
    Get.put(PushNotifications());

  } catch (e) {
    print("!!! FATAL ERROR DURING INITIALIZATION: $e");
  }

  // 5. Finally, run the app.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Eavz',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      debugShowCheckedModeBanner: false,
      // The AuthenticationController's logic will handle showing the
      // correct screen (Login vs. Splash/Home).
      home: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
// Simple loading screen that allows the AuthenticationController to work
class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
