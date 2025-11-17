import 'package:eavzappl/bindings/initial_bindings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:eavzappl/pushNotifications/push_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:eavzappl/firebase_options.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:async';
import 'dart:ui';

@pragma('vm:entry-point')
Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );

    final token = await FirebaseAppCheck.instance.getToken(true);
    print('App Check debug token: $token');

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    await analytics.logAppOpen();

    runApp(const MyApp());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    print("!!! FATAL ERROR DURING INITIALIZATION: $error");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Eavz',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBindings(),
      home: const WaitingScreen(),
      
      builder: (context, child) {
    return child!;  // Force non-null → GetX always has valid overlay context
  },

  //ALSO ADD THESE TWO LINES (critical for Get.offAll stability)
  transitionDuration: Duration.zero,
  defaultTransition: Transition.noTransition,
    );
  }
}

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}