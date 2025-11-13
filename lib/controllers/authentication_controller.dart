// lib/controllers/authentication_controller.dart

// --- START OF FIXES: ADD ALL MISSING IMPORTS ---
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:eavzappl/homeScreen/home_screen.dart';
import 'package:eavzappl/models/person.dart' as person_model;
import 'package:eavzappl/splashScreen/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img; // <-- FIX: For image processing (img.decodeImage)
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // <-- FIX: For getTemporaryDirectory
import 'package:eavzappl/utils/app_theme.dart';

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

  // ✅ ADD: Mutex for auth operations
  bool _isAuthOperationInProgress = false;
  Completer<void> _authCompleter = Completer<void>();

  @override
  void onReady() {
    super.onReady();
    _firebaseUser.value = FirebaseAuth.instance.currentUser;
    _firebaseUser.bindStream(FirebaseAuth.instance.authStateChanges());
    ever(_firebaseUser, _setInitialScreen);
    _setInitialScreen(_firebaseUser.value);
  }

  void _setInitialScreen(User? user) async {
  // Prevent concurrent auth operations
  if (_isAuthOperationInProgress) {
    await _authCompleter.future;
    return;
  }

  _isAuthOperationInProgress = true;
  _authCompleter = Completer<void>();

  try {
    if (user == null) {
      log("User is null, navigating to LoginScreen");
      _hasInitialized = false;

      // Clear controllers in correct order
      if (Get.isRegistered<LikeController>()) {
        Get.find<LikeController>().clear();
      }
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().clearAllSubscriptions();
      }

      Get.offAll(() => const LoginScreen());
    } else {
      if (_hasInitialized) return;

      log("User authenticated: ${user.uid}, initializing app");
      Get.offAll(() => const SplashScreen());
      _hasInitialized = true;

      final profileController = Get.find<ProfileController>();
      
      // ✅ FIX: Verify Firestore document exists before initializing
      bool documentExists = await _verifyUserDocument(user.uid);
      
      if (!documentExists) {
        // After a successful login/registration, the document MUST exist.
        // If it doesn't, this is a critical error state.
        throw Exception("User document not found for uid: ${user.uid}. This should not happen.");
      }

      // Start initialization
      profileController.initializeUserStreams(user.uid);

      const minimumSplashDuration = Duration(seconds: 3);
      final splashTimer = Future.delayed(minimumSplashDuration);

      final dataLoadingFuture = profileController.initialization.timeout(
        const Duration(seconds: 20), // ✅ Increased timeout
        onTimeout: () {
          log("Data loading timed out - proceeding anyway", 
              name: "AuthenticationController");
        },
      );

      await Future.wait([
        splashTimer,
        dataLoadingFuture,
      ]);

      log("Initialization complete, navigating to HomeScreen");
      Get.offAll(() => const HomeScreen());
    }
  } catch (e, stackTrace) {
    log("Error in _setInitialScreen", 
        error: e, 
        stackTrace: stackTrace, 
        name: "AuthenticationController");
    
    // ✅ Show error to user
    Get.snackbar(
      "Initialization Error",
      "Failed to load profile. Please restart the app.",
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
    
    // ✅ FIX: Instead of fallback navigation, sign out and go to login
    await signOutUser();
  } finally {
    _isAuthOperationInProgress = false;
    if (!_authCompleter.isCompleted) {
      _authCompleter.complete();
    }
  }
}

