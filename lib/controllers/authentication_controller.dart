// lib/controllers/authentication_controller.dart

// --- START OF FIXES: ADD ALL MISSING IMPORTS ---
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:eavzappl/homeScreen/home_screen.dart';
import 'package:eavzappl/models/person.dart' as personModel;
import 'package:eavzappl/splashScreen/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img; // <-- FIX: For image processing (img.decodeImage)
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // <-- FIX: For getTemporaryDirectory

// Import the controllers you need to reference
import 'profile_controller.dart'; // <-- FIX: To recognize ProfileController
import 'like_controller.dart';    // <-- FIX: To recognize LikeController
// --- END OF FIXES ---


class AuthenticationController extends GetxController {
  static AuthenticationController get instance => Get.find();

  final Rx<User?> _firebaseUser = Rx<User?>(null);
  User? get user => _firebaseUser.value;

  final verificationId = ''.obs;
  bool _hasInitialized = false;

  @override
  void onReady() {
    super.onReady();
    _firebaseUser.value = FirebaseAuth.instance.currentUser;
    _firebaseUser.bindStream(FirebaseAuth.instance.authStateChanges());
    ever(_firebaseUser, _setInitialScreen);
    _setInitialScreen(_firebaseUser.value);
  }

  // lib/controllers/authentication_controller.dart

// ... inside the AuthenticationController class ...

