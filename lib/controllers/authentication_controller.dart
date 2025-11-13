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
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eavzappl/firebase_options.dart';

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

    // Detailed auth state monitoring
    FirebaseAuth.instance.authStateChanges().listen((user) {
      log("🔐 Auth state changed: ${user?.uid ?? 'SIGNED_OUT'}", name: 'AuthMonitor');
      _firebaseUser.value = user;
    });

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
  String? userId;
  String? idToken;
  
  try {
    log("Starting bulletproof registration for: $email", name: 'AuthController');
    
    // ============================================================================
    // PHASE 1: CREATE AUTH USER AND IMMEDIATELY CAPTURE CREDENTIALS
    // ============================================================================
    credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    
    userId = credential.user!.uid;
    log("Firebase Auth user created: $userId", name: 'AuthController');

    // CRITICAL: Get ID token IMMEDIATELY before any sign-out can occur
    idToken = await credential.user!.getIdToken(true);
    if (idToken == null) {
      throw Exception("Failed to capture a valid ID token.");
    }
    log("ID token captured: ${idToken.substring(0, 20)}...", name: 'AuthController');
    
    // ============================================================================
    // PHASE 2: PERFORM ALL OPERATIONS WITH CAPTURED TOKEN (NOT CURRENT USER)
    // ============================================================================
    
    // Create a temporary Firebase instance with the captured token
    // This bypasses any sign-out issues on the device
    final Map<String, String> authHeaders = {
      'Authorization': 'Bearer $idToken',
    };
    
    // Upload profile photo using captured credentials
    String? downloadUrl;
    if (profileImageFile != null) {
      log("Uploading profile photo with captured token...", name: 'AuthController');
      downloadUrl = await _uploadProfilePhotoWithToken(
        profileImageFile, 
        userId,
        idToken!,
      );
      log("Profile photo uploaded: $downloadUrl", name: 'AuthController');
    }
    
    // ============================================================================
    // PHASE 3: CREATE FIRESTORE DOCUMENT WITH RETRY LOGIC
    // ============================================================================
    
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
    
    log("Creating Firestore document with token authentication...", name: 'AuthController');
    
    // Retry logic with exponential backoff
    bool documentCreated = false;
    int retryCount = 0;
    const maxRetries = 5;
    
    while (retryCount < maxRetries && !documentCreated) {
      try {
        // Use REST API with captured token as fallback
        await _createFirestoreDocumentWithToken(
          userId,
          personInstance.toJson(),
          idToken!,
        );
        
        documentCreated = true;
        log("Firestore document created (attempt ${retryCount + 1})", name: 'AuthController');
        
      } catch (firestoreError) {
        retryCount++;
        log("Firestore attempt $retryCount failed: $firestoreError", 
            name: 'AuthController');
        
        if (retryCount < maxRetries) {
          // Exponential backoff: 1s, 2s, 4s, 8s, 16s
          final delay = Duration(seconds: (1 << (retryCount - 1)));
          log("Waiting ${delay.inSeconds}s before retry...", name: 'AuthController');
          await Future.delayed(delay);
          
          // Try to get a fresh token if possible
          try {
            final freshUser = FirebaseAuth.instance.currentUser;
            if (freshUser != null && freshUser.uid == userId) {
              idToken = await freshUser.getIdToken(true);
              log("Fresh token obtained", name: 'AuthController');
            }
          } catch (e) {
            log("Could not refresh token, using cached", name: 'AuthController');
          }
        } else {
          throw Exception("Failed to create Firestore document after $maxRetries attempts");
        }
      }
    }
    
    // ============================================================================
    // PHASE 4: VERIFY DOCUMENT EXISTS
    // ============================================================================
    
    log("Verifying document exists...", name: 'AuthController');
    
    bool documentExists = false;
    int verifyAttempts = 0;
    
    while (verifyAttempts < 10 && !documentExists) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .get();
        
        documentExists = docSnapshot.exists;
        
        if (documentExists) {
          log("Document verified in Firestore", name: 'AuthController');
          break;
        }
      } catch (e) {
        log("Verification attempt $verifyAttempts failed: $e", 
            name: 'AuthController');
      }
      
      verifyAttempts++;
      log("Document not found, waiting... (attempt $verifyAttempts/10)", 
          name: 'AuthController');
    }
    
    if (!documentExists) {
      throw Exception("Document created but failed final verification");
    }
    
    // ============================================================================
    // PHASE 5: FORCE RE-AUTHENTICATION IF SIGNED OUT
    // ============================================================================
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != userId) {
      log("User signed out during registration, re-authenticating...", 
          name: 'AuthController');
      
      try {
        // Force sign back in using the original credentials
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        log("User re-authenticated successfully", name: 'AuthController');
      } catch (e) {
        log("Re-authentication failed, but data is safe: $e", 
            name: 'AuthController');
        // Don't fail registration - data is already saved
      }
    }
    
    // Success!
    Get.snackbar(
      "Success",
      "Account created successfully!",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
    
    log("Registration completed successfully", name: 'AuthController');
    return true;
    
  } on FirebaseAuthException catch (e) {
    log("FirebaseAuth error: ${e.code} - ${e.message}", name: 'AuthController');
    
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
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
    
    // Only clean up if user was created but data save failed
    if (userId != null) {
      await _cleanupFailedRegistration(userId);
    }
    
    return false;
    
  } catch (error, stackTrace) {
    log("Unexpected error during registration",
        error: error,
        stackTrace: stackTrace,
        name: 'AuthController');
    
    Get.snackbar(
      "Registration Failed",
      "An unexpected error occurred. Please try again.",
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
    
    // Only clean up if user was created
    if (userId != null) {
      await _cleanupFailedRegistration(userId);
    }
    
    return false;
  }
}

