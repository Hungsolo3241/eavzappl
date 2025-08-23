import 'package:eavzappl/authenticationScreen/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:eavzappl/widgets/custom_text_field_widget.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';
import '../homeScreen/home_screen.dart';
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

    // Start loading: Show splash screen
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    bool loginSuccess = false;
    try {
      loginSuccess = await authenticationController.loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (loginSuccess) {
        // Login was successful
        // Ensure splash is visible, wait for 5 seconds
        print("Login successful, starting 5-second delay..."); // For debugging
        await Future.delayed(const Duration(seconds: 8));
        print("5-second delay finished."); // For debugging

        // Check if the widget is still mounted before navigating
        if (mounted) {
          Get.offAll(() => const HomeScreen());
          // After navigating, this screen is disposed, so isLoading state doesn't need to be manually reset.
        }
        return; // Exit after successful login and navigation
      }
      // If loginSuccess is false, the AuthenticationController should have shown a snackbar.
      // We will fall through to the finally block to hide the splash screen.

    } catch (error) {
      // Catch unexpected errors during the login process
      print("LOGIN SCREEN CAUGHT ERROR: $error"); // For debugging
      if (mounted) {
        Get.snackbar("Login Error", "An unexpected error occurred. Please try again.",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } finally {
      // This block will execute regardless of success or failure
      // If login was NOT successful AND the widget is still mounted, hide the splash screen.
      // If login was successful, we would have navigated and returned, so this setState might not even run,
      // or if it does, it's on a screen that's about to be disposed.
      if (!loginSuccess && mounted) {
        print("Login failed or error occurred, hiding splash screen."); // For debugging
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 140,),
                Image.asset(
                  "images/logo.png",
                  width: 300,
                  height: 275,
                ),
                const SizedBox(height: 80),
                const Text(
                  "  come inside",
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 45,
                  child: CustomTextFieldWidget(
                    editingController: emailController,
                    iconData: Icons.email_outlined,
                    labelText: "Email",
                    isObscure: false,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 45,
                  child: CustomTextFieldWidget(
                    editingController: passwordController,
                    iconData: Icons.lock_outline,
                    labelText: "Password",
                    isObscure: true,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 35,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                  child: InkWell(
                    onTap: _performLogin,
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
                const SizedBox(
                  height: 14,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Get.to(() => const RegistrationScreen());
                      },
                      child: const Text(
                        " Register",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14,),
              ],
            ),
          ),
          if (isLoading)
            const Positioned.fill(
              child: SplashScreen(),
            ),
        ],
      ),
    );
  }
}

