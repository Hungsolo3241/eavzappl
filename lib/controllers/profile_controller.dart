import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/filter_preferences.dart';
import 'package:eavzappl/models/person.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/like_controller.dart';

import 'dart:convert'; // For jsonDecode
import 'package:shared_preferences/shared_preferences.dart';

enum ProfileLoadingStatus { initial, loading, done, error }

class ProfileController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- STATE MANAGEMENT ---
  final Completer<void> _initCompleter = Completer<void>();
  late final Future<void> initialization;

  // --- PRIVATE SOURCE OF TRUTH DATA ---
  final RxList<Person> swipingProfiles = <Person>[].obs;
  final RxList<String> _favoriteUids = <String>[].obs;
  final Rx<Person?> _currentUserProfile = Rx<Person?>(null);

  // --- PUBLIC UI-FACING REACTIVE LISTS ---
  final RxList<Person> swipingProfileList = <Person>[].obs;
  final RxList<Person> usersWhoViewedMe = <Person>[].obs;
  final RxList<Person> usersWhoHaveLikedMe = <Person>[].obs;
  final RxList<Person> usersIHaveLiked = <Person>[].obs;
  final RxList<Person> usersIHaveFavourited = <Person>[].obs;

  // --- PUBLIC DERIVED STATE ---
  final Rx<FilterPreferences> activeFilters = FilterPreferences
      .initial()
      .obs;

  // --- ASYNC/LOADING STATE ---
  final Rx<ProfileLoadingStatus> loadingStatus = Rx(
      ProfileLoadingStatus.initial);
  final RxBool isTogglingFavorite = false.obs;

  // --- STREAM SUBSCRIPTIONS ---
  Completer<void>? _swipingProfilesCompleter;
  StreamSubscription? _authStateSubscription;
  StreamSubscription? _swipingProfilesSubscription;
  StreamSubscription? _favoritesSubscription;
  StreamSubscription? _sentLikesSubscription;
  StreamSubscription? _receivedLikesSubscription;
  StreamSubscription? _matchesSubscription;
  StreamSubscription? _viewersSubscription;
  StreamSubscription? _userDocSubscription;

  // --- PUBLIC GETTERS ---
  bool isFavorite(String uid) => _favoriteUids.contains(uid);

  // In lib/controllers/profile_controller.dart

  @override
  void onInit() {
    super.onInit();
    initialization = _initCompleter.future;
  }

  // NEW, SIMPLIFIED METHOD FOR PULL-TO-REFRESH
  Future<void> refreshSwipingProfiles() async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      log('Cannot refresh, no user ID found.', name: 'ProfileController');
      return; // Silently exit if no user
    }

    log('Pull-to-refresh triggered.', name: 'ProfileController');

    // The RefreshIndicator's Future will complete when this method completes.
    // _initializeAllStreams already sets the loading status, which handles the UI.
    // The logic inside _listenToSwipingProfiles that completes the completer
    // will now only apply to the forceReload/login flow, which is correct.
    await initializeAllStreams(currentUserId);
  }


  Future<void> forceReload() async {
    // This method is now just an alias for the new, correct refresh logic.
    await refreshSwipingProfiles();
  }

// Method to update, save, and re-apply filters.
  Future<void> updateAndApplyFilters(FilterPreferences newFilters) async {
    activeFilters.value = newFilters; // Update the live filters
    await _saveFiltersToPrefs(newFilters); // Save them to device storage
    await fetchSwipingProfiles(); // Re-fetch profiles with the new filters
  }

