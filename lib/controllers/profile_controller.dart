import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/person.dart'; // Make sure LikeStatus is imported if defined here, or from its own file
import 'package:firebase_auth/firebase_auth.dart';
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
  StreamSubscription<List<Person>>? _profilesStreamSubscription; // To manage the profiles stream
  // --- Filter Logic Additions ---
  final Rx<FilterPreferences> activeFilters = Rx<FilterPreferences>(FilterPreferences());

  // --- Favorite Feature Additions ---
  final RxSet<String> favoritedUserIds = RxSet<String>();
  StreamSubscription? _favoritesSubscription;
  // --- End of Favorite Feature Additions ---

  void updateFilters(FilterPreferences newFilters) {
    activeFilters.value = newFilters;
    print("Filters updated in ProfileController. New filters: Age ${newFilters.ageRange}, Ethnicity ${newFilters.ethnicity}, Profession ${newFilters.profession}, Country ${newFilters.country}, Host ${newFilters.wantsHost}, Travel ${newFilters.wantsTravel}");
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
    if (filters.gender != null && filters.gender != "Any" && filters.gender!.isNotEmpty) {
      filteredList = filteredList.where((person) {
        if (person.gender == null) return false;
        return person.gender!.toLowerCase() == filters.gender!.toLowerCase();
      }).toList();
    }

    // Apply Ethnicity Filter
    if (filters.ethnicity != null && filters.ethnicity != "Any") {
      filteredList = filteredList.where((person) =>
      person.ethnicity?.toLowerCase() == filters.ethnicity!.toLowerCase()
      ).toList();
    }

    // Apply Wants Host Filter
    if (filters.wantsHost != null) {
      filteredList = filteredList.where((person) =>
      person.hostSelection == filters.wantsHost
      ).toList();
    }

    // Apply Wants Travel Filter
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

    // Apply Province/State Filter
    if (filters.country != null && filters.country != "Any" && filters.country!.isNotEmpty &&
        filters.province != null && filters.province != "Any" && filters.province!.isNotEmpty) {
      filteredList = filteredList.where((person) =>
      person.province?.toLowerCase() == filters.province!.toLowerCase()
      ).toList();
    }

    // Apply City Filter
    if (filters.country != null && filters.country != "Any" && filters.country!.isNotEmpty &&
        filters.province != null && filters.province != "Any" && filters.province!.isNotEmpty &&
        filters.city != null && filters.city != "Any" && filters.city!.isNotEmpty) {
      filteredList = filteredList.where((person) =>
      person.city?.toLowerCase() == filters.city!.toLowerCase()
      ).toList();
    }
    return filteredList;
  }

  @override
  void onInit() {
    super.onInit();
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print("ProfileController: User is currently signed out!");
        _profilesStreamSubscription?.cancel();
        usersProfileList.value = [];
        currentUserProfile.value = null;
        _currentUserOrientation.value = null;
        favoritedUserIds.clear();
        _favoritesSubscription?.cancel();
        activeFilters.value = FilterPreferences();
      } else {
        print("ProfileController: User is signed in! UID: ${user.uid}. Initializing/Refreshing profiles.");
        _fetchAndStreamUserFavorites(user.uid);
        _initializeAndStreamProfiles();
        activeFilters.value = FilterPreferences();
      }
    });
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _profilesStreamSubscription?.cancel();
    super.onClose();
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
      favoritedUserIds.value = ids;
      _updateFavoriteStatusInProfileList();
      print("ProfileController: User favorites updated: ${favoritedUserIds.length} favorites.");
    }, onError: (error) {
      print("ProfileController: Error fetching user favorites: $error");
    });
  }

  void _updateFavoriteStatusInProfileList() {
    // No need to track 'changed' and call usersProfileList.refresh() here,
    // as individual Person.isFavorite.value changes will be observed by Obx in the UI.
    for (var person in usersProfileList.value) {
      bool isFav = favoritedUserIds.contains(person.uid);
      if (person.isFavorite.value != isFav) { // Compare with .value
        person.isFavorite.value = isFav;     // Set .value
      }
    }
    // usersProfileList.refresh(); // This might be redundant now
  }

  Future<void> toggleFavoriteStatus(String personIdToToggle) async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      print("ProfileController Error: Current user is null. Cannot toggle favorite.");
      return;
    }

    DocumentReference favoriteDocRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("userFavorites")
        .doc(personIdToToggle);

    final personDoc = await favoriteDocRef.get();
    bool newFavoriteState;

    final int personIndex = usersProfileList.value.indexWhere((p) => p.uid == personIdToToggle);

    if (personDoc.exists) {
      await favoriteDocRef.delete();
      newFavoriteState = false;
      print("ProfileController: User $personIdToToggle removed from favorites for $currentUserId");
    } else {
      await favoriteDocRef.set({'favoritedAt': FieldValue.serverTimestamp()});
      newFavoriteState = true;
      print("ProfileController: User $personIdToToggle added to favorites for $currentUserId");
    }

    // Update the local Person object's reactive isFavorite property.
    // The UI (Obx) will react directly to this change.
    if (personIndex != -1) {
      usersProfileList.value[personIndex].isFavorite.value = newFavoriteState; // Set .value
    }
    // favoritedUserIds will be updated by the stream in _fetchAndStreamUserFavorites.
    // usersProfileList.refresh(); // Not needed as Obx reacts to person.isFavorite.value
  }
  // --- End of Favorite Feature Methods ---

  // --- Like Feature Methods ---
  Future<void> _updateInitialLikeStatusForPerson(Person person, String currentUserId) async {
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
      DocumentSnapshot currentUserLikesTargetSnap = await currentUserLikesTargetRef.get();
      DocumentSnapshot targetLikesCurrentUserSnap = await targetLikesCurrentUserRef.get();

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
      print("ProfileController: Error updating initial like status for ${person.uid}: $e");
      person.likeStatus.value = LikeStatus.none;
    }
  }

  Future<void> toggleLike(String targetUserId) async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      print("ProfileController Error: Current user is null. Cannot toggle like.");
      return;
    }

    final int personIndex = usersProfileList.value.indexWhere((p) => p.uid == targetUserId);
    if (personIndex == -1) {
      print("ProfileController Warning: Person $targetUserId not found in usersProfileList for like toggle.");
      return;
    }
    Person targetPerson = usersProfileList.value[personIndex];

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
        DocumentSnapshot currentUserLikesTargetSnap = await transaction.get(currentUserLikesTargetRef);
        DocumentSnapshot targetLikesCurrentUserSnap = await transaction.get(targetLikesCurrentUserRef);

        if (currentUserLikesTargetSnap.exists) {
          transaction.delete(currentUserLikesTargetRef);
          if (targetLikesCurrentUserSnap.exists) {
            targetPerson.likeStatus.value = LikeStatus.targetUserLikedCurrentUser;
          } else {
            targetPerson.likeStatus.value = LikeStatus.none;
          }
          print("ProfileController: User $currentUserId unliked $targetUserId.");
        } else {
          transaction.set(currentUserLikesTargetRef, {'likedAt': FieldValue.serverTimestamp()});
          if (targetLikesCurrentUserSnap.exists) {
            targetPerson.likeStatus.value = LikeStatus.mutualLike;
            print("ProfileController: User $currentUserId liked $targetUserId. It's a MUTUAL like!");
          } else {
            targetPerson.likeStatus.value = LikeStatus.currentUserLiked;
            print("ProfileController: User $currentUserId liked $targetUserId. Waiting for target to like back.");
          }
        }
      });
    } catch (e) {
      print("ProfileController: Error in toggleLike transaction for $targetUserId: $e");
    }
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
    _profilesStreamSubscription?.cancel();

    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .get();

      if (!currentUserDoc.exists || currentUserDoc.data() == null) {
        print("ProfileController: Current user document ($currentUserId) not found or has no data.");
        usersProfileList.value = [];
        return;
      }

      currentUserProfile.value = Person.fromDataSnapshot(currentUserDoc);
      _currentUserOrientation.value = currentUserProfile.value?.orientation?.toLowerCase();

      if (_currentUserOrientation.value == null) {
        print("ProfileController: Current user '$currentUserId' orientation not found.");
        usersProfileList.value = [];
        return;
      }

      String targetOrientation;
      if (_currentUserOrientation.value == 'adam') {
        targetOrientation = 'eve';
      } else if (_currentUserOrientation.value == 'eve') {
        targetOrientation = 'adam';
      } else {
        print("ProfileController: Unknown current user orientation ('${_currentUserOrientation.value}')");
        usersProfileList.value = [];
        return;
      }

      print("ProfileController: User '$currentUserId' orientation: ${_currentUserOrientation.value}, fetching $targetOrientation profiles.");

      Stream<QuerySnapshot> profilesStream = FirebaseFirestore.instance
          .collection("users")
          .where("uid", isNotEqualTo: currentUserId)
          .where("orientation", isEqualTo: targetOrientation)
          .snapshots();

      _profilesStreamSubscription = profilesStream.asyncMap((queryDataSnapshot) async {
        print("ProfileController: Stream for user '$currentUserId' received ${queryDataSnapshot.docs.length} profiles matching target orientation '$targetOrientation'.");
        List<Person> profilesList = [];
        for (var eachProfileDoc in queryDataSnapshot.docs) {
          Person person = Person.fromDataSnapshot(eachProfileDoc);
          // Update reactive isFavorite.value based on the favoritedUserIds set
          person.isFavorite.value = favoritedUserIds.contains(person.uid); 
          await _updateInitialLikeStatusForPerson(person, currentUserId);
          profilesList.add(person);
        }
        return profilesList;
      }).listen((profilesWithLikeStatus) {
        usersProfileList.value = profilesWithLikeStatus;
        print("ProfileController: usersProfileList updated with ${profilesWithLikeStatus.length} profiles including like statuses.");
      }, onError: (e) {
        print("ProfileController: Error in profiles stream for user '$currentUserId': $e");
        usersProfileList.value = [];
        currentUserProfile.value = null;
        _currentUserOrientation.value = null;
      });

    } catch (e) {
      print("ProfileController: General Error in _initializeAndStreamProfiles for user '$currentUserId': $e");
      usersProfileList.value = [];
      currentUserProfile.value = null;
      _currentUserOrientation.value = null;
    }
  }
}