// ✅ NEW: Helper method to verify Firestore document exists
Future<bool> _verifyUserDocument(String uid) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.exists;
  } catch (e) {
    log('Error checking user document: $e', name: 'AuthenticationController');
    return false;
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
          // No user found with this phone number.
          // This is a login screen, so we should not create a new user.
          // We should sign out the newly created Firebase Auth user and show an error.
          await FirebaseAuth.instance.signOut();
          Get.snackbar(
            "Login Failed",
            "No account found for this phone number. Please register first.",
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
        }
        // If a user is found, we do nothing. The user is already logged in,
        // and the auth state listener will handle the navigation.
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
      Get.snackbar("Login Failed", errorMessage, backgroundColor: AppTheme.textGrey, colorText: Colors.white);
      return false;
    } catch (error) {
      Get.snackbar("Login Failed", "An unexpected error occurred.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
      return false;
    }
  }

  Future<void> signOutUser() async {
    log('[AuthCtrl] Initiating sign out.');

    // Clear controllers BEFORE signing out
    if (Get.isRegistered<LikeController>()) {
      Get.find<LikeController>().clear();
    }
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().clearAllSubscriptions();
    }

    // Small delay to ensure cleanup completes
    await Future.delayed(const Duration(milliseconds: 500));

    await FirebaseAuth.instance.signOut();
    _hasInitialized = false;

    log('[AuthCtrl] Sign out complete.');
  }

  // Registration
  Future<bool> createAccountAndSaveData(
  String email,
  String password,
  File? profileImageFile,
  Map<String, dynamic> userData,
) async {
  UserCredential? credential;
  
  try {
    log("🚀 Starting registration for: $email", name: 'AuthController');
    
    // Step 1: Create Firebase Auth user
    credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    
    final userId = credential.user!.uid;
    log("✅ Firebase Auth user created: $userId", name: 'AuthController');

    // Force a token refresh to try and stabilize the session on faulty devices
    log("🔄 Forcing token refresh...", name: 'AuthController');
    await credential.user!.getIdToken(true);
    log("✅ Token refreshed.", name: 'AuthController');
    
    // Step 2: Upload profile photo FIRST (if provided)
    String? downloadUrl;
    if (profileImageFile != null) {
      log("📸 Uploading profile photo...", name: 'AuthController');
      downloadUrl = await uploadProfilePhoto(profileImageFile, userId);
      log("✅ Profile photo uploaded: $downloadUrl", name: 'AuthController');
    }
    
    // Step 3: Create complete Person instance
    person_model.Person personInstance = person_model.Person(
      uid: userId,
      email: email.trim(),
      name: userData['name'] ?? '',
      username: userData['username'] ?? '',
      orientation: (userData['orientation'] as String? ?? 'adam').toLowerCase(),
      profilePhoto: downloadUrl,
      publishedDateTime: DateTime.now().millisecondsSinceEpoch,
      gender: userData['gender'] ?? '',
      age: (userData['age'] as num?)?.toInt(),
      phoneNumber: userData['phoneNumber'] ?? '',
      country: userData['country'] ?? '',
      province: userData['province'] ?? '',
      city: userData['city'] ?? '',
      relationshipStatus: userData['relationshipStatus'] ?? '',
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
      bio: '',
    );
    
    log("💾 Saving user document to Firestore...", name: 'AuthController');
    
    // Step 4: CRITICAL - Save to Firestore with retry logic
    int retryCount = 0;
    const maxRetries = 3;
    bool documentCreated = false;
    
    while (retryCount < maxRetries && !documentCreated) {
      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .set(personInstance.toJson(), SetOptions(merge: false));
        
        documentCreated = true;
        log("✅ User document saved to Firestore", name: 'AuthController');
        
      } catch (firestoreError) {
        retryCount++;
        log("⚠️ Firestore save attempt $retryCount failed: $firestoreError", 
            name: 'AuthController');
        
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount));
        } else {
          throw Exception("Failed to create user document after $maxRetries attempts");
        }
      }
    }
    
    // Step 5: CRITICAL - Verify document was actually created
    log("🔍 Verifying document exists in Firestore...", name: 'AuthController');
    
    int verifyAttempts = 0;
    bool documentExists = false;
    
    while (verifyAttempts < 5 && !documentExists) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final docSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();
      
      documentExists = docSnapshot.exists;
      
      if (documentExists) {
        log("✅ Document verified in Firestore", name: 'AuthController');
        break;
      }
      
      verifyAttempts++;
      log("⏳ Waiting for document to propagate (attempt $verifyAttempts)...", 
          name: 'AuthController');
    }
    
    if (!documentExists) {
      throw Exception("Document created but failed verification");
    }
    
    // Step 6: Show success message
    Get.snackbar(
      "Success",
      "Account created successfully!",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
    
    log("🎉 Registration completed successfully", name: 'AuthController');
    return true;
    
  } on FirebaseAuthException catch (e) {
    log("❌ FirebaseAuth error: ${e.code} - ${e.message}", name: 'AuthController');
    
    String errorMessage = "An error occurred. Please try again.";
    if (e.code == 'weak-password') {
      errorMessage = 'Password must be at least 6 characters.';
    } else if (e.code == 'email-already-in-use') {
      errorMessage = 'An account already exists for this email.';
    } else if (e.code == 'invalid-email') {
      errorMessage = 'Invalid email address.';
    }
    
    Get.snackbar(
      "Registration Failed",
      errorMessage,
      backgroundColor: AppTheme.textGrey,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
    
    // Clean up auth user if created
    if (credential?.user != null) {
      try {
        await credential!.user!.delete();
        log("🧹 Cleaned up Firebase Auth user", name: 'AuthController');
      } catch (deleteError) {
        log("⚠️ Error deleting auth user: $deleteError", name: 'AuthController');
      }
    }
    
    return false;
    
  } catch (error, stackTrace) {
    log("❌ Unexpected error during registration",
        error: error,
        stackTrace: stackTrace,
        name: 'AuthController');
    
    Get.snackbar(
      "Registration Failed",
      "An unexpected error occurred. Please try again.",
      backgroundColor: AppTheme.textGrey,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
    
    // Clean up auth user
    if (credential?.user != null) {
      try {
        await credential!.user!.delete();
        log("🧹 Cleaned up Firebase Auth user", name: 'AuthController');
      } catch (deleteError) {
        log("⚠️ Error deleting auth user: $deleteError", name: 'AuthController');
      }
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

  Future<String> uploadProfilePhoto(File profilePhoto, String uid) async {
    File compressedPhoto = await _compressImage(profilePhoto.path);
    Reference referenceStorage = FirebaseStorage.instance.ref().child("profilePhotos/$uid");
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

    int targetWidth = 720;
    img.Image resizedImage;
    if (originalImage.width > targetWidth) {
      resizedImage = img.copyResize(originalImage, width: targetWidth);
    } else {
      resizedImage = originalImage;
    }

    final compressedImageBytes = img.encodeJpg(resizedImage, quality: 90);
    final tempDir = await getTemporaryDirectory();
    File compressedFile = await File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg').create();
    await compressedFile.writeAsBytes(compressedImageBytes);
    log('Image compressed: ${originalFile.lengthSync()} bytes -> ${compressedFile.lengthSync()} bytes');
    return compressedFile;
  }
}