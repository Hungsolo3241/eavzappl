import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eavzappl/models/person.dart' as personModel;

class AuthenticationController extends GetxController
{
  static AuthenticationController authController = Get.find();

  Future<bool> loginUser(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      Get.snackbar("Login Successful", "Welcome back!", backgroundColor: Colors.green, colorText: Colors.white);
      return true;
    } on FirebaseAuthException catch (e) {
      // These print statements are helpful for debugging if new codes appear
      print("Firebase Auth Error Code: ${e.code}");
      print("Firebase Auth Error Message: ${e.message}");

      String errorMessage = "An error occurred. Please try again."; // Default message

      // Conditions based on observed Firebase error codes
      if (e.code == 'invalid-credential') { // For wrong password or user not found
        errorMessage = 'Invalid credentials. Please check your email and password.';
      } else if (e.code == 'invalid-email') { // For badly formatted email
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user account has been disabled.';
      }
      // You can add other specific Firebase Auth error codes here if needed

      Get.snackbar("Login Failed", errorMessage, backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false;
    } catch (error) {
      // This print is also helpful for unexpected issues
      print("Generic Catch Error in loginUser: $error");
      Get.snackbar("Login Failed", "An unexpected error occurred: ${error.toString()}", backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false;
    }
  }



  late final Rx<File?> _pickedFile = Rx<File?>(null); // Initialize with null
  File? get profilePhoto => _pickedFile.value;

  void resetProfilePhoto() {
    _pickedFile.value = null;
    // _pickedFile.refresh(); // Not strictly necessary if Obx is used correctly, but won't hurt
    print("AuthenticationController: Profile photo reset.");
  }

  pickImageFromGallery() async
  {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if(imageFile != null)
    {
      Get.snackbar("Profile Picture", "You have successfully selected your profile picture!");
      _pickedFile.value = File(imageFile.path);
      _pickedFile.refresh();
    }
    else
    {
      Get.snackbar("Profile Picture", "Image selection cancelled.");
    }
  }

  captureImageFromPhoneCamera() async
  {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.camera);

    if(imageFile != null)
    {
      Get.snackbar("Profile Picture", "You have successfully captured your profile picture!");
      _pickedFile.value = File(imageFile.path);
      _pickedFile.refresh();
    }
    else
    {
      Get.snackbar("Profile Picture", "Image capture cancelled.");
    }
  }

