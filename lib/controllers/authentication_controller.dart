import 'dart:io';
import 'dart:developer';
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
import 'package:eavzappl/authenticationScreen//login_screen.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AuthenticationController extends GetxController
{
  static AuthenticationController authController = Get.find();
  // --- LOGOUT ---
  Future<void> logoutUser() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const LoginScreen());
  }
  // --- LOGIN ---
  Future<bool> loginUser(String email, String password) async {
    try {
      // 1. Sign in the user
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // 2. Explicitly tell ProfileController to load the user's data and WAIT for it to finish.
      final ProfileController profileController = Get.find();
      await profileController.forceReload();
      // 3. Now that the data is loaded, navigate directly to the HomeScreen.
      Get.offAll(() => const HomeScreen());
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

  // Inside class AuthenticationController...

  /// Compresses the image file at the given path.
  Future<File> _compressImage(String filePath) async {
    File originalFile = File(filePath);

    // Read the original image file
    final imageBytes = await originalFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      // If decoding fails, return the original file to avoid errors
      return originalFile;
    }

    // Determine the target width for resizing. 1080p is a good standard for profile pics.
    int targetWidth = 1080;

    // Resize the image only if it's wider than our target.
    // This preserves the aspect ratio.
    img.Image resizedImage;
    if (originalImage.width > targetWidth) {
      resizedImage = img.copyResize(originalImage, width: targetWidth);
    } else {
      resizedImage = originalImage;
    }

    // Encode the resized image as a JPEG with 85% quality.
    // This is the main compression step.
    final compressedImageBytes = img.encodeJpg(resizedImage, quality: 85);

    // Get a temporary directory to save the new compressed file
    final tempDir = await getTemporaryDirectory();
    File compressedFile = await File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg').create();

    // Write the compressed bytes to the new file
    await compressedFile.writeAsBytes(compressedImageBytes);

    log('Image compressed: ${originalFile.lengthSync()} bytes -> ${compressedFile.lengthSync()} bytes');

    return compressedFile;
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
    File compressedPhoto = await _compressImage(profilePhoto.path);
    Reference referenceStorage = FirebaseStorage.instance.ref()
        .child("profilePhotos/${FirebaseAuth.instance.currentUser!.uid}");

    UploadTask uploadTask = referenceStorage.putFile(compressedPhoto);
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
