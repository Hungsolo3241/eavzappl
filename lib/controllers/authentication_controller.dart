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

  late final Rx<File?> _pickedFile = Rx<File?>(null); // Initialize with null
  File? get profilePhoto => _pickedFile.value;

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
    try {
      UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

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

      await FirebaseFirestore.instance.collection("users")
          .doc(credential.user!.uid)
          .set(firestoreUserData);

      Get.snackbar("Success", "Account created successfully!", backgroundColor: Colors.green, colorText: Colors.white);
      return true; // Return true on success

    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      Get.snackbar("Account Creation Failed", errorMessage, backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false; // Return false on FirebaseAuthException
    }
    catch (error) {
      Get.snackbar("Account Creation Failed", "An unexpected error occurred: ${error.toString()}", backgroundColor: Colors.blueGrey, colorText: Colors.white);
      return false; // Return false on other errors
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
      String orientation,
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
      // This method now assumes user is already authenticated or auth is handled by the caller,
      // as 'password' is no longer a direct parameter for Firebase Auth user creation here.
      // Primary user creation is handled by 'createAccountAndSaveData'.
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // If this method were intended to create users, it would need the password for
        // UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: /* password_from_param */);
        // For now, if no user, we can't proceed to save data linked to a user.
        Get.snackbar("Error", "User not authenticated. Cannot save profile data.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
        return;
      }

      String profilePhotoUrl = await uploadProfilePhoto(profilePhotoFile);

      int? ageAsInt;
      if (ageString.trim().isNotEmpty) {
        ageAsInt = int.tryParse(ageString.trim());
        if (ageAsInt == null) {
          Get.snackbar("Data Error", "Invalid age format: '$ageString'. Age will not be saved.", backgroundColor: Colors.orangeAccent, colorText: Colors.white);
          // Decide if you want to return or proceed without age
        }
      }

      personModel.Person personInstance = personModel.Person(
        uid: currentUser.uid, // Use current user's UID
        profilePhoto: profilePhotoUrl,
        email: email,
        // password: password, // REMOVED password field from Person model
        name: name,
        age: ageAsInt, // Pass the parsed int?
        phoneNumber: phoneNumber,
        gender: gender,
        orientation: orientation,
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
