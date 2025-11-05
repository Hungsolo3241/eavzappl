// lib/controllers/profile_controller.dart
// ENHANCED VERSION - Replace existing stream management logic

import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/filter_preferences.dart';
import 'package:eavzappl/models/person.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:eavzappl/controllers/like_controller.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ProfileLoadingStatus { initial, loading, done, error }

class ProfileController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- ENHANCED SUBSCRIPTION MANAGEMENT ---
  final Map<String, StreamSubscription> _subscriptionMap = {};
  Timer? _debounceTimer;
  bool _isDisposed = false;

  // --- STATE MANAGEMENT ---
  final Completer<void> _initCompleter = Completer<void>();
  late final Future<void> initialization;

  // --- DATA ---
  final RxList<Person> swipingProfiles = <Person>[].obs;
  final RxList<String> _favoriteUids = <String>[].obs;
  final Rx<Person?> _currentUserProfile = Rx<Person?>(null);

  // --- PUBLIC UI-FACING REACTIVE LISTS ---
  final RxList<Person> swipingProfileList = <Person>[].obs;
  final RxList<Person> usersWhoViewedMe = <Person>[].obs;
  final RxList<Person> usersWhoHaveLikedMe = <Person>[].obs;
  final RxList<Person> usersIHaveLiked = <Person>[].obs;
  final RxList<Person> usersIHaveFavourited = <Person>[].obs;

  // --- FILTERS ---
  final Rx<FilterPreferences> activeFilters = FilterPreferences.initial().obs;

  // --- LOADING STATE ---
  final Rx<ProfileLoadingStatus> loadingStatus = Rx(ProfileLoadingStatus.initial);
  final RxBool isTogglingFavorite = false.obs;

  // --- PUBLIC GETTERS ---
  String? get currentUserOrientation => _currentUserProfile.value?.orientation;
  bool isFavorite(String uid) => _favoriteUids.contains(uid);

  @override
  void onInit() {
    super.onInit();
    initialization = _initCompleter.future;
  }

  // ============================================================================
  // ENHANCED SUBSCRIPTION MANAGEMENT
  // ============================================================================

  /// Safely adds a subscription with automatic cleanup
  void _addSubscription(String key, StreamSubscription subscription) {
    if (_isDisposed) {
      subscription.cancel();
      return;
    }

    // Cancel existing subscription with same key
    _cancelSubscription(key);
    
    _subscriptionMap[key] = subscription;
    log('Added subscription: $key (total: ${_subscriptionMap.length})', 
        name: 'ProfileController');
  }

  /// Cancels a specific subscription by key
  void _cancelSubscription(String key) {
    final sub = _subscriptionMap.remove(key);
    if (sub != null) {
      sub.cancel();
      log('Cancelled subscription: $key', name: 'ProfileController');
    }
  }

  /// Cancels all subscriptions
  void _cancelAllSubscriptions() {
    log('Cancelling ${_subscriptionMap.length} subscriptions', 
        name: 'ProfileController');
    
    for (final entry in _subscriptionMap.entries) {
      entry.value.cancel();
      log('Cancelled: ${entry.key}', name: 'ProfileController');
    }
    _subscriptionMap.clear();
  }

  // ============================================================================
  // DEBOUNCED OPERATIONS
  // ============================================================================

  /// Debounced filter application to prevent rapid re-queries
  void applyFiltersDebounced(FilterPreferences newFilters) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      activeFilters.value = newFilters;
      fetchSwipingProfiles();
    });
  }

  // ============================================================================
  // STREAM LISTENERS WITH ENHANCED ERROR HANDLING
  // ============================================================================

  Future<void> initializeUserStreams(String userId) async {
    if (_isDisposed) return;

    loadingStatus.value = ProfileLoadingStatus.loading;
    await _loadFiltersFromPrefs();

    // Single user document listener with retry logic
    _listenToUserDocument(userId);
  }

  void _listenToUserDocument(String userId) {
    _addSubscription(
      'user_document',
      _firestore
          .collection("users")
          .doc(userId)
          .snapshots()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: (sink) {
              sink.addError(TimeoutException('User document stream timeout'));
            },
          )
          .listen(
            (userDoc) {
              if (_isDisposed) return;

              if (userDoc.exists) {
                final data = userDoc.data() as Map<String, dynamic>;
                data['uid'] = userDoc.id;
                final person = Person.fromJson(data);
                _currentUserProfile.value = person;

                // Initialize other streams only after user doc is loaded
                _initializeAllStreams(userId, person);

                if (!_initCompleter.isCompleted) {
                  _initCompleter.complete();
                }
              } else {
                log('User document for $userId not found yet', 
                    name: 'ProfileController');
                loadingStatus.value = ProfileLoadingStatus.done;
              }
            },
            onError: (error, stackTrace) {
              log('Error in user document stream',
                  name: 'ProfileController',
                  error: error,
                  stackTrace: stackTrace);
              
              if (!_initCompleter.isCompleted) {
                _initCompleter.completeError(error);
              }
              loadingStatus.value = ProfileLoadingStatus.error;
            },
            cancelOnError: false, // Keep stream alive after errors
          ),
    );
  }

  void _initializeAllStreams(String userId, Person currentUserProfile) {
    if (_isDisposed) return;

    final likeController = Get.find<LikeController>();

    _listenToSwipingProfiles(userId, currentUserProfile, likeController);
    _listenToFavorites(userId);
    _listenToLikes(userId, likeController);
    _listenToMatches(userId, likeController);
    _listenToViewers(userId);
  }

  void _listenToSwipingProfiles(
    String userId,
    Person currentUserProfile,
    LikeController likeController,
  ) {
    if (_isDisposed) return;

    Query query = _firestore
        .collection('users')
        .where("uid", isNotEqualTo: userId);

    final String? orientation = currentUserProfile.orientation?.toLowerCase().trim();
    String? targetOrientation;

    if (orientation == 'adam') {
      targetOrientation = 'eve';
    } else if (orientation == 'eve') {
      targetOrientation = 'adam';
    }




    if (targetOrientation != null) {
      query = query.where("orientation", isEqualTo: targetOrientation);
    } else {
      log('No target orientation found for $userId', name: 'ProfileController');
      return;
    }

    // Apply filters
    final filters = activeFilters.value;

    if (filters.ageRange != null) {
      query = query
          .where('age', isGreaterThanOrEqualTo: filters.ageRange!.start.round())
          .where('age', isLessThanOrEqualTo: filters.ageRange!.end.round());
    }

    // Add ordering for consistent results and to support range filters
    query = query.orderBy('age').orderBy('uid');

    if (filters.gender != null && filters.gender != 'Any') {
      query = query.where('gender', isEqualTo: filters.gender);
    }
    if (filters.ethnicity != null && filters.ethnicity != 'Any') {
      query = query.where('ethnicity', isEqualTo: filters.ethnicity);
    }
    if (filters.relationshipStatus != null && filters.relationshipStatus != 'Any') {
      query = query.where('relationshipStatus', isEqualTo: filters.relationshipStatus);
    }
    if (filters.country != null && filters.country!.isNotEmpty) {
      query = query.where('country', isEqualTo: filters.country);
    }
    if (filters.province != null && filters.province!.isNotEmpty) {
      query = query.where('province', isEqualTo: filters.province);
    }
    if (filters.city != null && filters.city!.isNotEmpty) {
      query = query.where('city', isEqualTo: filters.city);
    }
    if (filters.wantsHost == true) {
      query = query.where('hostSelection', isEqualTo: true);
    }
    if (filters.wantsTravel == true) {
      query = query.where('travelSelection', isEqualTo: true);
    }
    if (filters.profession != null && filters.profession != 'Any') {
      if (filters.profession == 'Professional') {
        query = query.where('profession', whereNotIn: ['Student', 'Freelancer']);
      } else {
        query = query.where('profession', isEqualTo: filters.profession);
      }
    }

    // Add pagination (CRITICAL IMPROVEMENT)
    query = query.limit(50); // Load 50 profiles at a time

    _addSubscription(
      'swiping_profiles',
      query.snapshots().listen(
        (snapshot) async {
          if (_isDisposed) return;

          var profiles = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['uid'] = doc.id;
            return Person.fromJson(data);
          }).toList();


          final userIds = profiles.map((p) => p.uid!).toList();
          if (userIds.isNotEmpty) {
            await likeController.preloadLikeStatuses(userIds);
          }

          swipingProfileList.assignAll(profiles);

          if (loadingStatus.value != ProfileLoadingStatus.done) {
            loadingStatus.value = ProfileLoadingStatus.done;
          }
        },
        onError: (error, stackTrace) {
          log('Error in swiping profiles stream',
              name: 'ProfileController',
              error: error,
              stackTrace: stackTrace);
          loadingStatus.value = ProfileLoadingStatus.error;
        },
        cancelOnError: false,
      ),
    );
  }

  void _listenToFavorites(String userId) {
    if (_isDisposed) return;

    _addSubscription(
      'favorites',
      _firestore
          .collection("users")
          .doc(userId)
          .collection("userFavorites")
          .snapshots()
          .listen(
            (snapshot) {
              if (_isDisposed) return;
              final uids = snapshot.docs.map((doc) => doc.id).toList();
              _favoriteUids.assignAll(uids);
              _fetchProfilesForUiList(uids, usersIHaveFavourited);
            },
            onError: (error) => log('Error in favorites stream',
                name: 'ProfileController', error: error),
            cancelOnError: false,
          ),
    );
  }

  void _listenToLikes(String userId, LikeController likeController) {
    if (_isDisposed) return;

    _addSubscription(
      'sent_likes',
      _firestore
          .collection('users')
          .doc(userId)
          .collection('likesSent')
          .snapshots()
          .listen(
            (snapshot) {
              if (_isDisposed) return;
              final uids = snapshot.docs.map((doc) => doc.id).toList();
              likeController.updateSentLikes(uids);
              _fetchProfilesForUiList(uids, usersIHaveLiked);
            },
            onError: (error) => log('Error in sent likes stream',
                name: 'ProfileController', error: error),
            cancelOnError: false,
          ),
    );

    _addSubscription(
      'received_likes',
      _firestore
          .collection('users')
          .doc(userId)
          .collection('likesReceived')
          .snapshots()
          .listen(
            (snapshot) {
              if (_isDisposed) return;
              final uids = snapshot.docs.map((doc) => doc.id).toList();
              likeController.updateReceivedLikes(uids);
              _fetchProfilesForUiList(uids, usersWhoHaveLikedMe);
            },
            onError: (error) => log('Error in received likes stream',
                name: 'ProfileController', error: error),
            cancelOnError: false,
          ),
    );
  }

  void _listenToMatches(String userId, LikeController likeController) {
    if (_isDisposed) return;

    _addSubscription(
      'matches',
      _firestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .snapshots()
          .listen(
            (snapshot) {
              if (_isDisposed) return;
              final uids = <String>{};
              for (final doc in snapshot.docs) {
                final List<dynamic> users = doc.data()['users'] ?? [];
                final otherUser = users.firstWhere(
                  (uid) => uid != userId,
                  orElse: () => null,
                );
                if (otherUser != null) {
                  uids.add(otherUser);
                }
              }
              likeController.updateMatches(uids.toList());
            },
            onError: (error) => log('Error in matches stream',
                name: 'ProfileController', error: error),
            cancelOnError: false,
          ),
    );
  }

  void _listenToViewers(String userId) {
    if (_isDisposed) return;

    _addSubscription(
      'viewers',
      _firestore
          .collection('users')
          .doc(userId)
          .collection('profileViewLog')
          .orderBy('lastViewed', descending: true)
          .limit(50)
          .snapshots()
          .listen(
            (snapshot) {
              if (_isDisposed) return;
              final uids = snapshot.docs.map((doc) => doc.id).toList();
              _fetchProfilesForUiList(uids, usersWhoViewedMe);
            },
            onError: (error) => log('Error in viewers stream',
                name: 'ProfileController', error: error),
            cancelOnError: false,
          ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<void> refreshSwipingProfiles() async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    log('Pull-to-refresh triggered.', name: 'ProfileController');
    await fetchSwipingProfiles();
  }

  Future<void> fetchSwipingProfiles() async {
    if (_isDisposed) return;

    final currentUserId = _auth.currentUser?.uid;
    final currentUserProfile = _currentUserProfile.value;

    if (currentUserId != null && currentUserProfile != null) {
      log("Fetching swiping profiles with new filters...", name: "ProfileController");
      final LikeController likeController = Get.find();
      _listenToSwipingProfiles(currentUserId, currentUserProfile, likeController);
    } else {
      swipingProfileList.clear();
      loadingStatus.value = ProfileLoadingStatus.done;
    }
  }

  Future<void> _fetchProfilesForUiList(List<String> uids, RxList<Person> uiList) async {
    if (_isDisposed) return;

    if (uids.isEmpty) {
      uiList.clear();
      return;
    }

    try {
      // Firestore has a limit of 10 items for 'whereIn' queries
      final batches = <Future<QuerySnapshot>>[];
      for (var i = 0; i < uids.length; i += 10) {
        final batchUids = uids.skip(i).take(10).toList();
        batches.add(
          _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batchUids)
              .get(),
        );
      }

      final results = await Future.wait(batches);
      final profiles = results
          .expand((snapshot) => snapshot.docs)
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['uid'] = doc.id;
            return Person.fromJson(data);
          })
          .toList();

      uiList.assignAll(profiles);
    } catch (e) {
      log('Error fetching profiles for UI list', name: 'ProfileController', error: e);
    }
  }

  Future<void> _loadFiltersFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? filtersJsonString = prefs.getString('user_filters');
      if (filtersJsonString != null) {
        final Map<String, dynamic> filtersMap = json.decode(filtersJsonString);
        activeFilters.value = FilterPreferences.fromJson(filtersMap);
        log('Filters loaded from local storage.', name: 'ProfileController');
      } else {
        activeFilters.value = FilterPreferences.initial();
      }
    } catch (e) {
      log('Failed to load filters', name: 'ProfileController', error: e);
      activeFilters.value = FilterPreferences.initial();
    }
  }

  Future<void> toggleFavoriteStatus(String targetUid) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || _isDisposed) return;

    isTogglingFavorite.value = true;
    final docRef = _firestore
        .collection("users")
        .doc(currentUserId)
        .collection("userFavorites")
        .doc(targetUid);

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
    if (currentUserId == null || currentUserId == viewedUserId || _isDisposed) return;

    try {
      await _firestore
          .collection("users")
          .doc(viewedUserId)
          .collection("profileViewLog")
          .doc(currentUserId)
          .set({'lastViewed': FieldValue.serverTimestamp()});
    } catch (e, s) {
      log('Error recording profile view for $viewedUserId',
          name: 'ProfileController',
          error: e,
          stackTrace: s);
    }
  }

  void clearAllSubscriptions() {
    log('Clearing all user state and cancelling streams due to logout.',
        name: 'ProfileController');

    _cancelAllSubscriptions();
    _debounceTimer?.cancel();

    _currentUserProfile.value = null;
    swipingProfiles.clear();
    _favoriteUids.clear();
    swipingProfileList.clear();
    usersWhoViewedMe.clear();
    usersWhoHaveLikedMe.clear();
    usersIHaveLiked.clear();
    usersIHaveFavourited.clear();
    activeFilters.value = FilterPreferences.initial();
    loadingStatus.value = ProfileLoadingStatus.initial;

    if (Get.isRegistered<LikeController>()) {
      Get.find<LikeController>().clear();
    }
  }

  @override
  void onClose() {
    log('ProfileController onClose called. Disposing all subscriptions.',
        name: 'ProfileController');
    
    _isDisposed = true;
    _cancelAllSubscriptions();
    _debounceTimer?.cancel();
    
    super.onClose();
  }

  Future<void> forceReload() async {
    await refreshSwipingProfiles();
  }
}