  void _setInitialScreen(User? user) async { // Add async
    if (user == null) {
      log("User is null, navigating to LoginScreen");
      _hasInitialized = false;

      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().clearAllSubscriptions();
      }
      if (Get.isRegistered<LikeController>()) {
        Get.find<LikeController>().clear();
      }

      Get.offAll(() => const LoginScreen());
    } else {
      if (_hasInitialized) return;

      log("User is not null, navigating to SplashScreen");
      Get.offAll(() => const SplashScreen());
      _hasInitialized = true;

      final profileController = Get.find<ProfileController>();
      profileController.initializeUserStreams(user.uid);

      const minimumSplashDuration = Duration(seconds: 3);
      final splashTimer = Future.delayed(minimumSplashDuration);

      // Add a timeout to the data loading future to prevent getting stuck
      final dataLoadingFuture = profileController.initialization.timeout(
        const Duration(seconds: 10), // 10-second timeout
        onTimeout: () {
          log("Data loading timed out.", name: "AuthenticationController");
          // You might want to navigate to an error screen or just proceed
          return;
        },
      );

      // Wait for both the splash timer and data loading (with timeout) to complete
      await Future.wait([
        splashTimer,
        dataLoadingFuture,
      ]);

      log("Splash screen duration and data loading complete, navigating to HomeScreen");
      Get.offAll(() => const HomeScreen());
    }
  }


  // Phone Auth
  Future<void> verifyPhoneNumber(String phoneNumber, {required Function(bool) onCodeSent}) async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          Get.snackbar("Verification Failed", e.message ?? "An unknown error occurred.", backgroundColor: Colors.redAccent, colorText: Colors.white);
          onCodeSent(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          this.verificationId.value = verificationId;
          onCodeSent(true);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId.value = verificationId;
        },
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to start phone number verification: ${e.toString()}", backgroundColor: Colors.redAccent, colorText: Colors.white);
      onCodeSent(false);
    }
  }

  Future<bool> signInWithSmsCode(String smsCode) async {
    if (verificationId.value.isEmpty) {
      Get.snackbar("Error", "Verification ID is missing. Please try sending the code again.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: smsCode,
      );
      await signInWithPhoneCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Sign-in Failed", e.message ?? "Invalid code or an error occurred.", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred: ${e.toString()}", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return false;
    }
  }

  Future<void> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: user.phoneNumber)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          // New user, create a document
          personModel.Person personInstance = personModel.Person(
            uid: user.uid,
            phoneNumber: user.phoneNumber,
            publishedDateTime: DateTime.now().millisecondsSinceEpoch,
            // Initialize other fields with default or empty values
            email: '', name: '', username: '', orientation: 'adam', profilePhoto: null, gender: '',
            age: null, country: '', province: '', city: '', lookingForBreakfast: false, lookingForLunch: false,
            lookingForDinner: false, lookingForLongTerm: false, height: '', bodyType: '', drinkSelection: false,
            smokeSelection: false, meatSelection: false, greekSelection: false, hostSelection: false, travelSelection: false,
            profession: '', income: '', professionalVenues: [], otherProfessionalVenue: '',
            ethnicity: '', nationality: '', languages: '', instagram: '', twitter: '',
          );
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(personInstance.toJson());
        }
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Sign-in Failed", e.message ?? "An error occurred during sign-in.", backgroundColor: Colors.redAccent, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred: ${e.toString()}", backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // Email/Password Auth
  Future<bool> loginUser(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Invalid credentials. Please try again.";
      if (e.code == 'invalid-email') { errorMessage = 'The email address is not valid.'; }
      else if (e.code == 'user-disabled') { errorMessage = 'This user account has been disabled.'; }
      Get.snackbar("Login Failed", errorMessage, backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false;
    } catch (error) {
      Get.snackbar("Login Failed", "An unexpected error occurred.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false;
    }
  }

  // Logout
  Future<void> signOutUser() async {
    log('[AuthCtrl] Initiating sign out.');

    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().clearAllSubscriptions();
    }
    if (Get.isRegistered<LikeController>()) {
      Get.find<LikeController>().clear(); // <-- FIX: Renamed 'clearAllSubscriptions' to 'clear' to match your call. Or change this to clearAllSubscriptions() if that's the method name.
    }

    await FirebaseAuth.instance.signOut();

    log('[AuthCtrl] Sign out complete. Navigation will be handled by auth state listener.');
  }

  // Registration
  Future<bool> createAccountAndSaveData(String email, String password, File? profileImageFile, Map<String, dynamic> userData) async {
    UserCredential? credential;
    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
      String? downloadUrl;
      if (profileImageFile != null) {
        downloadUrl = await uploadProfilePhoto(profileImageFile);
      }
      personModel.Person personInstance = personModel.Person(
        uid: credential.user!.uid, email: email.trim(), name: userData['name'] ?? '',
        username: userData['username'] ?? '', orientation: (userData['orientation'] as String? ?? 'adam').toLowerCase(),
        profilePhoto: downloadUrl, publishedDateTime: DateTime.now().millisecondsSinceEpoch,
        gender: userData['gender'] ?? '', age: userData['age'] as int?, phoneNumber: userData['phoneNumber'] ?? '',
        country: userData['country'] ?? '', province: userData['province'] ?? '', city: userData['city'] ?? '',
        lookingForBreakfast: userData['lookingForBreakfast'] ?? false, lookingForLunch: userData['lookingForLunch'] ?? false,
        lookingForDinner: userData['lookingForDinner'] ?? false, lookingForLongTerm: userData['lookingForLongTerm'] ?? false,
        height: userData['height'] ?? '', bodyType: userData['bodyType'] ?? '',
        drinkSelection: userData['drinkSelection'] ?? false, smokeSelection: userData['smokeSelection'] ?? false,
        meatSelection: userData['meatSelection'] ?? false, greekSelection: userData['greekSelection'] ?? false,
        hostSelection: userData['hostSelection'] ?? false, travelSelection: userData['travelSelection'] ?? false,
        profession: userData['profession'] ?? '', income: userData['income'] ?? '',
        professionalVenues: List<String>.from(userData['professionalVenues'] ?? []),
        otherProfessionalVenue: userData['otherProfessionalVenue'] ?? '',
        ethnicity: userData['ethnicity'] ?? '', nationality: userData['nationality'] ?? '',
        languages: userData['languages'] ?? '', instagram: userData['instagram'] ?? '', twitter: userData['twitter'] ?? '',
      );
      await FirebaseFirestore.instance.collection("users").doc(credential.user!.uid).set(personInstance.toJson());
      Get.snackbar("Success", "Account created successfully!", backgroundColor: Colors.green, colorText: Colors.white);
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'weak-password') { errorMessage = 'The password provided is too weak.'; }
      else if (e.code == 'email-already-in-use') { errorMessage = 'The account already exists for that email.'; }
      Get.snackbar("Account Creation Failed", errorMessage, backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false;
    } catch (error) {
      Get.snackbar("Account Creation Failed", "An unexpected error occurred: ${error.toString()}", backgroundColor: Colors.blueGrey, colorText: Colors.white);
      if (credential?.user != null) {
        await credential!.user!.delete();
      }
      return false;
    }
  }

  // --- Image Handling and Uploading ---
  late final Rx<File?> _pickedFile = Rx<File?>(null);
  File? get profilePhoto => _pickedFile.value;

  void resetProfilePhoto() {
    _pickedFile.value = null;
  }

  pickImageFromGallery() async {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      _pickedFile.value = File(imageFile.path);
    }
  }

  captureImageFromPhoneCamera() async {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (imageFile != null) {
      _pickedFile.value = File(imageFile.path);
    }
  }

  Future<String> uploadProfilePhoto(File profilePhoto) async {
    File compressedPhoto = await _compressImage(profilePhoto.path);
    Reference referenceStorage = FirebaseStorage.instance.ref().child("profilePhotos/${FirebaseAuth.instance.currentUser!.uid}");
    UploadTask uploadTask = referenceStorage.putFile(compressedPhoto);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<File> _compressImage(String filePath) async {
    File originalFile = File(filePath);
    final imageBytes = await originalFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      return originalFile;
    }

    int targetWidth = 1080;
    img.Image resizedImage;
    if (originalImage.width > targetWidth) {
      resizedImage = img.copyResize(originalImage, width: targetWidth);
    } else {
      resizedImage = originalImage;
    }

    final compressedImageBytes = img.encodeJpg(resizedImage, quality: 85);
    final tempDir = await getTemporaryDirectory();
    File compressedFile = await File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg').create();
    await compressedFile.writeAsBytes(compressedImageBytes);
    log('Image compressed: ${originalFile.lengthSync()} bytes -> ${compressedFile.lengthSync()} bytes');
    return compressedFile;
  }
}

