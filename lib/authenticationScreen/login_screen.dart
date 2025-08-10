import 'package:flutter/material.dart';
import 'package:eavzappl/widgets/custom_text_field_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  TextEditingController? emailController = TextEditingController();
  TextEditingController? passwordController = TextEditingController();
  bool showProgressBar = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 50,),

            Image.asset(
                "images/logo.png",
            ),

            const SizedBox(height: 1.0), // Added SizedBox for spacing

            const Text(
              "come inside",
              style: TextStyle(
                fontSize: 30,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            //email
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

            //password
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

            //login button
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
                onTap: ()
                {

                },
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

            //don't have an account
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
                  onTap: ()
                  {
                    // Get.to(
                    //   () => const RegisterScreen(),
                    // );
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

            const SizedBox(
              height: 14,
            ),

            showProgressBar == true
                ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white12),
            )
                    : Container(),
          ],
        ),
      ),
    );
  }
}
