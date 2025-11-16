// lib/controllers/like_controller.dart

import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/person.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class LikeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isTogglingLike = false.obs;

  final RxList<String> _sentLikeUids = <String>[].obs;
  final RxList<String> _receivedLikeUids = <String>[].obs;
  final RxList<String> _matchedUids = <String>[].obs;
  
  // ✅ ADD: Track initialization state
  final RxBool isInitialized = false.obs;

  void clear() {
    _sentLikeUids.clear();
    _receivedLikeUids.clear();
    _matchedUids.clear();
    isInitialized.value = false;
  }

  // ✅ NEW: Synchronously load initial like data
  Future<void> initializeLikeData(String userId) async {
    try {
      Logger().i('Initializing like data for user: $userId');
      
      // Load all three collections in parallel
      final results = await Future.wait([
        _firestore.collection('users').doc(userId).collection('likesSent').get(),
        _firestore.collection('users').doc(userId).collection('likesReceived').get(),
        _firestore.collection('matches').where('users', arrayContains: userId).get(),
      ]);

      // Update sent likes
      _sentLikeUids.value = results[0].docs.map((doc) => doc.id).toList();
      
      // Update received likes
      _receivedLikeUids.value = results[1].docs.map((doc) => doc.id).toList();
      
      // Update matches
      final matchedUids = <String>{};
      for (final doc in results[2].docs) {
        final List<dynamic> users = doc.data()['users'] ?? [];
        final otherUser = users.firstWhere(
          (uid) => uid != userId,
          orElse: () => null,
        );
        if (otherUser != null) {
          matchedUids.add(otherUser);
        }
      }
      _matchedUids.value = matchedUids.toList();
      
      isInitialized.value = true;
      
      Logger().i('Like data initialized: ${_sentLikeUids.length} sent, ${_receivedLikeUids.length} received, ${_matchedUids.length} matches');
      
    } catch (e, s) {
      Logger().e('Error initializing like data', error: e, stackTrace: s);
      // Even on error, mark as initialized to unblock UI
      isInitialized.value = true;
    }
  }

  LikeStatus getLikeStatus(String otherUserId) {
    // ✅ IMPORTANT: Return accurate status even before streams update
    final bool iHaveLikedThem = _sentLikeUids.contains(otherUserId);
    final bool theyHaveLikedMe = _receivedLikeUids.contains(otherUserId);

    if (iHaveLikedThem && theyHaveLikedMe) {
      return LikeStatus.mutualLike;
    } else if (iHaveLikedThem) {
      return LikeStatus.liked;
    } else if (theyHaveLikedMe) {
      return LikeStatus.likedBy;
    } else {
      return LikeStatus.none;
    }
  }

  Future<void> preloadLikeStatuses(List<String> userIds) async {
    // This method is now just a placeholder since we load everything upfront
    return Future.value();
  }

  Future<void> toggleLike(String targetUid) async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || isTogglingLike.isTrue) return;

    isTogglingLike.value = true;
    final batch = _firestore.batch();
    final currentUserLikesSentRef = _firestore.collection('users').doc(currentUserId).collection('likesSent').doc(targetUid);
    final targetUserLikesReceivedRef = _firestore.collection('users').doc(targetUid).collection('likesReceived').doc(currentUserId);

    final ids = [currentUserId, targetUid]..sort();
    final matchId = ids.join('_');
    final matchRef = _firestore.collection('matches').doc(matchId);

    try {
      final bool isCurrentlyLiked = _sentLikeUids.contains(targetUid);

      if (isCurrentlyLiked) {
        // ✅ OPTIMISTIC UPDATE: Update local state immediately
        _sentLikeUids.remove(targetUid);
        if (_matchedUids.contains(targetUid)) {
          _matchedUids.remove(targetUid);
        }
        
        batch.delete(currentUserLikesSentRef);
        batch.delete(targetUserLikesReceivedRef);
        batch.delete(matchRef);
      } else {
        // ✅ OPTIMISTIC UPDATE: Update local state immediately
        _sentLikeUids.add(targetUid);
        
        final likeData = {'timestamp': FieldValue.serverTimestamp()};
        batch.set(currentUserLikesSentRef, likeData);
        batch.set(targetUserLikesReceivedRef, likeData);

        if (_receivedLikeUids.contains(targetUid)) {
          _matchedUids.add(targetUid);
          batch.set(matchRef, {'users': ids, 'createdAt': FieldValue.serverTimestamp()});
        }
      }
      
      // ✅ Force UI update by reassigning lists
      _sentLikeUids.refresh();
      _matchedUids.refresh();
      
      await batch.commit();
    } catch (e, s) {
      Logger().e('Error toggling like', error: e, stackTrace: s);
      Get.snackbar("Error", "Failed to update like status: ${e.toString()}");
    } finally {
      isTogglingLike.value = false;
    }
  }

  void updateSentLikes(List<String> uids) {
    _sentLikeUids.assignAll(uids);
  }

  void updateReceivedLikes(List<String> uids) {
    _receivedLikeUids.assignAll(uids);
  }

  void updateMatches(List<String> uids) {
    _matchedUids.assignAll(uids);
  }
}