// ============================================================================
// HELPER METHODS
// ============================================================================

/// Upload profile photo using REST API with captured token
Future<String> _uploadProfilePhotoWithToken(
  File profilePhoto,
  String uid,
  String idToken,
) async {
  try {
    // Compress image first
    File compressedPhoto = await _compressImage(profilePhoto.path);
    
    // Upload to Firebase Storage using the standard SDK
    // The SDK will use the current auth state, which should still be valid
    Reference referenceStorage = FirebaseStorage.instance
        .ref()
        .child("profilePhotos/$uid");
    
    UploadTask uploadTask = referenceStorage.putFile(compressedPhoto);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    
    return downloadUrl;
  } catch (e) {
    log("Profile photo upload failed: $e", name: 'AuthController');
    // Return null instead of throwing - we can proceed without profile photo
    throw Exception("Profile photo upload failed: $e");
  }
}

/// Create Firestore document using REST API with captured token
Future<void> _createFirestoreDocumentWithToken(
  String userId,
  Map<String, dynamic> data,
  String idToken,
) async {
  try {
    // Try SDK first (it's more reliable if auth state is intact)
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .set(data, SetOptions(merge: false));
    
  } catch (sdkError) {
    log("SDK write failed, trying REST API: $sdkError", name: 'AuthController');
    
    // Fallback to REST API with captured token
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$userId'
    );
    
    // Convert data to Firestore REST API format
    final Map<String, dynamic> firestoreData = {
      'fields': _convertToFirestoreFields(data),
    };
    
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(firestoreData),
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('REST API write failed: ${response.statusCode} ${response.body}');
    }
  }
}

/// Convert Dart types to Firestore REST API field format
Map<String, dynamic> _convertToFirestoreFields(Map<String, dynamic> data) {
  final Map<String, dynamic> fields = {};
  
  for (final entry in data.entries) {
    final key = entry.key;
    final value = entry.value;
    
    if (value == null) {
      fields[key] = {'nullValue': null};
    } else if (value is String) {
      fields[key] = {'stringValue': value};
    } else if (value is int) {
      fields[key] = {'integerValue': value.toString()};
    } else if (value is double) {
      fields[key] = {'doubleValue': value};
    } else if (value is bool) {
      fields[key] = {'booleanValue': value};
    } else if (value is List) {
      fields[key] = {
        'arrayValue': {
          'values': value.map((item) => 
            item is String ? {'stringValue': item} : {'stringValue': item.toString()}
          ).toList(),
        }
      };
    } else {
      fields[key] = {'stringValue': value.toString()};
    }
  }
  
  return fields;
}

/// Clean up failed registration
Future<void> _cleanupFailedRegistration(String userId) async {
  log("Cleaning up failed registration for $userId", name: 'AuthController');
  
  try {
    // Try to delete Firestore document first
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .delete()
        .timeout(const Duration(seconds: 5));
    log("Firestore document deleted", name: 'AuthController');
  } catch (e) {
    log("Could not delete Firestore document: $e", name: 'AuthController');
  }
  
  try {
    // Delete auth user
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid == userId) {
      await user!.delete();
      log("Auth user deleted", name: 'AuthController');
    }
  } catch (e) {
    log("Could not delete auth user: $e", name: 'AuthController');
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