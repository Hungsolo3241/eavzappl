import 'package:eavzappl/authenticationScreen/registration_screen.dart';
import 'package:eavzappl/authenticationScreen/phone_auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:eavzappl/widgets/custom_text_field_widget.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';
import 'package:eavzappl/utils/snackbar_helper.dart';
import 'package:eavzappl/utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  final AuthenticationController authenticationController = Get.find<
      AuthenticationController>();

  Future<void> _performLogin() async {
    // Basic client-side validation
    if (emailController.text.trim().isEmpty) {
      SnackbarHelper.show(
        message: "Please enter your email.",
        isError: true,
        backgroundColor: AppTheme.textGrey.withOpacity(0.8),
      );
      return;
    }
    if (passwordController.text.trim().isEmpty) {
      SnackbarHelper.show(
        message: "Please enter your password.",
        isError: true,
        backgroundColor: AppTheme.textGrey.withOpacity(0.8),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // The auth listener will handle navigation, so we just await the result.
    bool loginSuccess = await authenticationController.loginUser(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (!loginSuccess && mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // in lib/authenticationScreen/login_screen.dart

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        // The Stack's children should be a list of widgets.
        children: [
          // WIDGET 1: The entire scrollable form.
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery
                    .of(context)
                    .size
                    .height * 0.15),
                Image.asset(
                  "images/logo.png",
                  width: 300,
                  height: 275,
                ),
                const SizedBox(height: 20),
                Text(
                  "",
                  style: AppTextStyles.heading1.copyWith(color: AppTheme.primaryYellow),
                ),
                const SizedBox(height: 30),
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
                const SizedBox(height: 20),
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
                const SizedBox(height: 30),
                Container(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 35,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryYellow, width: 2),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(25),
                    ),
                  ),
                  child: InkWell(
                    onTap: isLoading ? null : _performLogin,
                    child: Center(
                      child: Text(
                        "Login",
                        style: AppTextStyles.body1.copyWith(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.textGrey)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("OR", style: AppTextStyles.body1.copyWith(color: AppTheme.textGrey)),
                    ),
                    const Expanded(child: Divider(color: AppTheme.textGrey)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 35,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryYellow, width: 2),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(25),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Get.to(() => const PhoneAuthScreen());
                    },
                    child: Center(
                      child: Text(
                        "Sign in with Phone Number",
                        style: AppTextStyles.body1.copyWith(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: AppTextStyles.body1.copyWith(color: AppTheme.textGrey, fontSize: 18),
                    ),
                    InkWell(
                      onTap: () {
                        Get.to(() => const RegistrationScreen());
                      },
                      child: Text(
                        " Register",
                        style: AppTextStyles.body1.copyWith(color: AppTheme.primaryYellow, fontSize: 18, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40), // Add some padding at the bottom
              ],
            ),
          ), // <-- End of SingleChildScrollView

          // WIDGET 2: The loading overlay.
          // This is the correct place for it.
          if (isLoading)
            Container(
              color: Colors.black.withAlpha((255 * 0.5).round()),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
