import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/person.dart'; // Assuming Person.fromDataSnapshot exists
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final Rx<List<Person>> usersProfileList = Rx<List<Person>>([]);
  List<Person> get allUsersProfileList => usersProfileList.value;

  final Rx<Person?> currentUserProfile = Rx<Person?>(null);
  final Rx<String?> _currentUserOrientation = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    _initializeAndStreamProfiles();
  }

  Future<void> _initializeAndStreamProfiles() async {
    try {
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null) {
        print("ProfileController: Current user is null. Cannot fetch profiles.");
        usersProfileList.value = [];
        currentUserProfile.value = null;
        _currentUserOrientation.value = null;
        return;
      }

      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .get();

      if (!currentUserDoc.exists || currentUserDoc.data() == null) {
        print("ProfileController: Current user document not found or has no data.");
        usersProfileList.value = [];
        currentUserProfile.value = null;
        _currentUserOrientation.value = null;
        return;
      }

      currentUserProfile.value = Person.fromDataSnapshot(currentUserDoc);
      String? fetchedOrientationFromParsedObject = currentUserProfile.value?.orientation;
      _currentUserOrientation.value = fetchedOrientationFromParsedObject?.toLowerCase();

      if (_currentUserOrientation.value == null) {
        // For logging the raw value from the document if the parsed one is null
        final rawData = currentUserDoc.data() as Map<String, dynamic>?; // Safe cast
        final rawOrientationDirectlyFromDoc = rawData?['orientation'] as String?; // Safe access

        print("ProfileController: Current user 'orientation' field not found (parsed as '$fetchedOrientationFromParsedObject') or was null. Raw 'orientation' from Firestore doc: '$rawOrientationDirectlyFromDoc'");
        usersProfileList.value = [];
        return;
      }

      String targetOrientation;
      if (_currentUserOrientation.value == 'adam') {
        targetOrientation = 'eve';
      } else if (_currentUserOrientation.value == 'eve') {
        targetOrientation = 'adam';
      } else {
        // Use fetchedOrientationFromParsedObject for clarity on what was parsed before lowercasing
        print("ProfileController: Unknown current user orientation (lowercase: '${_currentUserOrientation.value}'). Parsed from Firestore: '$fetchedOrientationFromParsedObject'");
        usersProfileList.value = [];
        return;
      }

      print("ProfileController: Current user orientation (lowercase): ${_currentUserOrientation.value}, fetching $targetOrientation profiles.");

      usersProfileList.bindStream(
        FirebaseFirestore.instance
            .collection("users")
            .where("uid", isNotEqualTo: currentUserId)
            .where("orientation", isEqualTo: targetOrientation)
            .snapshots()
            .map((QuerySnapshot queryDataSnapshot) {
          List<Person> profilesList = [];
          print("ProfileController: Received ${queryDataSnapshot.docs.length} profiles from stream matching target orientation '$targetOrientation'.");
          for (var eachProfile in queryDataSnapshot.docs) {
            profilesList.add(Person.fromDataSnapshot(eachProfile));
          }
          return profilesList;
        }),
      );
    } catch (e) {
      print("ProfileController: Error in _initializeAndStreamProfiles: $e");
      usersProfileList.value = [];
      currentUserProfile.value = null;
      _currentUserOrientation.value = null;
    }
  }
}
