import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/filter_preferences.dart';
import 'package:eavzappl/models/person.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

enum ProfileLoadingStatus { loading, loaded, error }

class ProfileController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- STATE MANAGEMENT ---
  final RxBool isInitialized = false.obs;

  // --- PRIVATE SOURCE OF TRUTH DATA ---
  final RxList<String> _sentLikeUids = <String>[].obs;
  final RxList<String> _receivedLikeUids = <String>[].obs;
  final RxSet<String> _matchedUids = <String>{}.obs;
  final RxList<String> _favoriteUids = <String>[].obs;
  final Rx<Person?> _currentUserProfile = Rx<Person?>(null);

  // --- PUBLIC UI-FACING REACTIVE LISTS ---
  final RxList<Person> swipingProfileList = <Person>[].obs;
  final RxList<Person> usersWhoViewedMe = <Person>[].obs;
  final RxList<Person> usersWhoHaveLikedMe = <Person>[].obs;
  final RxList<Person> usersIHaveLiked = <Person>[].obs;
  final RxList<Person> usersIHaveFavourited = <Person>[].obs;

  // --- PUBLIC DERIVED STATE ---
  final RxMap<String, LikeStatus> likeStatusMap = <String, LikeStatus>{}.obs;
  final Rx<FilterPreferences> activeFilters = FilterPreferences.initial().obs;

  // --- ASYNC/LOADING STATE ---
  final Rx<ProfileLoadingStatus> loadingStatus = ProfileLoadingStatus.loading.obs;
  final RxBool isTogglingLike = false.obs;
  final RxBool isTogglingFavorite = false.obs;

  // --- STREAM SUBSCRIPTIONS ---
  StreamSubscription? _authStateSubscription;
  StreamSubscription? _swipingProfilesSubscription;
  StreamSubscription? _favoritesSubscription;
  StreamSubscription? _sentLikesSubscription;
  StreamSubscription? _receivedLikesSubscription;
  StreamSubscription? _matchesSubscription;
  StreamSubscription? _viewersSubscription;

  // --- PUBLIC GETTERS ---
  bool isFavorite(String uid) => _favoriteUids.contains(uid);
  LikeStatus getLikeStatus(String uid) => likeStatusMap[uid] ?? LikeStatus.none;

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
    everAll([_sentLikeUids, _receivedLikeUids, _matchedUids], (_) => _updateLikeStatusMap());
  }

  @override
  void onClose() {
    _cancelAllSubscriptions();
    super.onClose();
  }

  void applyFilters(FilterPreferences newFilters) {
    activeFilters.value = newFilters;
    final currentUserId = _auth.currentUser?.uid;

    // 1. Get the current user profile from your state.
    final currentUserProfile = _currentUserProfile.value;

    // 2. Ensure BOTH the user ID and the profile object are not null before proceeding.
    if (currentUserId != null && currentUserProfile != null) {
      // 3. Call the function with BOTH required arguments.
      _listenToSwipingProfiles(currentUserId, currentUserProfile);
    } else {
      // Optional: Log an error if the profile isn't available when filters are applied.
      log(
        'Could not apply filters because user or profile was not loaded.',
        name: 'ProfileController',
      );
    }
  }


  // --- CORE ACTIONS ---
  Future<void> toggleLike(String targetUid) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || isTogglingLike.isTrue) return;

    isTogglingLike.value = true;
    final batch = _firestore.batch();
    final currentUserLikesSentRef = _firestore.collection('users').doc(currentUserId).collection('likesSent').doc(targetUid);
    final targetUserLikesReceivedRef = _firestore.collection('users').doc(targetUid).collection('likesReceived').doc(currentUserId);
    final matchId = [currentUserId, targetUid]..sort();
    final matchRef = _firestore.collection('matches').doc(matchId.join('_'));

    try {
      final bool isCurrentlyLiked = _sentLikeUids.contains(targetUid);
      if (isCurrentlyLiked) {
        batch.delete(currentUserLikesSentRef);
        batch.delete(targetUserLikesReceivedRef);
        batch.delete(matchRef);
      } else {
        final likeData = {'timestamp': FieldValue.serverTimestamp()};
        batch.set(currentUserLikesSentRef, likeData);
        batch.set(targetUserLikesReceivedRef, likeData);
        if (_receivedLikeUids.contains(targetUid)) {
          batch.set(matchRef, {'users': [currentUserId, targetUid], 'createdAt': FieldValue.serverTimestamp()});
        }
      }
      await batch.commit();
    } catch (e, s) {
      log('Error toggling like', name: 'ProfileController', error: e, stackTrace: s);
    } finally {
      isTogglingLike.value = false;
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

  // --- STATE COMPUTATION ---
  void _updateLikeStatusMap() {
    final newStatusMap = <String, LikeStatus>{};
    final allKnownUids = {...swipingProfileList.map((p) => p.uid).whereType<String>(), ..._sentLikeUids, ..._receivedLikeUids, ..._matchedUids};

    for (final uid in allKnownUids) {
      if (_matchedUids.contains(uid)) {
        newStatusMap[uid] = LikeStatus.mutualLike;
      } else if (_sentLikeUids.contains(uid)) {
        newStatusMap[uid] = LikeStatus.liked;
      } else {
        newStatusMap[uid] = LikeStatus.none;
      }
    }
    likeStatusMap.value = newStatusMap;
  }

  // --- DATA FETCHING & STREAMING ---
  Future<void> _initializeAllStreams(String userId) async {
    loadingStatus.value = ProfileLoadingStatus.loading;
    isInitialized.value = false;

    try {
      final currentUserDoc = await _firestore.collection("users").doc(userId).get();

      if (currentUserDoc.exists) {
        final data = currentUserDoc.data() as Map<String, dynamic>;
        data['uid'] = currentUserDoc.id;
        final person = Person.fromJson(data); // Create a local variable
        _currentUserProfile.value = person;   // Update the state for the rest of the app

        // --- THE FIX ---
        // Pass the 'person' object directly to the function that needs it.
        _listenToSwipingProfiles(userId, person);

        // These other functions don't depend on the current user's profile data, so they are fine.
        _listenToFavorites(userId);
        _listenToLikes(userId);
        _listenToMatches(userId);
        _listenToViewers(userId);

        isInitialized.value = true;
      } else {
        throw Exception("User document not found for UID: $userId");
      }
    } catch(e, s) {
      log('Fatal error during initialization', name: 'ProfileController', error: e, stackTrace: s);
      loadingStatus.value = ProfileLoadingStatus.error;
      isInitialized.value = false;
    }
  }

  void _listenToSwipingProfiles(String userId, Person currentUserProfile) {
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

    _swipingProfilesSubscription = query.snapshots().listen((snapshot) {
      final profiles = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return Person.fromJson(data);
      }).toList();
      swipingProfileList.assignAll(profiles);
      _updateLikeStatusMap();
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

  void _listenToLikes(String userId) {
    _sentLikesSubscription?.cancel();
    _sentLikesSubscription = _firestore.collection('users').doc(userId).collection('likesSent').snapshots().listen((snapshot) {
      final uids = snapshot.docs.map((doc) => doc.id).toList();
      _sentLikeUids.assignAll(uids);
      _fetchProfilesForUiList(uids, usersIHaveLiked);
    }, onError: (e) => log('Error in sent likes stream', name: 'ProfileController', error: e));

    _receivedLikesSubscription?.cancel();
    _receivedLikesSubscription = _firestore.collection('users').doc(userId).collection('likesReceived').snapshots().listen((snapshot) {
      final uids = snapshot.docs.map((doc) => doc.id).toList();
      _receivedLikeUids.assignAll(uids);
      _fetchProfilesForUiList(uids, usersWhoHaveLikedMe);
    }, onError: (e) => log('Error in received likes stream', name: 'ProfileController', error: e));
  }

  void _listenToMatches(String userId) {
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
      _matchedUids.assignAll(uids);
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
    _sentLikeUids.clear();
    _receivedLikeUids.clear();
    _matchedUids.clear();
    _favoriteUids.clear();
    _currentUserProfile.value = null;
    swipingProfileList.clear();
    usersWhoViewedMe.clear();
    usersWhoHaveLikedMe.clear();
    usersIHaveLiked.clear();
    usersIHaveFavourited.clear();
    likeStatusMap.clear();
    loadingStatus.value = ProfileLoadingStatus.loading;
  }

  void _cancelAllSubscriptions() {
    _swipingProfilesSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _sentLikesSubscription?.cancel();
    _receivedLikesSubscription?.cancel();
    _matchesSubscription?.cancel();
    _viewersSubscription?.cancel();
  }
}
