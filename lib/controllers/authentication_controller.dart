import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eavzappl/models/person.dart' as personModel;
import 'package:eavzappl/splashScreen/splash_screen.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/homeScreen/home_screen.dart';

class AuthenticationController extends GetxController
{
  static AuthenticationController authController = Get.find();
  // --- LOGOUT ---
  // This is the only logic needed. Signing out triggers the authStateChanges
  // listener in ProfileController, which handles clearing all user data.
  Future<void> logoutUser() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(const SplashScreen());
  }
  // --- LOGIN ---
  // This is also all that is needed. After sign-in, the SplashScreen will
  // detect the new user and navigate correctly.
  Future<bool> loginUser(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      Get.offAll(const SplashScreen());
      return true;

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Invalid credentials. Please try again.";
      if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user account has been disabled.';
      }
      Get.snackbar("Login Failed", errorMessage, backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false;
    } catch (error) {
      Get.snackbar("Login Failed", "An unexpected error occurred.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false;
    }
  }

  late final Rx<File?> _pickedFile = Rx<File?>(null);
  File? get profilePhoto => _pickedFile.value;

  void resetProfilePhoto() {
    _pickedFile.value = null;
  }

  pickImageFromGallery() async {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if(imageFile != null) {
      _pickedFile.value = File(imageFile.path);
    }
  }

  captureImageFromPhoneCamera() async {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if(imageFile != null) {
      _pickedFile.value = File(imageFile.path);
    }
  }

  Future<String> uploadProfilePhoto(File profilePhoto) async {
    Reference referenceStorage = FirebaseStorage.instance.ref()
        .child("profilePhotos/${FirebaseAuth.instance.currentUser!.uid}");

    UploadTask uploadTask = referenceStorage.putFile(profilePhoto);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<bool> createAccountAndSaveData(String email, String password, File? profileImageFile, Map<String, dynamic> userData) async {
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

      String finalOrientation = (userData['orientation'] as String? ?? 'adam').toLowerCase();

      personModel.Person personInstance = personModel.Person(
        uid: credential.user!.uid,
        email: email.trim(),
        name: userData['name'] ?? '',
        username: userData['username'] ?? '',
        orientation: finalOrientation,
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
        professionalVenues: List<String>.from(userData['professionalVenues'] ?? []),
        otherProfessionalVenue: userData['otherProfessionalVenue'] ?? '',
        ethnicity: userData['ethnicity'] ?? '',
        nationality: userData['nationality'] ?? '',
        languages: userData['languages'] ?? '',
        instagram: userData['instagram'] ?? '',
        twitter: userData['twitter'] ?? '',
      );


      await FirebaseFirestore.instance.collection("users")
          .doc(credential.user!.uid)
          .set(personInstance.toJson());

      // --- START OF THE FIX ---
      // Manually trigger the ProfileController to load the new user's data.
      final ProfileController profileController = Get.find();
      await profileController.forceReload();
      // --- END OF THE FIX ---

      Get.snackbar("Success", "Account created successfully!", backgroundColor: Colors.green, colorText: Colors.white);

      // Now that the profile is loaded, navigate to the HomeScreen.
      Get.offAll(() => const HomeScreen()); // <-- We'll navigate from here now.

      return true;

    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      }
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
}
