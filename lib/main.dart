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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:async';
import 'dart:ui';

import 'package:eavzappl/utils/app_theme.dart';

// The background handler must be a top-level function (outside a class).
@pragma('vm:entry-point')
Future<void> main() async { // 1. Ensure your main function is marked 'async'
  await runZonedGuarded(() async {
    // 2. This line is CRITICAL. It ensures Flutter is ready.
    WidgetsFlutterBinding.ensureInitialized();

    // ← LOAD ENVIRONMENT VARIABLES FIRST
    await dotenv.load(fileName: ".env");

    // 3. This line is the ENTIRE FIX. It forces the app to WAIT
    //    until Firebase is fully initialized before doing anything else.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );

    // ✅ Setup Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // ✅ Setup Analytics
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    await analytics.logAppOpen();

    // 5. Finally, run the app.
    runApp(const MyApp());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    print("!!! FATAL ERROR DURING INITIALIZATION: $error");
  });
}

// Function to initialize controllers and other services that can be deferred
Future<void> _initializeControllersAndServices() async {
  // ← LOAD ENVIRONMENT VARIABLES FIRST
  await dotenv.load(fileName: ".env");

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // Initialize your controllers.
  Get.put(AuthenticationController()); // Essential
  Get.lazyPut(() => ProfileController()); // Lazy load
  Get.lazyPut(() => LikeController());
  Get.lazyPut(() => LocationController());
  Get.lazyPut(() => PushNotifications());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Eavz',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      // Use a FutureBuilder to show a loading screen while initializations are in progress
      home: FutureBuilder(
        future: _initializeControllersAndServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Once initializations are complete, let AuthenticationController handle navigation
            return const WaitingScreen(); // AuthenticationController will redirect from here
          }
          // Show a loading indicator while waiting
          return const WaitingScreen();
        },
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
