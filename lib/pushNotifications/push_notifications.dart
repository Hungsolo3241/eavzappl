import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart';
import 'package:get/get.dart';
import 'dart:developer';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotifications {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize(BuildContext context) async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await _getAndSaveFCMToken();
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(context, message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTapNavigation(message.data);
    });

    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTapNavigation(initialMessage.data);
    }
  }

  Future<void> _getAndSaveFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set(
        {'fcmToken': token, 'lastTokenUpdate': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      log("PushNotifications: Error saving FCM token to Firestore: $e");
    }
  }

  Future<Map<String, dynamic>> _getNotificationPreferences(String userId) async {
    try {
      DocumentSnapshot settingsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notification_settings')
          .get();

      if (settingsDoc.exists && settingsDoc.data() != null) {
        return settingsDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      log("PushNotifications: Error fetching notification settings: $e");
    }
    return {};
  }

  bool _shouldShowNotification(String? type, Map<String, dynamic> prefs) {
    if (!(prefs['receiveAllNotifications'] ?? true)) return false;

    switch (type) {
      case 'profile_view':
        return prefs['profileViewNotifications'] ?? true;
      case 'new_like':
        return prefs['newLikeNotifications'] ?? true;
      case 'mutual_match':
        return prefs['mutualMatchNotifications'] ?? true;
      default:
        return true;
    }
  }

  Future<void> _showForegroundNotification(BuildContext context, RemoteMessage message) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userPreferences = await _getNotificationPreferences(userId);
    final String? type = message.data['type'] as String?;

    if (!_shouldShowNotification(type, userPreferences)) return;

    final data = message.data;
    final String? navigateToUserId = data['relatedItemId'] as String?;

    if (!context.mounted) return;

    if (navigateToUserId == null || navigateToUserId.isEmpty) {
      _showGenericDialog(context, message.notification);
    } else {
      _showCustomDialog(context, data);
    }
  }

  void _showGenericDialog(BuildContext context, RemoteNotification? notification) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(notification?.title ?? "Notification"),
          content: SingleChildScrollView(child: Text(notification?.body ?? "")),
          actions: [
            TextButton(
              child: const Text("Dismiss"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showCustomDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return NotificationDialogBox(
          profilePhoto: data['senderPhotoUrl'] as String? ?? "",
          name: data['senderName'] as String? ?? "New Notification",
          navigateToUserId: data['relatedItemId'] as String,
          age: data['senderAge'] as String? ?? "",
          city: data['senderCity'] as String? ?? "",
          profession: data['senderProfession'] as String? ?? "",
        );
      },
    );
  }

  void _handleNotificationTapNavigation(Map<String, dynamic> data) {
    final String? type = data['type'] as String?;
    final String? relatedItemId = data['relatedItemId'] as String?;

    if (relatedItemId == null || relatedItemId.isEmpty) return;

    if (type == 'profile_view' || type == 'new_like' || type == 'mutual_match') {
      Get.to(() => UserDetailsScreen(userID: relatedItemId));
    }
  }
}

class NotificationDialogBox extends StatelessWidget {
  final String profilePhoto;
  final String name;
  final String navigateToUserId;
  final String age;
  final String city;
  final String profession;

  const NotificationDialogBox({
    Key? key,
    required this.profilePhoto,
    required this.name,
    required this.navigateToUserId,
    required this.age,
    required this.city,
    required this.profession,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Notification from $name'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 30,
              backgroundImage: profilePhoto.isNotEmpty ? NetworkImage(profilePhoto) : null,
              onBackgroundImageError: profilePhoto.isNotEmpty ? (exception, stackTrace) {
                log('Error loading profile image: $exception');
              } : null,
              child: profilePhoto.isEmpty ? const Icon(Icons.person) : null,
            ),
          ),
          const SizedBox(height: 16),
          Text('Name: $name'),
          const SizedBox(height: 4),
          if (age.isNotEmpty) Text('Age: $age'),
          if (city.isNotEmpty) Text('City: $city'),
          if (profession.isNotEmpty) Text('Profession: $profession'),
        ],
      ),
      actions: [
        TextButton(
          child: const Text("View"),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            Get.to(() => UserDetailsScreen(userID: navigateToUserId));
          },
        ),
        TextButton(
          child: const Text("Dismiss"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
