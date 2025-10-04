import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:eavzappl/accountSettingsScreen/edit_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:eavzappl/accountSettingsScreen/notifications_screen.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';
import 'package:eavzappl/controllers/profile_controller.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  // The AuthenticationController instance.
  final AuthenticationController authController = Get.find<AuthenticationController>();

  Future<void> _showReauthenticationDialog({
    required BuildContext context,
    required String title,
    required Future<void> Function() onAuthenticated, // Removed password argument as it's not directly needed by the caller of this generic dialog
  }) async {
    final TextEditingController passwordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isLoading = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: !isLoading,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.grey[850],
              title: Text(title, style: TextStyle(color: Colors.blueGrey)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "For your security, please enter your current password to continue.",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Current Password",
                        labelStyle: TextStyle(color: Colors.blueGrey),
                        prefixIcon: Icon(Icons.lock, color: Colors.blueGrey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey, width: 2.0), borderRadius: BorderRadius.circular(8.0)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8.0)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Password cannot be empty.";
                        }
                        return null;
                      },
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 15),
                      const CircularProgressIndicator(color: Colors.blueGrey),
                    ]
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setStateDialog(() {
                        isLoading = true;
                      });
                      try {
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user != null && user.email != null) {
                          AuthCredential credential = EmailAuthProvider.credential(
                            email: user.email!,
                            password: passwordController.text.trim(),
                          );
                          await user.reauthenticateWithCredential(credential);
                          Navigator.of(dialogContext).pop(); 
                          await onAuthenticated(); 
                        } else {
                          throw FirebaseAuthException(code: "user-not-found", message: "No user found or email is null.");
                        }
                      } on FirebaseAuthException catch (e) {
                        Get.snackbar(
                          "Re-authentication Failed",
                          e.message ?? "An error occurred.",
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      } catch (e) {
                        Get.snackbar(
                          "Error",
                          "An unexpected error occurred: ${e.toString()}",
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      } finally {
                        if (mounted && dialogContext.mounted) { // Check if the dialog is still mounted
                           setStateDialog(() {
                             isLoading = false;
                           });
                        }
                      }
                    }
                  },
                  child: Text("Confirm", style: TextStyle(color: Colors.blueGrey)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _showChangeEmailDialog(BuildContext context) async {
    final TextEditingController newEmailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isLoading = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: !isLoading,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.grey[850],
              title: const Text("Change Email Address", style: TextStyle(color: Colors.blueGrey)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: newEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "New Email Address",
                        labelStyle: TextStyle(color: Colors.blueGrey),
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.blueGrey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey, width: 2.0), borderRadius: BorderRadius.circular(8.0)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8.0)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "New email cannot be empty.";
                        }
                        if (!GetUtils.isEmail(value.trim())) {
                          return "Please enter a valid email address.";
                        }
                        return null;
                      },
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 15),
                      const CircularProgressIndicator(color: Colors.blueGrey),
                    ]
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                ),
                TextButton(
                  child: const Text("Update Email", style: TextStyle(color: Colors.blueGrey)),
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setStateDialog(() {
                        isLoading = true;
                      });
                      try {
                        User? user = FirebaseAuth.instance.currentUser;
                        String newEmail = newEmailController.text.trim();
                        
                        await user?.verifyBeforeUpdateEmail(newEmail); 
                        
                        Navigator.of(dialogContext).pop();
                        Get.snackbar(
                          "Verification Sent",
                          "A verification email has been sent to $newEmail. Please verify to complete the email change.",
                          backgroundColor: Colors.blueGrey,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 5),
                        );
                      } on FirebaseAuthException catch (e) {
                         String errorMessage = e.message ?? "An error occurred.";
                         if (e.code == 'email-already-in-use') {
                           errorMessage = "This email address is already in use by another account.";
                         } else if (e.code == 'requires-recent-login') {
                            errorMessage = "This operation is sensitive and requires recent authentication. Please log out and log back in before trying again.";
                         }
                        Get.snackbar(
                          "Update Failed",
                          errorMessage,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      } catch (e) {
                        Get.snackbar(
                          "Error",
                          "An unexpected error occurred: ${e.toString()}",
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      } finally {
                         if (mounted && dialogContext.mounted) { 
                           setStateDialog(() {
                             isLoading = false;
                           });
                        }
                      }
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  int _calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r"""[!@#$%^&*(),.?":{}|<>';]"""))) strength++; // Changed to r"""..."""
    return strength;
  }

  String _getPasswordStrengthText(int strength) {
    switch (strength) {
      case 0: case 1: case 2: return "Weak";
      case 3: return "Medium";
      case 4: return "Strong";
      case 5: return "Very Strong";
      default: return "Weak";
    }
  }

  Color _getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0: case 1: case 2: return Colors.red;
      case 3: return Colors.orange;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.red;
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isLoading = false;
    int passwordStrength = 0;

    return showDialog<void>(
      context: context,
      barrierDismissible: !isLoading,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.grey[850],
              title: const Text("Change Password", style: TextStyle(color: Colors.blueGrey)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "New Password",
                        labelStyle: TextStyle(color: Colors.blueGrey),
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.blueGrey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey, width: 2.0), borderRadius: BorderRadius.circular(8.0)),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          passwordStrength = _calculatePasswordStrength(value);
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "New password cannot be empty.";
                        }
                        if (value.length < 8) {
                          return "Password must be at least 8 characters.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 5),
                    if (newPasswordController.text.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Strength: ${_getPasswordStrengthText(passwordStrength)}",
                          style: TextStyle(color: _getPasswordStrengthColor(passwordStrength)),
                        ),
                      ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Confirm New Password",
                        labelStyle: TextStyle(color: Colors.blueGrey),
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.blueGrey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey, width: 2.0), borderRadius: BorderRadius.circular(8.0)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please confirm your new password.";
                        }
                        if (value != newPasswordController.text) {
                          return "Passwords do not match.";
                        }
                        return null;
                      },
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 15),
                      const CircularProgressIndicator(color: Colors.blueGrey),
                    ]
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                ),
                TextButton(
                  child: const Text("Update Password", style: TextStyle(color: Colors.blueGrey)),
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setStateDialog(() { isLoading = true; });
                      try {
                        User? user = FirebaseAuth.instance.currentUser;
                        await user?.updatePassword(newPasswordController.text.trim());
                        
                        // Update passwordLastChanged in Firestore
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .update({'passwordLastChanged': FieldValue.serverTimestamp()});
                        }

                        Navigator.of(dialogContext).pop();
                        Get.snackbar(
                          "Success",
                          "Password updated successfully.",
                          backgroundColor: Colors.blueGrey,
                          colorText: Colors.white,
                        );
                      } on FirebaseAuthException catch (e) {
                        Get.snackbar(
                          "Update Failed",
                          e.message ?? "An error occurred during password update.",
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      } catch (e) {
                        Get.snackbar(
                          "Error",
                          "An unexpected error occurred: ${e.toString()}",
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      } finally {
                        if (mounted && dialogContext.mounted) {
                          setStateDialog(() { isLoading = false; });
                        }
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAccountSecurityInfoDialog(BuildContext context) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar("Error", "User not logged in.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    String email = currentUser.email ?? "Not available";
    String accountCreated = "Not available";
    if (currentUser.metadata.creationTime != null) {
      accountCreated = DateFormat.yMMMMd().add_jm().format(currentUser.metadata.creationTime!);
    }
    
    String passwordLastChanged = "Never or not recorded";
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('passwordLastChanged') && data['passwordLastChanged'] != null) {
          Timestamp ts = data['passwordLastChanged'];
          passwordLastChanged = DateFormat.yMMMMd().add_jm().format(ts.toDate());
        }
      }
    } catch (e) {
      // Ignore error, default message will be shown
      print("Error fetching passwordLastChanged: $e");
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text("Account Security", style: TextStyle(color: Colors.blueGrey)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildSecurityInfoRow("Email:", email),
                _buildSecurityInfoRow("Account Created:", accountCreated),
                _buildSecurityInfoRow("Password Last Changed:", passwordLastChanged),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("OK", style: TextStyle(color: Colors.blueGrey)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecurityInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountConfirmationDialog(BuildContext context) async {
    bool isLoading = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: !isLoading,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: Colors.grey[850],
                title: const Text("Delete Account?", style: TextStyle(color: Colors.redAccent)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "This action is permanent and cannot be undone. All your data associated with this account will be deleted.",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "Are you sure you want to proceed?",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 15),
                      const CircularProgressIndicator(color: Colors.redAccent),
                    ]
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                    onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                  ),
                  TextButton(
                    child: const Text("Delete My Account", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onPressed: isLoading ? null : () async {
                      setStateDialog(() { isLoading = true; });
                      try {
                        User? user = FirebaseAuth.instance.currentUser;
                        // TODO: Implement Firestore data deletion here or via a Cloud Function.
                        // Example: await FirebaseFirestore.instance.collection('users').doc(user?.uid).delete();
                        // This is crucial to remove user's data from your database.
                        // The most robust way is a Cloud Function triggered by Auth user deletion.
                        
                        await user?.delete();
                        
                        Navigator.of(dialogContext).pop(); // Close confirmation dialog
                        Get.offAll(() => const LoginScreen()); // Navigate to login
                        Get.snackbar(
                          "Account Deleted",
                          "Your account has been permanently deleted.",
                          backgroundColor: Colors.blueGrey,
                          colorText: Colors.white,
                        );
                      } on FirebaseAuthException catch (e) {
                         String errorMessage = e.message ?? "An error occurred while deleting your account.";
                         if (e.code == 'requires-recent-login') {
                           errorMessage = "This operation is sensitive and requires recent authentication. Please log out, log back in, and try again.";
                         }
                        Get.snackbar(
                          "Deletion Failed",
                          errorMessage,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      } catch (e) {
                        Get.snackbar(
                          "Error",
                          "An unexpected error occurred: ${e.toString()}",
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      } finally {
                        if (mounted && dialogContext.mounted) {
                           setStateDialog(() { isLoading = false; });
                        }
                      }
                    },
                  ),
                ],
              );
            }
        );
      },
    );
  }


  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Settings"),
        titleTextStyle: const TextStyle(color: Colors.blueGrey, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.blueGrey),
        backgroundColor: Colors.black54,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueGrey),
            tooltip: 'Log Out',
            onPressed: () async {
              // Re-using the same confirmation dialog logic
              bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.grey[850],
                    title: const Text('Log Out', style: TextStyle(color: Colors.blueGrey)),
                    content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                // CORRECT: Calling the controller's logout method to reset state.
                await authController.logoutUser();
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.edit, color: Colors.yellow[700]),
            title: const Text("Edit Profile", style: TextStyle(color: Colors.blueGrey)),
            onTap: () async { // Make the function async

              // Await the result from EditProfileScreen
              final result = await Get.to(() => const EditProfileScreen());

              // If the result is true, it means the profile was saved successfully
              if (result == true) {
                // Find the ProfileController and force it to reload everything
                // This will update all profile lists across the app.
                final ProfileController profileController = Get.find();
                await profileController.forceReload();

                // Optionally, you can also pop the settings screen to go back to the main view
                // to see the changes immediately.
                Get.back();
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.email_outlined, color: Colors.yellow[700]),
            title: const Text("Change Email", style: TextStyle(color: Colors.blueGrey)),
            onTap: () {
              _showReauthenticationDialog(
                context: context,
                title: "Change Email",
                onAuthenticated: () async {
                  await _showChangeEmailDialog(context);
                },
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.password, color: Colors.yellow[700]),
            title: const Text("Change Password", style: TextStyle(color: Colors.blueGrey)),
            onTap: () {
              _showReauthenticationDialog(
                context: context,
                title: "Change Password",
                onAuthenticated: () async {
                  await _showChangePasswordDialog(context);
                },
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.shield_outlined, color: Colors.yellow[700]),
            title: const Text("Account Security", style: TextStyle(color: Colors.blueGrey)),
            onTap: () {
              _showAccountSecurityInfoDialog(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications, color: Colors.yellow[700]),
            title: const Text("Notifications", style: TextStyle(color: Colors.blueGrey)),
            onTap: () {
              Get.to(() => const NotificationsScreen());
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.yellow[700]),
            title: const Text("About", style: TextStyle(color: Colors.blueGrey)),
            onTap: () {
              Get.snackbar("App Info", "EAVZ App v1.0.0", colorText: Colors.white);
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text("Delete Account", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              _showReauthenticationDialog(
                context: context,
                title: "Delete Account",
                onAuthenticated: () async {
                  await _showDeleteAccountConfirmationDialog(context);
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.blueGrey),
            title: const Text('Log Out', style: TextStyle(color: Colors.white)),
            onTap: () async {
              bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.grey[850],
                    title: const Text('Log Out', style: TextStyle(color: Colors.blueGrey)),
                    content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                // CORRECT: Call the controller's logout method which resets state.
                await authController.logoutUser();
              }
            },
          ),
        ],
      ),
    );
  }
}
