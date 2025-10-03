import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/filter_preferences.dart';
import 'package:eavzappl/models/person.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/like_controller.dart';

enum ProfileLoadingStatus { loading, loaded, error }

class ProfileController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- STATE MANAGEMENT ---
  final RxBool isInitialized = false.obs;

  // --- PRIVATE SOURCE OF TRUTH DATA ---
  final RxList<String> _favoriteUids = <String>[].obs;
  final Rx<Person?> _currentUserProfile = Rx<Person?>(null);

  // --- PUBLIC UI-FACING REACTIVE LISTS ---
  final RxList<Person> swipingProfileList = <Person>[].obs;
  final RxList<Person> usersWhoViewedMe = <Person>[].obs;
  final RxList<Person> usersWhoHaveLikedMe = <Person>[].obs;
  final RxList<Person> usersIHaveLiked = <Person>[].obs;
  final RxList<Person> usersIHaveFavourited = <Person>[].obs;

  // --- PUBLIC DERIVED STATE ---
  final Rx<FilterPreferences> activeFilters = FilterPreferences.initial().obs;

  // --- ASYNC/LOADING STATE ---
  final Rx<ProfileLoadingStatus> loadingStatus = ProfileLoadingStatus.loading.obs;
  final RxBool isTogglingFavorite = false.obs;

  // --- STREAM SUBSCRIPTIONS ---
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

  @override
  void onInit() {
    super.onInit();
    _authStateSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _initializeAllStreams(user.uid);
      } else {
        _clearAllState();
      }
    });
  }

  @override
  void onClose() {
    _cancelAllSubscriptions();
    super.onClose();
  }

  // FIXED
  void applyFilters(FilterPreferences newFilters) {
    activeFilters.value = newFilters;
    final currentUserId = _auth.currentUser?.uid;
    final currentUserProfile = _currentUserProfile.value;

    if (currentUserId != null && currentUserProfile != null) {
      // FIX IS HERE: Find the LikeController and pass it along
      final LikeController likeController = Get.find();
      _listenToSwipingProfiles(currentUserId, currentUserProfile, likeController);
    } else {
      log('Could not apply filters because user or profile was not loaded.', name: 'ProfileController');
    }
  }

  Future<void> forceReload() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      log("Forcing a reload of all streams.", name: "ProfileController");
      // First, tear down everything.
      _clearAllState();
      // Now, initialize again with the current user.
      await _initializeAllStreams(currentUser.uid);
    }
  }


  Future<void> toggleFavoriteStatus(String targetUid) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    isTogglingFavorite.value = true;
    final docRef = _firestore.collection("users").doc(currentUserId).collection("userFavorites").doc(targetUid);

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
      await _firestore.collection("users").doc(viewedUserId).collection("profileViewLog").doc(currentUserId).set({'lastViewed': FieldValue.serverTimestamp()});
    } catch (e, s) {
      log('Error recording profile view for $viewedUserId', name: 'ProfileController', error: e, stackTrace: s);
    }
  }

  // --- DATA FETCHING & STREAMING ---
  // FIXED
  Future<void> _initializeAllStreams(String userId) async {
    // First, cancel any previous user's document listener
    _userDocSubscription?.cancel();

    loadingStatus.value = ProfileLoadingStatus.loading;
    isInitialized.value = false;

    // Listen to the user's own document for real-time updates (or creation)
    _userDocSubscription = _firestore.collection("users").doc(userId).snapshots().listen(
            (userDoc) {
          if (userDoc.exists && !isInitialized.value) {
            // The document now exists, and we haven't initialized yet. Let's go!
            log('User document for $userId found, proceeding with initialization.', name: 'ProfileController');

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

            isInitialized.value = true;
            loadingStatus.value = ProfileLoadingStatus.loaded; // Make sure to update status
          } else if (!userDoc.exists) {
            // This is normal for a brand new user. We just wait.
            log('User document for $userId not found yet, waiting for creation...', name: 'ProfileController');
          }
        },
        onError: (e, s) {
          log('Fatal error in user document stream', name: 'ProfileController', error: e, stackTrace: s);
          loadingStatus.value = ProfileLoadingStatus.error;
          isInitialized.value = false;
        }
    );
  }


  void _listenToSwipingProfiles(String userId, Person currentUserProfile, LikeController likeController) {
    _swipingProfilesSubscription?.cancel();

    Query query = _firestore.collection('users').where("uid", isNotEqualTo: userId);

    // Now, use the object that was passed in. It's guaranteed to be available.
    final String? currentUserOrientation = currentUserProfile.orientation?.toLowerCase().trim();
    String? targetOrientation;

    if (currentUserOrientation == 'adam') {
      targetOrientation = 'eve';
    } else if (currentUserOrientation == 'eve') {
      targetOrientation = 'adam';
    }

    if (targetOrientation != null) {
      query = query.where("orientation", isEqualTo: targetOrientation);
    } else {
      log('Could not determine target orientation for user $userId. Current user orientation is $currentUserOrientation.', name: 'ProfileController');
      swipingProfileList.assignAll([]);
      loadingStatus.value = ProfileLoadingStatus.loaded;
      return;
    }

    final filters = activeFilters.value;
    if (filters.gender != null && filters.gender != 'Any') {
      query = query.where('gender', isEqualTo: filters.gender);
    }
    if (filters.ethnicity != null && filters.ethnicity != 'Any') {
      query = query.where('ethnicity', isEqualTo: filters.ethnicity);
    }

    _swipingProfilesSubscription = query.snapshots().listen((snapshot) async { // Add 'async' here
      if (snapshot.docs.isEmpty) {
        swipingProfileList.clear();
        loadingStatus.value = ProfileLoadingStatus.loaded;
        return;
      }
      // 1. Create the list of profiles from the snapshot
      final profiles = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return Person.fromJson(data);
      }).toList();

      // 2. Extract the user IDs from those profiles
      final userIds = profiles.map((p) => p.uid!).toList();
      // 3. Command the LikeController to preload the statuses
      if (userIds.isNotEmpty) {
        final LikeController likeController = Get.find();
        await likeController.preloadLikeStatuses(userIds);
      }
      // 4. Update the public list that the UI is watching
      swipingProfileList.assignAll(profiles);
      // This old method is no longer needed here, as LikeController handles it
      // _updateLikeStatusMap();
      loadingStatus.value = ProfileLoadingStatus.loaded;

    }, onError: (e) {
      log('Error in swiping profiles stream', name: 'ProfileController', error: e);
      loadingStatus.value = ProfileLoadingStatus.error;
    });
  }


  void _listenToFavorites(String userId) {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = _firestore.collection("users").doc(userId).collection("userFavorites").snapshots().listen((snapshot) {
      final uids = snapshot.docs.map((doc) => doc.id).toList();
      _favoriteUids.assignAll(uids);
      _fetchProfilesForUiList(uids, usersIHaveFavourited);
    }, onError: (e) => log('Error in favorites stream', name: 'ProfileController', error: e));
  }

  // FIXED
  void _listenToLikes(String userId, LikeController likeController) {
    _sentLikesSubscription?.cancel();
    _sentLikesSubscription = _firestore.collection('users').doc(userId).collection('likesSent').snapshots().listen((snapshot) {
      final uids = snapshot.docs.map((doc) => doc.id).toList();
      // This is now correct because likeController is passed in.
      likeController.updateSentLikes(uids);
      _fetchProfilesForUiList(uids, usersIHaveLiked);
    }, onError: (e) => log('Error in sent likes stream', name: 'ProfileController', error: e));

    _receivedLikesSubscription?.cancel();
    _receivedLikesSubscription = _firestore.collection('users').doc(userId).collection('likesReceived').snapshots().listen((snapshot) {
      final uids = snapshot.docs.map((doc) => doc.id).toList();
      // This is now correct because likeController is passed in.
      likeController.updateReceivedLikes(uids);
      _fetchProfilesForUiList(uids, usersWhoHaveLikedMe);
    }, onError: (e) => log('Error in received likes stream', name: 'ProfileController', error: e));
  }


  // FIXED
  void _listenToMatches(String userId, LikeController likeController) { // Capital 'C'
    _matchesSubscription?.cancel();
    _matchesSubscription = _firestore.collection('matches').where('users', arrayContains: userId).snapshots().listen((snapshot) {
      final uids = <String>{};
      for (final doc in snapshot.docs) {
        final List<dynamic> users = doc.data()['users'] ?? [];
        final otherUser = users.firstWhere((uid) => uid != userId, orElse: () => null);
        if (otherUser != null) {
          uids.add(otherUser);
        }
      }
      // This is now correct because likeController is passed in.
      likeController.updateMatches(uids.toList());
    }, onError: (e) => log('Error in matches stream', name: 'ProfileController', error: e));
  }


  void _listenToViewers(String userId) {
    _viewersSubscription?.cancel();
    _viewersSubscription = _firestore.collection('users').doc(userId).collection('profileViewLog').orderBy('lastViewed', descending: true).limit(50).snapshots().listen((snapshot) {
      final uids = snapshot.docs.map((doc) => doc.id).toList();
      _fetchProfilesForUiList(uids, usersWhoViewedMe);
    }, onError: (e) => log('Error in viewers stream', name: 'ProfileController', error: e));
  }

  Future<void> _fetchProfilesForUiList(List<String> uids, RxList<Person> uiList) async {
    if (uids.isEmpty) {
      uiList.clear();
      return;
    }
    try {
      final querySnapshot = await _firestore.collection('users').where(FieldPath.documentId, whereIn: uids).get();
      final profiles = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return Person.fromJson(data);
      }).toList();
      uiList.assignAll(profiles);
    } catch (e) {
      log('Error fetching profiles for UI list', name: 'ProfileController', error: e);
    }
  }

  void _clearAllState() {
    _cancelAllSubscriptions();
    isInitialized.value = false;
    _favoriteUids.clear();
    _currentUserProfile.value = null;
    swipingProfileList.clear();
    usersWhoViewedMe.clear();
    usersWhoHaveLikedMe.clear();
    usersIHaveLiked.clear();
    usersIHaveFavourited.clear();
    loadingStatus.value = ProfileLoadingStatus.loading;
  }

  void _cancelAllSubscriptions() {
    _userDocSubscription?.cancel();
    _authStateSubscription?.cancel();
    _swipingProfilesSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _sentLikesSubscription?.cancel();
    _receivedLikesSubscription?.cancel();
    _matchesSubscription?.cancel();
    _viewersSubscription?.cancel();
  }
}
