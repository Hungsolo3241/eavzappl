import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/person.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class ProfileController extends GetxController {
  final Rx<List<Person>> usersProfileList = Rx<List<Person>>([]);
  List<Person> get allUsersProfileList => usersProfileList.value;

  final Rx<Person?> currentUserProfile = Rx<Person?>(null);
  Rx<String?> get currentUserOrientation => _currentUserOrientation; // Allow read access if needed
  final Rx<String?> _currentUserOrientation = Rx<String?>(null);

  StreamSubscription<User?>? _authStateSubscription;

  @override
  void onInit() {
    super.onInit();
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print("ProfileController: User is currently signed out!");
        usersProfileList.value = [];
        currentUserProfile.value = null;
        _currentUserOrientation.value = null;
      } else {
        print("ProfileController: User is signed in! UID: ${user.uid}. Initializing/Refreshing profiles.");
        _initializeAndStreamProfiles(); // Re-initialize when auth state changes to a new user
      }
    });
    // Optional: If a user might already be logged in when controller initializes,
    // and authStateChanges might not fire immediately for an existing session.
    // However, authStateChanges usually fires on listen with the current state.
    // if (FirebaseAuth.instance.currentUser != null) {
    //   _initializeAndStreamProfiles();
    // }
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel(); // Cancel subscription when controller is disposed
    super.onClose();
  }

  Future<void> _initializeAndStreamProfiles() async {
    // Clear old data first to avoid showing stale profiles briefly
    // usersProfileList.value = []; // Handled by authStateChanges listener for logout
    // currentUserProfile.value = null; // Handled by authStateChanges listener for logout
    // _currentUserOrientation.value = null; // Handled by authStateChanges listener for logout

    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      print("ProfileController: _initializeAndStreamProfiles called but user is null.");
      usersProfileList.value = [];
      currentUserProfile.value = null;
      _currentUserOrientation.value = null;
      return;
    }

    print("ProfileController: Initializing for user: $currentUserId");

    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .get();

      if (!currentUserDoc.exists || currentUserDoc.data() == null) {
        print("ProfileController: Current user document ($currentUserId) not found or has no data.");
        usersProfileList.value = [];
        currentUserProfile.value = null;
        _currentUserOrientation.value = null;
        return;
      }

      currentUserProfile.value = Person.fromDataSnapshot(currentUserDoc);
      String? fetchedOrientationFromParsedObject = currentUserProfile.value?.orientation;
      _currentUserOrientation.value = fetchedOrientationFromParsedObject?.toLowerCase();

      if (_currentUserOrientation.value == null) {
        final rawData = currentUserDoc.data() as Map<String, dynamic>?;
        final rawOrientationDirectlyFromDoc = rawData?['orientation'] as String?;
        print("ProfileController: Current user '$currentUserId' orientation field not found (parsed as '$fetchedOrientationFromParsedObject') or was null. Raw 'orientation' from Firestore doc: '$rawOrientationDirectlyFromDoc'");
        usersProfileList.value = [];
        return;
      }

      String targetOrientation;
      if (_currentUserOrientation.value == 'adam') {
        targetOrientation = 'eve';
      } else if (_currentUserOrientation.value == 'eve') {
        targetOrientation = 'adam';
      } else {
        print("ProfileController: Unknown current user orientation ('${_currentUserOrientation.value}') for user '$currentUserId'. Parsed from Firestore: '$fetchedOrientationFromParsedObject'");
        usersProfileList.value = [];
        return;
      }

      print("ProfileController: User '$currentUserId' orientation (lowercase): ${_currentUserOrientation.value}, fetching $targetOrientation profiles.");

      // bindStream will replace the old stream if called again.
      usersProfileList.bindStream(
        FirebaseFirestore.instance
            .collection("users")
            .where("uid", isNotEqualTo: currentUserId)
            .where("orientation", isEqualTo: targetOrientation)
            .snapshots()
            .map((QuerySnapshot queryDataSnapshot) {
          List<Person> profilesList = [];
          print("ProfileController: Stream for user '$currentUserId' received ${queryDataSnapshot.docs.length} profiles matching target orientation '$targetOrientation'.");
          for (var eachProfile in queryDataSnapshot.docs) {
            profilesList.add(Person.fromDataSnapshot(eachProfile));
          }
          return profilesList;
        }),
      );
    } catch (e) {
      print("ProfileController: Error in _initializeAndStreamProfiles for user '$currentUserId': $e");
      usersProfileList.value = [];
      currentUserProfile.value = null;
      _currentUserOrientation.value = null;
    }
  }
}
