import 'package:eavzappl/controllers/authentication_controller.dart';
import 'package:eavzappl/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:eavzappl/utils/app_theme.dart';


class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});
 
  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final AuthenticationController _authController = Get.find();
  final TextEditingController _smsCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isCodeSent = false;
  String _fullPhoneNumber = '';

  void _sendCode() {
    if (_fullPhoneNumber.isEmpty) {
      Get.snackbar("Input Error", "Please enter a valid phone number.",
          backgroundColor: Colors.redAccent, colorText: AppTheme.textLight);
      return;
    }
    setState(() {
      _isLoading = true;
    });
    _authController.verifyPhoneNumber(_fullPhoneNumber, onCodeSent: (success) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (success) {
            _isCodeSent = true;
          }
        });
      }
    });
  }

  void _verifyCode() async {
    if (_smsCodeController.text.trim().isEmpty) {
      Get.snackbar("Input Error", "Please enter the code you received.",
          backgroundColor: Colors.redAccent, colorText: AppTheme.textLight);
      return;
    }
    setState(() {
      _isLoading = true;
    });

    bool success = await _authController.signInWithSmsCode(_smsCodeController.text.trim());

    if (!success && mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    // On success, the main auth listener will handle navigation automatically.
  }

  Widget _buildPhoneNumberInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Enter Your Phone Number", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
        const SizedBox(height: 30),
        SizedBox(
          width: MediaQuery.of(context).size.width - 40,
          height: 45,
          child: IntlPhoneField(
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              labelStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(borderSide: BorderSide()),
            ),
            initialCountryCode: 'ZA', // Default to South Africa
            onChanged: (phone) {
              _fullPhoneNumber = phone.completeNumber;
            },
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: MediaQuery.of(context).size.width - 40,
          height: 35,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendCode,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
            child: _isLoading
                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundDark))
                : const Text("Send Code", style: TextStyle(color: AppTheme.backgroundDark, fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildSmsCodeInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Enter Code Sent to $_fullPhoneNumber", textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: AppTheme.textLight)),
        const SizedBox(height: 30),
        SizedBox(
          width: MediaQuery.of(context).size.width - 40,
          height: 45,
          child: CustomTextFieldWidget(
            editingController: _smsCodeController,
            labelText: "6-Digit Code",
            iconData: Icons.sms,
            isObscure: false,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: MediaQuery.of(context).size.width - 40,
          height: 35,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
            child: _isLoading
                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundDark))
                : const Text("Verify & Sign In", style: TextStyle(color: AppTheme.backgroundDark, fontSize: 18)),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isCodeSent = false;
            });
          },
          child: Text("Use a different number?", style: TextStyle(color: AppTheme.primaryYellow)),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign in with Phone"),
        backgroundColor: AppTheme.backgroundDark,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: _isCodeSent ? _buildSmsCodeInput() : _buildPhoneNumberInput(),
        ),
      ),
    );
  }
}