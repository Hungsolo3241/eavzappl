import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/person.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart'; // Unused import removed
import 'package:get/get.dart';
import 'dart:async';
import 'package:eavzappl/models/filter_preferences.dart';

class ProfileController extends GetxController {
  final Rx<List<Person>> usersProfileList = Rx<List<Person>>([]);
  List<Person> get allUsersProfileList => usersProfileList.value;

  final Rx<Person?> currentUserProfile = Rx<Person?>(null);
  Rx<String?> get currentUserOrientation => _currentUserOrientation;
  final Rx<String?> _currentUserOrientation = Rx<String?>(null);

  StreamSubscription<User?>? _authStateSubscription;

  // --- Filter Logic Additions ---
  final Rx<FilterPreferences> activeFilters = Rx<FilterPreferences>(FilterPreferences());

  void updateFilters(FilterPreferences newFilters) {
    activeFilters.value = newFilters;
    print("Filters updated in ProfileController. New filters: Age ${newFilters.ageRange}, Ethnicity ${newFilters.ethnicity}, Profession ${newFilters.profession}, Country ${newFilters.country}, Host ${newFilters.wantsHost}, Travel ${newFilters.wantsTravel}");
    usersProfileList.refresh();
  }

  List<Person> get filteredUsersProfileList {
    List<Person> filteredList = allUsersProfileList;
    final filters = activeFilters.value;

    // Apply Age Filter
    if (filters.ageRange != null) {
      filteredList = filteredList.where((person) {
        if (person.age == null) return false;
        return person.age! >= filters.ageRange!.start.round() &&
               person.age! <= filters.ageRange!.end.round();
      }).toList();
    }

    // Apply Gender Filter
    if (filters.gender != null && filters.gender != "Any" && filters.gender!.isNotEmpty) { // Assuming "Any" or empty means no gender filter
      filteredList = filteredList.where((person) {
        if (person.gender == null) return false; // Or handle as per your logic
        return person.gender!.toLowerCase() == filters.gender!.toLowerCase();
      }).toList();
    }

    // Apply Ethnicity Filter
    if (filters.ethnicity != null && filters.ethnicity != "Any") {
      filteredList = filteredList.where((person) =>
        person.ethnicity?.toLowerCase() == filters.ethnicity!.toLowerCase()
      ).toList();
    }

    // Apply Wants Host Filter (Corrected to use person.hostSelection)
    if (filters.wantsHost != null) {
      filteredList = filteredList.where((person) =>
        person.hostSelection == filters.wantsHost
      ).toList();
    }

    // Apply Wants Travel Filter (Corrected to use person.travelSelection)
    if (filters.wantsTravel != null) {
      filteredList = filteredList.where((person) =>
        person.travelSelection == filters.wantsTravel
      ).toList();
    }

    // Apply Profession Filter
    if (filters.profession != null && filters.profession != "Any") {
      filteredList = filteredList.where((person) =>
        person.profession?.toLowerCase() == filters.profession!.toLowerCase()
      ).toList();
    }

    // Apply Country Filter
    if (filters.country != null && filters.country != "Any" && filters.country!.isNotEmpty) {
        filteredList = filteredList.where((person) =>
        person.country?.toLowerCase() == filters.country!.toLowerCase()
        ).toList();
    }

    // Apply Province/State Filter (only if country is also specified)
    if (filters.country != null && filters.country != "Any" && filters.country!.isNotEmpty &&
        filters.province != null && filters.province != "Any" && filters.province!.isNotEmpty) {
        filteredList = filteredList.where((person) =>
        person.province?.toLowerCase() == filters.province!.toLowerCase()
        ).toList();
    }

    // Apply City Filter (only if country and province are also specified)
    if (filters.country != null && filters.country != "Any" && filters.country!.isNotEmpty &&
        filters.province != null && filters.province != "Any" && filters.province!.isNotEmpty &&
        filters.city != null && filters.city != "Any" && filters.city!.isNotEmpty) {
        filteredList = filteredList.where((person) =>
        person.city?.toLowerCase() == filters.city!.toLowerCase()
        ).toList();
    }
    print("Filtered list count after applying all filters: ${filteredList.length}");
    return filteredList;
  }
  // --- End of Filter Logic Additions ---

  @override
  void onInit() {
    super.onInit();
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print("ProfileController: User is currently signed out!");
        usersProfileList.value = [];
        currentUserProfile.value = null;
        _currentUserOrientation.value = null;
        activeFilters.value = FilterPreferences();
      } else {
        print("ProfileController: User is signed in! UID: ${user.uid}. Initializing/Refreshing profiles.");
        _initializeAndStreamProfiles();
        activeFilters.value = FilterPreferences();
      }
    });
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    super.onClose();
  }

  likeSentAndReceived(String toUserId, String fromUserName) async
  {
      var document = await FirebaseFirestore.instance.collection("users")
          .doc(toUserId)
          .collection("likesReceived")
          .doc(fromUserName).get();

      if (document.exists) {
        await FirebaseFirestore.instance.collection("users")
            .doc(toUserId)
            .collection("likesReceived")
            .doc(fromUserName).delete();
      } else {
        await FirebaseFirestore.instance.collection("users")
            .doc(toUserId)
            .collection("likesReceived")
            .doc(fromUserName).set({});
      }
      update();
  }

  Future<void> _initializeAndStreamProfiles() async {
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
