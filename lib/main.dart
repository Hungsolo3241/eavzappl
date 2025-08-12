import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart'; // Added import

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
  Get.put(AuthenticationController()); // Initialize AuthenticationController
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
