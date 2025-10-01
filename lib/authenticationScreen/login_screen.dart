import 'dart:math' as math;
import 'package:eavzappl/authenticationScreen/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:eavzappl/widgets/custom_text_field_widget.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';
import 'package:eavzappl/splashScreen/splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  final AuthenticationController authenticationController = Get.find<AuthenticationController>();

  Future<void> _performLogin() async {
    // Basic client-side validation
    if (emailController.text.trim().isEmpty) {
      Get.snackbar("Validation Error", "Please enter your email.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }
    if (passwordController.text.trim().isEmpty) {
      Get.snackbar("Validation Error", "Please enter your password.",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      bool loginSuccess = await authenticationController.loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (loginSuccess) {
        // On success, navigate to the splash screen which will handle the next step
        Get.offAll(() => const SplashScreen());
      } else {
        // If login fails, the controller shows a snackbar. We just need to stop loading.
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        Get.snackbar("Login Error", "An unexpected error occurred: ${error.toString()}",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                Image.asset(
                  "images/logo.png",
                  width: 300,
                  height: 275,
                ),
                const SizedBox(height: 20),
                Text(
                  "come inside",
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.yellow[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                CustomTextFieldWidget(
                  editingController: emailController,
                  iconData: Icons.email_outlined,
                  labelText: "Email",
                  isObscure: false,
                ),
                const SizedBox(height: 20),
                CustomTextFieldWidget(
                  editingController: passwordController,
                  iconData: Icons.lock_outline,
                  labelText: "Password",
                  isObscure: true,
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.yellow[700],
                    borderRadius: const BorderRadius.all(
                      Radius.circular(25),
                    ),
                  ),
                  child: InkWell(
                    onTap: isLoading ? null : _performLogin,
                    child: const Center(
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 18,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Get.to(() => const RegistrationScreen());
                      },
                      child: Text(
                        " Register",
                        style: TextStyle(
                          color: Colors.yellow[700],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
