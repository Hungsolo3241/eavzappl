import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Ensure this is imported
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'homeScreen/home_screen.dart';
import 'package:flutter/services.dart';
import 'package:eavzappl/pushNotifications/push_notifications.dart' as push_notifications_service;
import 'package:firebase_messaging/firebase_messaging.dart';


import 'package:firebase_app_check/firebase_app_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(push_notifications_service.firebaseMessagingBackgroundHandler);

  // Activate Firebase App Check AFTER Firebase.initializeApp()
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      // appleProvider: AppleProvider.appAttest, // For iOS, if you implement it
    );
    print("Firebase App Check activated successfully."); // Added success log
  } catch (e, stacktrace) { // Added stacktrace
    print("!!!!!!!!!! FIREBASE APP CHECK ACTIVATION FAILED !!!!!!!!!!");
    print("Error: $e");
    print("Stacktrace: $stacktrace");
  }
  // Initialize GetX controllers AFTER Firebase and App Check are ready.
  Get.put(AuthenticationController());
  Get.put(ProfileController());

  // Make the app go edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Optional: You might also want to set preferred orientations if your app is fixed
  // SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);

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
          // ...
          // Modified main.dart StreamBuilder
// ...
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          } else {
            final mediaQuery = MediaQuery.of(context);

            return MediaQuery(
              data: mediaQuery.removePadding(removeBottom: true), // Attempt to remove bottom padding
              child: const LoginScreen(),
            );
          }
// ...
        },
      ),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
    );
  }
}
