import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:eavzappl/homeScreen/home_screen.dart';
import 'package:eavzappl/splashScreen/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eavzappl/models/person.dart' as personModel;
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AuthenticationController extends GetxController {
  static AuthenticationController authController = Get.find();
  late Rx<User?> _firebaseUser;
  bool _hasInitialized = false;

  @override
  void onReady() {
    super.onReady();
    _firebaseUser = Rx<User?>(FirebaseAuth.instance.currentUser);
    _firebaseUser.bindStream(FirebaseAuth.instance.authStateChanges());
    ever(_firebaseUser, _setInitialScreen);
  }

  void _setInitialScreen(User? user) async {
    if (user == null) {
      // If user logs out, reset the flag and go to login
      _hasInitialized = false;
      Get.offAll(() => const LoginScreen());
    } else {
      // If user is logged in but we have already initialized, do nothing.
      // This prevents re-running the whole sequence on hot restarts.
      if (_hasInitialized) return;

      Get.offAll(() => const SplashScreen());
      _hasInitialized = true; // Set flag to true immediately after showing splash

      final profileController = Get.find<ProfileController>();
      profileController.initializeAllStreams(user.uid);

      const minimumSplashDuration = Duration(seconds: 4);
      final timerFuture = Future.delayed(minimumSplashDuration);

      // Await both the timer and the profile controller's own initialization future
      await Future.wait([
        timerFuture,
        profileController.initialization,
      ]);

      Get.offAll(() => const HomeScreen());
    }
  }

  Future<void> logoutUser() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<bool> loginUser(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Invalid credentials. Please try again.";
      if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user account has been disabled.';
      }
      Get.snackbar("Login Failed", errorMessage,
          backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false;
    } catch (error) {
      Get.snackbar("Login Failed", "An unexpected error occurred.",
          backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false;
    }
  }

  Future<bool> createAccountAndSaveData(String email, String password,
      File? profileImageFile, Map<String, dynamic> userData) async {
    UserCredential? credential;
    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String? downloadUrl;
      if (profileImageFile != null) {
        downloadUrl = await uploadProfilePhoto(profileImageFile);
      }

      personModel.Person personInstance = personModel.Person(
        uid: credential.user!.uid,
        email: email.trim(),
        name: userData['name'] ?? '',
        username: userData['username'] ?? '',
        orientation: (userData['orientation'] as String? ?? 'adam').toLowerCase(),
        profilePhoto: downloadUrl,
        publishedDateTime: DateTime.now().millisecondsSinceEpoch,
        gender: userData['gender'] ?? '',
        age: userData['age'] as int?,
        phoneNumber: userData['phoneNumber'] ?? '',
        country: userData['country'] ?? '',
        province: userData['province'] ?? '',
        city: userData['city'] ?? '',
        lookingForBreakfast: userData['lookingForBreakfast'] ?? false,
        lookingForLunch: userData['lookingForLunch'] ?? false,
        lookingForDinner: userData['lookingForDinner'] ?? false,
        lookingForLongTerm: userData['lookingForLongTerm'] ?? false,
        height: userData['height'] ?? '',
        bodyType: userData['bodyType'] ?? '',
        drinkSelection: userData['drinkSelection'] ?? false,
        smokeSelection: userData['smokeSelection'] ?? false,
        meatSelection: userData['meatSelection'] ?? false,
        greekSelection: userData['greekSelection'] ?? false,
        hostSelection: userData['hostSelection'] ?? false,
        travelSelection: userData['travelSelection'] ?? false,
        profession: userData['profession'] ?? '',
        income: userData['income'] ?? '',
        professionalVenues:
            List<String>.from(userData['professionalVenues'] ?? []),
        otherProfessionalVenue: userData['otherProfessionalVenue'] ?? '',
        ethnicity: userData['ethnicity'] ?? '',
        nationality: userData['nationality'] ?? '',
        languages: userData['languages'] ?? '',
        instagram: userData['instagram'] ?? '',
        twitter: userData['twitter'] ?? '',
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(credential.user!.uid)
          .set(personInstance.toJson());

      Get.snackbar("Success", "Account created successfully!",
          backgroundColor: Colors.green, colorText: Colors.white);
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      }
      Get.snackbar("Account Creation Failed", errorMessage,
          backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false;
    } catch (error) {
      Get.snackbar(
          "Account Creation Failed", "An unexpected error occurred: ${error.toString()}",
          backgroundColor: Colors.blueGrey, colorText: Colors.white);
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
    Reference referenceStorage = FirebaseStorage.instance.ref()
        .child("profilePhotos/${FirebaseAuth.instance.currentUser!.uid}");

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
