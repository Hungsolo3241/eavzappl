import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:eavzappl/accountSettingsScreen/edit_profile_screen.dart'; // Navigates to EditProfileScreen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// NO import for 'user_settings_screen.dart' itself

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {

  Future<void> _signOutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      Get.snackbar(
        "Logout Failed",
        "An error occurred: ${e.toString()}",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitleTextStyle = const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold);
    final appBarIconTheme = const IconThemeData(color: Colors.green);
    final appBarBackgroundColor = Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        titleTextStyle: appBarTitleTextStyle,
        iconTheme: appBarIconTheme,
        backgroundColor: appBarBackgroundColor,
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.green),
            title: const Text("Edit Profile", style: TextStyle(color: Colors.green)),
            onTap: () async {
              // IMPORTANT REMINDER FOR FUTURE PROFILE EDITING UI:
              // The 'orientation' field MUST NOT be editable by the user.
              // This is a core business logic rule. Ensure any profile editing
              // screen or function enforces this by not providing an input field
              // for 'orientation' or by ignoring any attempts to change it.
              // The current user's orientation should be loaded and displayed,
              // but never submitted as part of an update.
              var editProfileResult = await Get.to(() => const EditProfileScreen());
              if (editProfileResult == true) {
                Get.back(result: true);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.green),
            title: const Text("Notifications", style: TextStyle(color: Colors.green)),
            onTap: () {
              Get.snackbar("Coming Soon", "Notification settings are not yet implemented.", colorText: Colors.white);
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts, color: Colors.green),
            title: const Text("Account Management", style: TextStyle(color: Colors.green)),
            onTap: () {
              Get.snackbar("Coming Soon", "Account management options are not yet implemented.", colorText: Colors.white);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.green),
            title: const Text("About", style: TextStyle(color: Colors.green)),
            onTap: () {
              Get.snackbar("App Info", "EAVZ App v1.0.0", colorText: Colors.white);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              _signOutUser();
            },
          ),
        ],
      ),
    );
  }
}
