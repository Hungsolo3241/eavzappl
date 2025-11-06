// lib/pushNotifications/push_notifications.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart';
import 'package:get/get.dart';
import 'dart:developer';

import 'package:eavzappl/models/push_notification_payload.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:eavzappl/utils/app_theme.dart';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotifications {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize(BuildContext context) async {
    NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // If permission is denied, show a dialog to the user
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.5),
          title: const Text('Notification Permission'),
          content: const Text('Please enable notifications to receive updates.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      // If permission is not determined, request it
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

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
    // ... (This section remains unchanged)
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      log("<<<<< FCM TOKEN: $token >>>>>", name: "PushNotifications");
      await _saveTokenToDatabase(token);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    // ... (This section remains unchanged)
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
    // ... (This section remains unchanged)
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
    // ... (This section remains unchanged)
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

  // --- REFACTORED to use the model ---
  Future<void> _showForegroundNotification(BuildContext context, RemoteMessage message) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userPreferences = await _getNotificationPreferences(userId);
    // Create a payload object from the data map for type-safety
    final payload = PushNotificationPayload.fromMap(message.data);

    if (!_shouldShowNotification(payload.type, userPreferences)) return;

    if (!context.mounted) return;

    // Use the payload to make decisions
    if (payload.relatedItemId == null || payload.relatedItemId!.isEmpty) {
      _showGenericDialog(context, message.notification);
    } else {
      _showCustomDialog(context, payload); // Pass the strongly-typed object
    }
  }

  void _showGenericDialog(BuildContext context, RemoteNotification? notification) {
    // ... (This section remains unchanged)
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.5),
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

  // --- REFACTORED to accept the model ---
  static void _showCustomDialog(BuildContext context, PushNotificationPayload payload) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Pass the safe, typed data from the payload to the dialog
        return NotificationDialogBox(
          profilePhoto: payload.senderPhotoUrl ?? "",
          name: payload.senderName ?? "Someone",
          navigateToUserId: payload.relatedItemId!, // We know it's not null here
          age: payload.senderAge ?? "",
          city: payload.senderCity ?? "",
          profession: payload.senderProfession ?? "",
        );
      },
    );
  }

  // --- REFACTORED to use the model ---
  static void _handleNotificationTapNavigation(Map<String, dynamic> data) {
    // Create a payload object for type-safety
    final payload = PushNotificationPayload.fromMap(data);

    if (payload.relatedItemId == null || payload.relatedItemId!.isEmpty) return;

    // Check the type from the payload
    if (['profile_view', 'new_like', 'mutual_match'].contains(payload.type)) {
      Get.to(() => UserDetailsScreen(userID: payload.relatedItemId!));
    }
  }

  static void showTestForegroundNotification(BuildContext context, PushNotificationPayload payload) {
    // This uses the exact same logic as your real foreground handler
    _showCustomDialog(context, payload);
  }
}

// --- FULLY REFACTORED NotificationDialogBox ---
class NotificationDialogBox extends StatelessWidget {
  final String profilePhoto;
  final String name;
  final String navigateToUserId;
  final String age;
  final String city;
  final String profession;

  // Added a const constructor for performance
  const NotificationDialogBox({
    super.key, // Use super.key
    required this.profilePhoto,
    required this.name,
    required this.navigateToUserId,
    required this.age,
    required this.city,
    required this.profession,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.5),
      title: Text(
        'New from $name',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Replaced NetworkImage with a robust CachedNetworkImage
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: profilePhoto,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              memCacheHeight: 160, // Performance optimization
              placeholder: (context, url) => Container(color: Colors.grey[800]),
              errorWidget: (context, url, error) => Container(
                height: 80,
                width: 80,
                color: Colors.grey[800],
                child: Icon(Icons.person, color: Colors.blueGrey[200], size: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Improved text styling for dark mode
          if (age.isNotEmpty) Text('Age: $age', style: const TextStyle(color: Colors.white70)),
          if (city.isNotEmpty) Text('City: $city', style: const TextStyle(color: Colors.white70)),
          if (profession.isNotEmpty) Text('Profession: $profession', style: const TextStyle(color: Colors.white70)),
        ],
      ),
      actions: [
        TextButton(
          child: Text("View Profile", style: TextStyle(color: AppTheme.primaryYellow)),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            Get.to(() => UserDetailsScreen(userID: navigateToUserId));
          },
        ),
        TextButton(
          child: Text("Dismiss", style: TextStyle(color: Colors.blueGrey[200])),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}