// Method to reset filters to default, save, and re-apply.
  Future<void> resetFilters() async {
    final defaultFilters = FilterPreferences
        .initial(); // Get a fresh, empty filter object
    activeFilters.value = defaultFilters;
    await _saveFiltersToPrefs(defaultFilters);
    await fetchSwipingProfiles();
  }


  Future<void> fetchSwipingProfiles() async {
    final currentUserId = _auth.currentUser?.uid;
    final currentUserProfile = _currentUserProfile.value;

    if (currentUserId != null && currentUserProfile != null) {
      log("Fetching swiping profiles with new filters...",
          name: "ProfileController");
      // Re-use the existing stream logic by just calling it again.
      // It will cancel the old stream and start a new one with the updated activeFilters.
      final LikeController likeController = Get.find();
      _listenToSwipingProfiles(
          currentUserId, currentUserProfile, likeController);
    } else {
      log('Could not fetch profiles because user or profile was not loaded.',
          name: 'ProfileController');
      // If there's no user, there are no profiles to show.
      swipingProfileList.clear();
      loadingStatus.value = ProfileLoadingStatus.done;
    }
  }

  Future<void> _saveFiltersToPrefs(FilterPreferences filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 1. Convert the FilterPreferences object to a Map using the generated toJson()
      final Map<String, dynamic> filtersMap = filters.toJson();
      // 2. Encode the Map into a JSON String before saving
      final String filtersJsonString = json.encode(filtersMap);
      await prefs.setString('user_filters', filtersJsonString);
      log('Filters saved to local storage.', name: 'ProfileController');
    } catch (e) {
      log('Failed to save filters', name: 'ProfileController', error: e);
    }
  }

  Future<void> _loadFiltersFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? filtersJsonString = prefs.getString('user_filters');
      if (filtersJsonString != null) {
        // 1. Decode the JSON String from storage into a Map
        final Map<String, dynamic> filtersMap = json.decode(filtersJsonString);
        // 2. Use the generated fromJson factory to create the object from the Map
        activeFilters.value = FilterPreferences.fromJson(filtersMap);
        log('Filters successfully loaded from local storage.',
            name: 'ProfileController');
      } else {
        log('No saved filters found. Using initial filters.',
            name: 'ProfileController');
        // Set to initial if nothing is saved
        activeFilters.value = FilterPreferences.initial();
      }
    } catch (e) {
      log('Failed to load filters', name: 'ProfileController', error: e);
      // Fallback to initial filters on any error
      activeFilters.value = FilterPreferences.initial();
    }
  }


  Future<void> toggleFavoriteStatus(String targetUid) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    isTogglingFavorite.value = true;
    final docRef = _firestore.collection("users").doc(currentUserId).collection(
        "userFavorites").doc(targetUid);

    try {
      if (_favoriteUids.contains(targetUid)) {
        await docRef.delete();
      } else {
        await docRef.set({'favoritedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      log('Error toggling favorite', name: 'ProfileController', error: e);
    } finally {
      isTogglingFavorite.value = false;
    }
  }

  Future<void> recordProfileView(String viewedUserId) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId == viewedUserId) return;
    try {
      await _firestore.collection("users").doc(viewedUserId).collection(
          "profileViewLog").doc(currentUserId).set(
          {'lastViewed': FieldValue.serverTimestamp()});
    } catch (e, s) {
      log('Error recording profile view for $viewedUserId',
          name: 'ProfileController', error: e, stackTrace: s);
    }
  }

  // --- DATA FETCHING & STREAMING ---
  Future<void> initializeAllStreams(String userId) async {
    // First, cancel any previous user's document listener
    _userDocSubscription?.cancel();

    loadingStatus.value = ProfileLoadingStatus.loading;

    await _loadFiltersFromPrefs(); // Load filters before fetching any data
    // Listen to the user's own document for real-time updates (or creation)
    _userDocSubscription =
        _firestore.collection("users").doc(userId).snapshots().listen(
                (userDoc) {
              if (userDoc.exists) {
                // The document now exists, and we haven't initialized yet. Let's go!
                log(
                    'User document for $userId found, proceeding with initialization.',
                    name: 'ProfileController');

                final data = userDoc.data() as Map<String, dynamic>;
                data['uid'] = userDoc.id;
                final person = Person.fromJson(data);
                _currentUserProfile.value = person;

                final LikeController likeController = Get.find();

                _listenToSwipingProfiles(userId, person, likeController);
                _listenToFavorites(userId);
                _listenToLikes(userId, likeController);
                _listenToMatches(userId, likeController);
                _listenToViewers(userId);

                if (!_initCompleter.isCompleted) {
                  _initCompleter.complete();
                }
              } else if (!userDoc.exists) {
                // This is normal for a brand new user. We just wait.
                log(
                    'User document for $userId not found yet, waiting for creation...',
                    name: 'ProfileController');
                loadingStatus.value = ProfileLoadingStatus.done;
              }
            },
            onError: (e, s) {
              log('Fatal error in user document stream',
                  name: 'ProfileController', error: e, stackTrace: s);
              loadingStatus.value = ProfileLoadingStatus.error;
            }
        );
  }


  void _listenToSwipingProfiles(String userId, Person currentUserProfile,
      LikeController likeController) {
    _swipingProfilesSubscription?.cancel();

    // 1. BUILD A BROAD, EFFICIENT QUERY
    Query query = _firestore.collection('users').where(
        "uid", isNotEqualTo: userId);
    final String? currentUserOrientation = currentUserProfile.orientation
        ?.toLowerCase().trim();
    String? targetOrientation;

    if (currentUserOrientation == 'adam') {
      targetOrientation = 'eve';
    } else if (currentUserOrientation == 'eve') {
      targetOrientation = 'adam';
    }

    if (targetOrientation != null) {
      query = query.where("orientation", isEqualTo: targetOrientation);
    } else {
      log('No target orientation found for $userId',
          name: 'ProfileController');
      return;
    }

    final filters = activeFilters.value;

    // Use Firestore ONLY for the age range filter, as it's a range.
    if (filters.ageRange != null) {
      query = query.where(
          'age', isGreaterThanOrEqualTo: filters.ageRange!.start.round());
      query = query.where(
          'age', isLessThanOrEqualTo: filters.ageRange!.end.round());
    }

    // 2. LISTEN TO THE BROAD QUERY
    _swipingProfilesSubscription = query.snapshots().listen((snapshot) async {
      if (_swipingProfilesCompleter != null &&
          !_swipingProfilesCompleter!.isCompleted) {
        _swipingProfilesCompleter!.complete();
        _swipingProfilesCompleter = null; // <-- ADD THIS LINE
      }

      // This gives us all users of the target orientation within the age range.
      var profiles = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return Person.fromJson(data);
      }).toList();

      // 3. --- FILTER LOCALLY (IN DART) ---
      // Now, we apply all the other simple filters here.
      if (filters.gender != null && filters.gender != 'Any') {
        profiles = profiles.where((p) => p.gender == filters.gender).toList();
      }
      if (filters.ethnicity != null && filters.ethnicity != 'Any') {
        profiles =
            profiles.where((p) => p.ethnicity == filters.ethnicity).toList();
      }
      if (filters.relationshipStatus != null &&
          filters.relationshipStatus != 'Any') {
        profiles = profiles.where((p) =>
        p.relationshipStatus == filters.relationshipStatus).toList();
      }
      if (filters.country != null && filters.country!.isNotEmpty) {
        profiles = profiles.where((p) => p.country == filters.country).toList();
      }
      if (filters.province != null && filters.province!.isNotEmpty) {
        profiles =
            profiles.where((p) => p.province == filters.province).toList();
      }
      if (filters.city != null && filters.city!.isNotEmpty) {
        profiles = profiles.where((p) => p.city == filters.city).toList();
      }
      if (filters.wantsHost == true) {
        profiles = profiles.where((p) => p.hostSelection == true).toList();
      }
      if (filters.wantsTravel == true) {
        profiles = profiles.where((p) => p.travelSelection == true).toList();
      }
      // Special 'Professional' logic
      if (filters.profession != null && filters.profession != 'Any') {
        if (filters.profession == 'Professional') {
          profiles = profiles.where((p) =>
          p.profession != 'Student' && p.profession != 'Freelancer').toList();
        } else {
          profiles = profiles
              .where((p) => p.profession == filters.profession)
              .toList();
        }
      }


      // 4. Update the UI with the final, filtered list.
      final userIds = profiles.map((p) => p.uid!).toList();
      if (userIds.isNotEmpty) {
        await likeController.preloadLikeStatuses(userIds);
      }
      swipingProfileList.assignAll(profiles);

      if (loadingStatus.value != ProfileLoadingStatus.done) {
        loadingStatus.value = ProfileLoadingStatus.done;
      }
    }, onError: (e) {
      log('Error in swiping profiles stream', name: 'ProfileController',
          error: e);
      loadingStatus.value = ProfileLoadingStatus.error;
    });
  }


  void _listenToFavorites(String userId) {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = _firestore
        .collection("users")
        .doc(userId)
        .collection("userFavorites")
        .snapshots()
        .listen((snapshot) {
      final uids = snapshot.docs.map((doc) => doc.id).toList();
      _favoriteUids.assignAll(uids);
      _fetchProfilesForUiList(uids, usersIHaveFavourited);
    }, onError: (e) =>
        log('Error in favorites stream', name: 'ProfileController', error: e));
  }

  // FIXED
  void _listenToLikes(String userId, LikeController likeController) {
    _sentLikesSubscription?.cancel();
    _sentLikesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('likesSent')
        .snapshots()
        .listen((snapshot) {
      final uids = snapshot.docs.map((doc) => doc.id).toList();
      // This is now correct because likeController is passed in.
      likeController.updateSentLikes(uids);
      _fetchProfilesForUiList(uids, usersIHaveLiked);
    }, onError: (e) =>
        log('Error in sent likes stream', name: 'ProfileController', error: e));

    _receivedLikesSubscription?.cancel();
    _receivedLikesSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('likesReceived')
        .snapshots()
        .listen((snapshot) {
      final uids = snapshot.docs.map((doc) => doc.id).toList();
      // This is now correct because likeController is passed in.
      likeController.updateReceivedLikes(uids);
      _fetchProfilesForUiList(uids, usersWhoHaveLikedMe);
    }, onError: (e) =>
        log('Error in received likes stream', name: 'ProfileController',
            error: e));
  }

  void _listenToMatches(String userId, LikeController likeController) {
    _matchesSubscription?.cancel();
    _matchesSubscription = _firestore
        .collection('matches')
        .where('users', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      final uids = <String>{};
      for (final doc in snapshot.docs) {
        final List<dynamic> users = doc.data()['users'] ?? [];
        final otherUser = users.firstWhere((uid) => uid != userId,
            orElse: () => null);
        if (otherUser != null) {
          uids.add(otherUser);
        }
      }
      // This is now correct because likeController is passed in.
      likeController.updateMatches(uids.toList());
    }, onError: (e) =>
        log('Error in matches stream', name: 'ProfileController', error: e));
  }


  void _listenToViewers(String userId) {
    _viewersSubscription?.cancel();
    _viewersSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('profileViewLog')
        .orderBy('lastViewed', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      final uids = snapshot.docs.map((doc) => doc.id).toList();
      _fetchProfilesForUiList(uids, usersWhoViewedMe);
    }, onError: (e) =>
        log('Error in viewers stream', name: 'ProfileController', error: e));
  }

  Future<void> _fetchProfilesForUiList(List<String> uids,
      RxList<Person> uiList) async {
    if (uids.isEmpty) {
      uiList.clear();
      return;
    }
    try {
      final querySnapshot = await _firestore.collection('users').where(
          FieldPath.documentId, whereIn: uids).get();
      final profiles = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return Person.fromJson(data);
      }).toList();
      uiList.assignAll(profiles);
    } catch (e) {
      log('Error fetching profiles for UI list', name: 'ProfileController',
          error: e);
    }
  }

  void _cancelAllSubscriptions() {
    log('Clearing all user state and cancelling streams due to logout.',
        name: 'ProfileController');

    // 1. Cancel all active stream subscriptions to prevent errors and memory leaks.
    _userDocSubscription?.cancel();
    _swipingProfilesSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _sentLikesSubscription?.cancel();
    _receivedLikesSubscription?.cancel();
    _matchesSubscription?.cancel();
    _viewersSubscription?.cancel();

    // Do NOT cancel _authStateSubscription here. Let onClose handle that.

    // 2. Clear all local data lists and state variables.
    _currentUserProfile.value = null;
    swipingProfiles.clear();
    _favoriteUids.clear();
    swipingProfileList.clear();
    usersWhoViewedMe.clear();
    usersWhoHaveLikedMe.clear();
    usersIHaveLiked.clear();
    usersIHaveFavourited.clear();
    activeFilters.value = FilterPreferences.initial(); // Reset filters to default
    loadingStatus.value = ProfileLoadingStatus.initial;

    // Also reset the LikeController if it's registered
    if (Get.isRegistered<LikeController>()) {
      Get.find<LikeController>().clear();
    }
  }


  @override
  void onClose() {
    log('ProfileController onClose called. Disposing all subscriptions.', name: 'ProfileController');
    _authStateSubscription?.cancel(); // Cancel the main listener
    _cancelAllSubscriptions(); // And clean up everything else
    super.onClose();
  }

}