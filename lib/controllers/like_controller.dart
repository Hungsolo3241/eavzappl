import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/person.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class LikeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- PROPERTIES ---

  /// A flag to show a loading indicator on the like button.
  final RxBool isTogglingLike = false.obs;

  // --- REFACTORED STATE MANAGEMENT ---

  /// A unified cache that holds the final, calculated status for each user.
  /// The UI will react directly to changes in this map, ensuring consistency.
  final RxMap<String, LikeStatus> userStatuses = <String, LikeStatus>{}.obs;

  /// Private lists remain the source of truth, updated by Firestore streams.
  final RxList<String> _sentLikeUids = <String>[].obs;
  final RxList<String> _receivedLikeUids = <String>[].obs;
  final RxList<String> _matchedUids = <String>[].obs;

  /// Clears all state, including the new status cache.
  void clear() {
    _sentLikeUids.clear();
    _receivedLikeUids.clear();
    _matchedUids.clear();
    userStatuses.clear();
    Logger().d("LikeController cleared.");
  }

  // --- PUBLIC GETTERS / METHODS ---

  /// Determines the relationship status with another user.
  /// This is now a fast, synchronous lookup from the cache.
  LikeStatus getLikeStatus(String otherUserId) {
    return userStatuses[otherUserId] ?? LikeStatus.none;
  }

  /// The core logic for toggling a like. Called from the UI.
  Future<void> toggleLike(String targetUid) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || isTogglingLike.isTrue) return;

    isTogglingLike.value = true;
    final batch = _firestore.batch();
    final currentUserLikesSentRef = _firestore.collection('users').doc(currentUserId).collection('likesSent').doc(targetUid);
    final targetUserLikesReceivedRef = _firestore.collection('users').doc(targetUid).collection('likesReceived').doc(currentUserId);

    // Construct match document reference
    final ids = [currentUserId, targetUid]..sort();
    final matchId = ids.join('_');
    final matchRef = _firestore.collection('matches').doc(matchId);

    try {
      final bool isCurrentlyLiked = _sentLikeUids.contains(targetUid);

      if (isCurrentlyLiked) {
        // --- UNLIKE LOGIC ---
        batch.delete(currentUserLikesSentRef);
        batch.delete(targetUserLikesReceivedRef);
        batch.delete(matchRef); // Also remove the match document if it exists
      } else {
        // --- LIKE LOGIC ---
        final likeData = {'timestamp': FieldValue.serverTimestamp()};
        batch.set(currentUserLikesSentRef, likeData);
        batch.set(targetUserLikesReceivedRef, likeData);

        // If the other person has already liked us, it's a new match.
        if (_receivedLikeUids.contains(targetUid)) {
          batch.set(matchRef, {'users': ids, 'createdAt': FieldValue.serverTimestamp()});
        }
      }
      await batch.commit();
    } catch (e, s) {
      Logger().e(
        'Error toggling like',
        error: e,
        stackTrace: s,
      );
      Get.snackbar("Error", "Failed to update like status: ${e.toString()}");
    } finally {
      isTogglingLike.value = false;
    }
  }

  // --- STATE UPDATE & RECALCULATION ---

  /// Called by ProfileController to update the list of users the current user has liked.
  void updateSentLikes(List<String> uids) {
    _sentLikeUids.assignAll(uids);
    _recalculateStatuses();
  }

  /// Called by ProfileController to update the list of users who have liked the current user.
  void updateReceivedLikes(List<String> uids) {
    _receivedLikeUids.assignAll(uids);
    _recalculateStatuses();
  }

  /// Called by ProfileController to update the list of mutual matches.
  void updateMatches(List<String> uids) {
    _matchedUids.assignAll(uids);
    _recalculateStatuses();
  }

  /// Preloads and calculates statuses for a given list of user IDs.
  /// This is crucial for ensuring the UI has the correct data when new profiles are loaded.
  Future<void> preloadLikeStatuses(List<String> userIds) async {
    _recalculateStatuses(uidsToProcess: userIds);
    return Future.value();
  }

  /// Central calculation method that updates the unified status cache.
  /// This eliminates race conditions by calculating the final state in one go.
  void _recalculateStatuses({List<String>? uidsToProcess}) {
    // If no specific UIDs are provided, recalculate for all known UIDs.
    final allUids = uidsToProcess != null ? Set<String>.from(uidsToProcess) : {..._sentLikeUids, ..._receivedLikeUids, ..._matchedUids};

    for (final uid in allUids) {
      final bool iHaveLikedThem = _sentLikeUids.contains(uid);
      final bool theyHaveLikedMe = _receivedLikeUids.contains(uid);
      // BUG FIX: Correctly use the matches list as the primary source of truth for mutual likes.
      final bool isMatch = _matchedUids.contains(uid);

      if (isMatch || (iHaveLikedThem && theyHaveLikedMe)) {
        userStatuses[uid] = LikeStatus.mutualLike;
      } else if (iHaveLikedThem) {
        userStatuses[uid] = LikeStatus.liked;
      } else if (theyHaveLikedMe) {
        userStatuses[uid] = LikeStatus.likedBy;
      } else {
        // If a user is no longer in any list, ensure their status is reset.
        userStatuses[uid] = LikeStatus.none;
      }
    }
    // This triggers a single, efficient UI update.
    userStatuses.refresh();
  }
}