  Future<String> uploadProfilePhoto(File profilePhoto) async
  {
    Reference referenceStorage = FirebaseStorage.instance.ref()
        .child("profilePhotos/${FirebaseAuth.instance.currentUser!.uid}");

    UploadTask uploadTask = referenceStorage.putFile(profilePhoto);
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<bool> createAccountAndSaveData(String email, String password, File? profileImageFile, Map<String, dynamic> userData) async {
    UserCredential? credential; // Keep credential in a broader scope

    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // If Auth user creation itself failed, credential will be null or an exception already thrown.
      // If we reach here, Auth user was created.

      String? downloadUrl;
      if (profileImageFile != null) {
        Reference reference = FirebaseStorage.instance.ref()
            .child("profilePhotos/${credential.user!.uid}");
        UploadTask uploadTask = reference.putFile(profileImageFile);
        TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      Map<String, dynamic> firestoreUserData = Map<String, dynamic>.from(userData);
      firestoreUserData['uid'] = credential.user!.uid;
      firestoreUserData['email'] = email.trim();
      firestoreUserData['profilePhoto'] = downloadUrl ?? "";

      if (firestoreUserData.containsKey('orientation') && firestoreUserData['orientation'] is String) {
        firestoreUserData['orientation'] = (firestoreUserData['orientation'] as String).toLowerCase();
      }

      // Attempt to set Firestore data
      await FirebaseFirestore.instance.collection("users")
          .doc(credential.user!.uid)
          .set(firestoreUserData);

      Get.snackbar("Success", "Account created successfully!", backgroundColor: Colors.green, colorText: Colors.white);
      return true; // Return true on success

    } on FirebaseAuthException catch (e) {
      // This catch is for errors during createUserWithEmailAndPassword
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      Get.snackbar("Account Creation Failed", errorMessage, backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false;
    }
    catch (error) {
      // This catch is for errors AFTER Auth user creation (e.g., Firestore write, image upload)
      Get.snackbar("Account Creation Failed", "An unexpected error occurred while saving data: ${error.toString()}", backgroundColor: Colors.blueGrey, colorText: Colors.white);

      // IMPORTANT: Attempt to delete the Auth user if Firestore write failed
      // IMPORTANT: Attempt to delete the Auth user if Firestore write failed
      if (credential != null && credential.user != null) { // More explicit check
        final User user = credential.user!; // This should now be safe
        try {
          await user.delete();
          Get.snackbar("Rollback", "User registration rolled back due to data saving error.", backgroundColor: Colors.orangeAccent, colorText: Colors.white);
          print("Successfully deleted partially created Auth user: ${user.uid}");
        } catch (deleteError) {
          Get.snackbar("Critical Error", "Failed to save data AND failed to rollback user. Please contact support.", backgroundColor: Colors.red, colorText: Colors.white);
          print("Failed to delete partially created Auth user (UID: ${user.uid}): $deleteError");
        }
      }


      return false;
    }
  }


  // Updated createNewUserAccount method
  createNewUserAccount(
      // Personal Info
      File profilePhotoFile,
      String email,
      // String password, // REMOVED password parameter
      String name,
      String ageString, // RENAMED from 'age' to 'ageString' for clarity
      String phoneNumber,
      String gender,
      String orientation, // This is the parameter from the form
      String username,
      String country,
      String province,
      String city,
      bool lookingForBreakfast,
      bool lookingForLunch,
      bool lookingForDinner,
      bool lookingForLongTerm,

      // Appearance (Eve specific)
      String height,
      String bodyType,
      bool drinkSelection, // Assuming these match Person model
      bool smokeSelection,
      bool meatSelection,
      bool greekSelection,
      bool hostSelection,
      bool travelSelection,
      String profession,
      String income,
      List<String> professionalVenues,
      String otherProfessionalVenue,

      // Background (Eve specific)
      String ethnicity,
      String nationality,
      String languages,

      // Social Media (Eve specific)
      String instagram,
      String twitter
      ) async
  {
    try
    {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        Get.snackbar("Error", "User not authenticated. Cannot save profile data.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
        return;
      }

      String profilePhotoUrl = await uploadProfilePhoto(profilePhotoFile);

      int? ageAsInt;
      if (ageString.trim().isNotEmpty) {
        ageAsInt = int.tryParse(ageString.trim());
        if (ageAsInt == null) {
          Get.snackbar("Data Error", "Invalid age format: '$ageString'. Age will not be saved.", backgroundColor: Colors.orangeAccent, colorText: Colors.white);
        }
      }

      personModel.Person personInstance = personModel.Person(
        uid: currentUser.uid, 
        profilePhoto: profilePhotoUrl,
        email: email,
        name: name,
        age: ageAsInt, 
        phoneNumber: phoneNumber,
        gender: gender,
        orientation: orientation.toLowerCase(), // Convert to lowercase here
        username: username,
        country: country,
        province: province,
        city: city,
        lookingForBreakfast: lookingForBreakfast,
        lookingForLunch: lookingForLunch,
        lookingForDinner: lookingForDinner,
        lookingForLongTerm: lookingForLongTerm,
        publishedDateTime: DateTime.now().millisecondsSinceEpoch,
        height: height,
        bodyType: bodyType,
        drinkSelection: drinkSelection,
        smokeSelection: smokeSelection,
        meatSelection: meatSelection,
        greekSelection: greekSelection,
        hostSelection: hostSelection,
        travelSelection: travelSelection,
        profession: profession,
        income: income,
        professionalVenues: professionalVenues,
        otherProfessionalVenue: otherProfessionalVenue,
        ethnicity: ethnicity,
        nationality: nationality,
        languages: languages,
        instagram: instagram,
        twitter: twitter,
      );

      await FirebaseFirestore.instance.collection("users")
          .doc(currentUser.uid).set(personInstance.toJson());

      Get.snackbar("Success", "Account data processed successfully!");

    }
    catch(e)
    {
      Get.snackbar("Error Processing Account Data", e.toString(), backgroundColor: Colors.blueGrey, colorText: Colors.white);
    }
  }
}
