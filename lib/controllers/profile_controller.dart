import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/filter_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/person.dart';

class ProfileController extends GetxController {
  final RxList<Person> allUsersProfileList = <Person>[].obs;
  final RxList<Person> usersProfileList = <Person>[].obs; // For filtered list
  final Rx<Person?> currentUserProfile = Rx<Person?>(null);
  // MODIFIED: Declaration to correctly handle nullable string value
  final Rx<String?> _currentUserOrientation = Rx<String?>(null);
  StreamSubscription? _profilesStreamSubscription;
  StreamSubscription? _authStateSubscription;

  // --- Filter Preferences ---
  final Rx<FilterPreferences> activeFilters =
  Rx<FilterPreferences>(FilterPreferences());

  // --- Favorite Feature ---
  final RxSet<String> favoritedUserIds = RxSet<String>();
  StreamSubscription? _favoritesSubscription;

  // --- Profile Viewers Feature ---
  final String profileViewersSubCollection = "profileViewers";
  RxList<Person> usersWhoViewedMeList = <Person>[].obs;
  StreamSubscription? _usersWhoViewedMeSubscription;


  @override
  void onInit() {
    super.onInit();
    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
          if (user == null) {
            print("ProfileController: User is currently signed out!");
            _profilesStreamSubscription?.cancel();
            _favoritesSubscription?.cancel();
            _usersWhoViewedMeSubscription?.cancel();
            allUsersProfileList.clear(); // Use clear for RxList
            usersProfileList.clear();   // Use clear for RxList
            currentUserProfile.value = null;
            // MODIFIED: Correctly set null to Rx<String?>
            _currentUserOrientation.value = null;
            favoritedUserIds.clear();
            usersWhoViewedMeList.clear();
            activeFilters.value = FilterPreferences();
          } else {
            print(
                "ProfileController: User is signed in! UID: ${user.uid}. Initializing/Refreshing profiles.");
            _fetchAndStreamUserFavorites(user.uid);
            _listenToUsersWhoViewedMe(user.uid);
            _initializeAndStreamProfiles();
            activeFilters.value = FilterPreferences(); // Consider if this should be reset elsewhere too
          }
        });
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _profilesStreamSubscription?.cancel();
    _usersWhoViewedMeSubscription?.cancel();
    super.onClose();
  }

  void updateFilters(FilterPreferences newFilters) {
    activeFilters.value = newFilters;
    print(
        "Filters updated in ProfileController. New filters: Age ${newFilters.ageRange}, Ethnicity ${newFilters.ethnicity}, Profession ${newFilters.profession}, Country ${newFilters.country}, Host ${newFilters.wantsHost}, Travel ${newFilters.wantsTravel}");
    // MODIFIED: Use assignAll for RxList
    usersProfileList.assignAll(filteredUsersProfileList);
  }

  List<Person> get filteredUsersProfileList {
    List<Person> filteredList = allUsersProfileList.toList(); // Create a copy to modify
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
    if (filters.gender != null &&
        filters.gender != "Any" &&
        filters.gender!.isNotEmpty) {
      filteredList = filteredList.where((person) {
        if (person.gender == null) return false;
        return person.gender!.toLowerCase() == filters.gender!.toLowerCase();
      }).toList();
    }

    // Apply Ethnicity Filter
    if (filters.ethnicity != null && filters.ethnicity != "Any") {
      filteredList = filteredList
          .where((person) =>
      person.ethnicity?.toLowerCase() ==
          filters.ethnicity!.toLowerCase())
          .toList();
    }

    // Apply Wants Host Filter
    if (filters.wantsHost != null) {
      filteredList = filteredList
          .where((person) => person.hostSelection == filters.wantsHost)
          .toList();
    }

    // Apply Wants Travel Filter
    if (filters.wantsTravel != null) {
      filteredList = filteredList
          .where((person) => person.travelSelection == filters.wantsTravel)
          .toList();
    }

    // Apply Profession Filter
    if (filters.profession != null && filters.profession != "Any") {
      filteredList = filteredList
          .where((person) =>
      person.profession?.toLowerCase() ==
          filters.profession!.toLowerCase())
          .toList();
    }

    // Apply Country Filter
    if (filters.country != null &&
        filters.country != "Any" &&
        filters.country!.isNotEmpty) {
      filteredList = filteredList
          .where((person) =>
      person.country?.toLowerCase() == filters.country!.toLowerCase())
          .toList();
    }

    // Apply Province/State Filter
    if (filters.country != null &&
        filters.country != "Any" &&
        filters.country!.isNotEmpty &&
        filters.province != null &&
        filters.province != "Any" &&
        filters.province!.isNotEmpty) {
      filteredList = filteredList
          .where((person) =>
      person.province?.toLowerCase() ==
          filters.province!.toLowerCase())
          .toList();
    }

    // Apply City Filter
    if (filters.country != null &&
        filters.country != "Any" &&
        filters.country!.isNotEmpty &&
        filters.province != null &&
        filters.province != "Any" &&
        filters.province!.isNotEmpty &&
        filters.city != null &&
        filters.city != "Any" &&
        filters.city!.isNotEmpty) {
      filteredList = filteredList
          .where((person) =>
      person.city?.toLowerCase() == filters.city!.toLowerCase())
          .toList();
    }
    return filteredList;
  }

  // --- Favorite Feature Methods ---
  void _fetchAndStreamUserFavorites(String currentUserId) {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("userFavorites")
        .snapshots()
        .listen((snapshot) {
      final ids = snapshot.docs.map((doc) => doc.id).toSet();
      favoritedUserIds.value = ids; // RxSet assignment is fine
      _updateFavoriteStatusInProfileList();
      print(
          "ProfileController: User favorites updated: ${favoritedUserIds.length} favorites.");
    }, onError: (error) {
      print("ProfileController: Error fetching user favorites: $error");
    });
  }

  void _updateFavoriteStatusInProfileList() {
    bool changed = false;
    for (var person in allUsersProfileList) {
      bool isFav = favoritedUserIds.contains(person.uid);
      if (person.isFavorite.value != isFav) {
        person.isFavorite.value = isFav;
        changed = true;
      }
    }
    // Only update if there was a change or if lists might be out of sync
    // MODIFIED: Use assignAll for RxList
    if (changed || usersProfileList.length != filteredUsersProfileList.length) { // Basic check
      usersProfileList.assignAll(filteredUsersProfileList);
    }
  }

  Future<void> toggleFavoriteStatus(String personIdToToggle) async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      print(
          "ProfileController Error: Current user is null. Cannot toggle favorite.");
      return;
    }

    DocumentReference favoriteDocRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("userFavorites")
        .doc(personIdToToggle);

    final personDoc = await favoriteDocRef.get();
    bool newFavoriteState;

    final int personIndexInAll =
    allUsersProfileList.indexWhere((p) => p.uid == personIdToToggle);
    // No need to find in usersProfileList separately as it's derived from allUsersProfileList
    // and isFavorite is on the Person object itself.

    if (personDoc.exists) {
      await favoriteDocRef.delete();
      newFavoriteState = false;
      print(
          "ProfileController: User $personIdToToggle removed from favorites for $currentUserId");
    } else {
      await favoriteDocRef.set({'favoritedAt': FieldValue.serverTimestamp()});
      newFavoriteState = true;
      print(
          "ProfileController: User $personIdToToggle added to favorites for $currentUserId");
    }

    if (personIndexInAll != -1) {
      allUsersProfileList[personIndexInAll].isFavorite.value = newFavoriteState;
      // UI should react because Person.isFavorite is an RxBool
      // and SwipingScreen's Obx listens to it.
      // Re-filtering might be needed if favorite status impacts filtering criteria (not currently the case)
      // _updateFavoriteStatusInProfileList(); // Call this to ensure usersProfileList is also in sync
      usersProfileList.assignAll(filteredUsersProfileList); // Keep filtered list in sync
    }
    // favoritedUserIds will be updated by the stream in _fetchAndStreamUserFavorites.
  }

  // --- Like Feature Methods ---
  Future<void> _updateInitialLikeStatusForPerson(
      Person person, String currentUserId) async {
    if (person.uid == null) {
      person.likeStatus.value = LikeStatus.none;
      return;
    }

    DocumentReference currentUserLikesTargetRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("likesSent")
        .doc(person.uid!);

    DocumentReference targetLikesCurrentUserRef = FirebaseFirestore.instance
        .collection("users")
        .doc(person.uid!)
        .collection("likesSent")
        .doc(currentUserId);

    try {
      DocumentSnapshot currentUserLikesTargetSnap =
      await currentUserLikesTargetRef.get();
      DocumentSnapshot targetLikesCurrentUserSnap =
      await targetLikesCurrentUserRef.get();

      if (currentUserLikesTargetSnap.exists) {
        if (targetLikesCurrentUserSnap.exists) {
          person.likeStatus.value = LikeStatus.mutualLike;
        } else {
          person.likeStatus.value = LikeStatus.currentUserLiked;
        }
      } else {
        if (targetLikesCurrentUserSnap.exists) {
          person.likeStatus.value = LikeStatus.targetUserLikedCurrentUser;
        } else {
          person.likeStatus.value = LikeStatus.none;
        }
      }
    } catch (e) {
      print(
          "ProfileController: Error updating initial like status for ${person.uid}: $e");
      person.likeStatus.value = LikeStatus.none;
    }
  }

  Future<void> toggleLike(String targetUserId) async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      print("ProfileController Error: Current user is null. Cannot toggle like.");
      return;
    }

    Person? targetPerson = allUsersProfileList.firstWhereOrNull((p) => p.uid == targetUserId);

    if (targetPerson == null) {
      print(
          "ProfileController Warning: Person $targetUserId not found for like toggle.");
      return;
    }

    DocumentReference currentUserLikesTargetRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("likesSent")
        .doc(targetUserId);

    DocumentReference targetLikesCurrentUserRef = FirebaseFirestore.instance
        .collection("users")
        .doc(targetUserId)
        .collection("likesSent")
        .doc(currentUserId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot currentUserLikesTargetSnap =
        await transaction.get(currentUserLikesTargetRef);
        DocumentSnapshot targetLikesCurrentUserSnap =
        await transaction.get(targetLikesCurrentUserRef);

        if (currentUserLikesTargetSnap.exists) {
          transaction.delete(currentUserLikesTargetRef);
          if (targetLikesCurrentUserSnap.exists) {
            targetPerson.likeStatus.value = LikeStatus.targetUserLikedCurrentUser;
          } else {
            targetPerson.likeStatus.value = LikeStatus.none;
          }
          print("ProfileController: User $currentUserId unliked $targetUserId.");
        } else {
          transaction.set(
              currentUserLikesTargetRef, {'likedAt': FieldValue.serverTimestamp()});
          if (targetLikesCurrentUserSnap.exists) {
            targetPerson.likeStatus.value = LikeStatus.mutualLike;
            print(
                "ProfileController: User $currentUserId liked $targetUserId. It's a MUTUAL like!");
          } else {
            targetPerson.likeStatus.value = LikeStatus.currentUserLiked;
            print(
                "ProfileController: User $currentUserId liked $targetUserId. Waiting for target to like back.");
          }
        }
      });
    } catch (e) {
      print(
          "ProfileController: Error in toggleLike transaction for $targetUserId: $e");
      // Optionally, revert optimistic UI update if any
    }
  }

  Future<void> _initializeAndStreamProfiles() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      print(
          "ProfileController: _initializeAndStreamProfiles called but user is null.");
      allUsersProfileList.clear();
      usersProfileList.clear();
      currentUserProfile.value = null;
      _currentUserOrientation.value = null; // Correctly assigns null
      return;
    }

    print("ProfileController: Initializing for user: $currentUserId");
    _profilesStreamSubscription?.cancel();

    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .get();

      if (!currentUserDoc.exists || currentUserDoc.data() == null) {
        print(
            "ProfileController: Current user document ($currentUserId) not found or has no data.");
        allUsersProfileList.clear();
        usersProfileList.clear();
        return;
      }

      currentUserProfile.value = Person.fromDataSnapshot(currentUserDoc);
      // MODIFIED: Correct assignment from nullable to nullable
      _currentUserOrientation.value =
          currentUserProfile.value?.orientation?.toLowerCase();

      // MODIFIED: Check for null on _currentUserOrientation.value
      if (_currentUserOrientation.value == null) {
        print(
            "ProfileController: Current user '$currentUserId' orientation not found.");
        allUsersProfileList.clear();
        usersProfileList.clear();
        return;
      }

      String targetOrientation;
      // MODIFIED: Safe access to _currentUserOrientation.value
      final String? currentOrientation = _currentUserOrientation.value;

      if (currentOrientation == 'adam') {
        targetOrientation = 'eve';
      } else if (currentOrientation == 'eve') {
        targetOrientation = 'adam';
      } else {
        print(
            "ProfileController: Unknown current user orientation ('$currentOrientation')");
        allUsersProfileList.clear();
        usersProfileList.clear();
        return;
      }

      print(
          "ProfileController: User '$currentUserId' orientation: $currentOrientation, fetching $targetOrientation profiles.");

      Stream<QuerySnapshot> profilesStream = FirebaseFirestore.instance
          .collection("users")
          .where("uid", isNotEqualTo: currentUserId)
          .where("orientation", isEqualTo: targetOrientation)
          .snapshots();

      _profilesStreamSubscription =
          profilesStream.asyncMap((queryDataSnapshot) async {
            print(
                "ProfileController: Stream for user '$currentUserId' received ${queryDataSnapshot.docs.length} profiles matching target orientation '$targetOrientation'.");
            List<Person> profilesList = [];
            for (var eachProfileDoc in queryDataSnapshot.docs) {
              Person person = Person.fromDataSnapshot(eachProfileDoc);
              person.isFavorite.value = favoritedUserIds.contains(person.uid);
              await _updateInitialLikeStatusForPerson(person, currentUserId);
              profilesList.add(person);
            }
            return profilesList;
          }).listen((profilesWithLikeStatus) {
            allUsersProfileList.assignAll(profilesWithLikeStatus); // MODIFIED
            usersProfileList.assignAll(filteredUsersProfileList); // MODIFIED Apply filters
            print(
                "ProfileController: allUsersProfileList updated with ${profilesWithLikeStatus.length} profiles. Filtered list has ${usersProfileList.length} profiles.");
          }, onError: (e) {
            print(
                "ProfileController: Error in profiles stream for user '$currentUserId': $e");
            allUsersProfileList.clear();
            usersProfileList.clear();
            currentUserProfile.value = null;
            _currentUserOrientation.value = null;
          });
    } catch (e) {
      print(
          "ProfileController: General Error in _initializeAndStreamProfiles for user '$currentUserId': $e");
      allUsersProfileList.clear();
      usersProfileList.clear();
      currentUserProfile.value = null;
      _currentUserOrientation.value = null;
    }
  }


  // --- Profile Viewers Feature Methods ---
  Future<void> recordProfileView(String viewedUserId) async {
    print("DEBUG: recordProfileView CALLED. Viewed User ID: $viewedUserId, Current User ID: ${FirebaseAuth.instance.currentUser?.uid}"); // Add/modify this line
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId == viewedUserId) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(viewedUserId)
          .collection(profileViewersSubCollection)
          .doc(currentUserId)
          .set({'viewedAt': FieldValue.serverTimestamp()});
      print(
          "ProfileController: User $currentUserId viewed profile $viewedUserId.");
    } catch (e) {
      print("ProfileController: Error recording profile view for $viewedUserId: $e");
    }
  }

  void _listenToUsersWhoViewedMe(String currentUserId) {
    _usersWhoViewedMeSubscription?.cancel();
    _usersWhoViewedMeSubscription = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection(profileViewersSubCollection)
        .snapshots()
        .asyncMap((snapshot) async {
      List<String> viewerUids = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        Timestamp? timestamp = data['viewedAt'] as Timestamp?;
        if (timestamp != null) {
          DateTime viewedAt = timestamp.toDate();
          if (DateTime.now().difference(viewedAt).inHours <= 36) {
            viewerUids.add(doc.id);
          } else {
            print("ProfileController: Expired view from ${doc.id}, not adding.");
          }
        }
      }

      List<Person> viewers = [];
      if (viewerUids.isNotEmpty) {
        for (String uid in viewerUids) { // Iterate directly over UIDs
          try {
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .get();
            if (userDoc.exists) {
              Person person = Person.fromDataSnapshot(userDoc);
              viewers.add(person);
            }
          } catch (e) {
            print("ProfileController: Error fetching profile for viewer $uid: $e");
          }
        }
      }
      return viewers;
    }).listen((fetchedViewers) {
      usersWhoViewedMeList.assignAll(fetchedViewers); // MODIFIED
      print(
          "ProfileController: Updated list of users who viewed me: ${usersWhoViewedMeList.length} viewers.");
    }, onError: (error) {
      print(
          "ProfileController: Error listening to users who viewed me: $error");
      usersWhoViewedMeList.clear();
    });
  }
}
