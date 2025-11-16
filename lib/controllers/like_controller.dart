import 'package:logger/logger.dart'; // CORRECTED IMPORT
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

  /// Private reactive lists that hold the source of truth for all like/match data.
  /// These are updated by the ProfileController's Firestore streams.
  final RxList<String> _sentLikeUids = <String>[].obs;
  final RxList<String> _receivedLikeUids = <String>[].obs;
  final RxList<String> _matchedUids = <String>[].obs;

  void clear() {
    _sentLikeUids.clear();
    _receivedLikeUids.clear();
    _matchedUids.clear();
  }

  // --- PUBLIC GETTERS / METHODS ---

  /// Determines the relationship status with another user.
  /// This is the main method the UI will call.
  LikeStatus getLikeStatus(String otherUserId) {
    final bool iHaveLikedThem = _sentLikeUids.contains(otherUserId);
    final bool theyHaveLikedMe = _receivedLikeUids.contains(otherUserId);

    if (iHaveLikedThem && theyHaveLikedMe) {
      return LikeStatus.mutualLike;
    } else if (iHaveLikedThem) {
      // I have liked them, but they haven't liked me back.
      return LikeStatus.liked;
    } else if (theyHaveLikedMe) {
      // They have liked me, but I haven't liked them back.
      return LikeStatus.likedBy; // <-- THE FIX
    } else {
      // Neither of us has liked the other.
      return LikeStatus.none;
    }
  }


  Future<void> preloadLikeStatuses(List<String> userIds) async {
    // This is a placeholder for a more complex preloading/caching strategy if needed.
    // For now, our reactive lists (_sentLikeUids, _receivedLikeUids) are the source of truth,
    // so this method doesn't need to do anything. Its existence is enough to
    // satisfy the call from ProfileController. In a future, more complex app,
    // this could be used to bulk-fetch data.
    return Future.value();
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
      // CORRECTED LOGGING
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

  // --- STATE UPDATE METHODS (Called by ProfileController) ---

  /// Called by ProfileController to update the reactive list of users the current user has liked.
  void updateSentLikes(List<String> uids) {
    _sentLikeUids.assignAll(uids);
  }

  /// Called by ProfileController to update the reactive list of users who have liked the current user.
  void updateReceivedLikes(List<String> uids) {
    _receivedLikeUids.assignAll(uids);
  }

  /// Called by ProfileController to update the reactive list of mutual matches.
  void updateMatches(List<String> uids) {
    _matchedUids.assignAll(uids);
  }
}
