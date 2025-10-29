import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/controllers/like_controller.dart';
import 'package:eavzappl/splashScreen/splash_screen.dart';
import 'package:flutter/services.dart';
import 'package:eavzappl/pushNotifications/push_notifications.dart' as push_notifications_service;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:eavzappl/models/filter_preferences.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:eavzappl/controllers/location_controller.dart';
import 'package:eavzappl/bindings/initial_bindings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(push_notifications_service.firebaseMessagingBackgroundHandler);
  // Activate Firebase App Check AFTER Firebase.initializeApp()
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest, // For iOS
    );

  // Make the app go edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Optional: Set preferred orientations to portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'eavzappl',
      debugShowCheckedModeBanner: false,
      home: const WaitingScreen(),
      initialBinding: InitialBindings(),

      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
    );
  }
}

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