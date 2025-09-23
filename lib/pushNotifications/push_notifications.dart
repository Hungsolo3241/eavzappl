import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  print("Background message data: ${message.data}");
}

class PushNotifications {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize(BuildContext context) async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM Token & Save/Update it
    await _getAndSaveFCMToken();
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print("PushNotifications: FCM Token Refreshed: $newToken");
      _saveTokenToDatabase(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('PushNotifications: Got a message whilst in the foreground!');
      print('PushNotifications: Message data: ${message.data}');
      if (message.notification != null) {
        print('PushNotifications: Message also contained a notification: ${message.notification}');
      }
      showForegroundNotificationDialog(context, message);
    });

    // Handle notification tap when app is open or in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('PushNotifications: Message opened app from background: ${message.data}');
      _handleNotificationTapNavigation(message.data, context);
    });

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('PushNotifications: Message opened app from terminated state: ${initialMessage.data}');
      // Pass null for context if you don't have one readily available here
      // or ensure your navigation doesn't strictly depend on it for this case.
      _handleNotificationTapNavigation(initialMessage.data, null);
    }
  }

  Future<void> _getAndSaveFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("PushNotifications: FCM Token: $token");
      await _saveTokenToDatabase(token);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("PushNotifications: User not logged in. Cannot save FCM token.");
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {'fcmToken': token, 'lastTokenUpdate': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      print("PushNotifications: FCM token saved to Firestore for user $userId");
    } catch (e) {
      print("PushNotifications: Error saving FCM token to Firestore: $e");
    }
  }

  Future<void> showForegroundNotificationDialog(BuildContext context, RemoteMessage message) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("PushNotifications: User not logged in, cannot check notification settings. Dialog will not be shown by default.");
      return;
    }

    Map<String, dynamic> userPreferences = {};

    try {
      DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notification_settings')
          .get();

      if (settingsDoc.exists && settingsDoc.data() != null) {
        userPreferences = settingsDoc.data() as Map<String, dynamic>;
        print("PushNotifications: Notification settings found for user $userId. Applying them.");
      } else {
        print("PushNotifications: Notification settings not found for user $userId. All notifications will be allowed by default for this message.");
      }
    } catch (e) {
      print("PushNotifications: Error fetching/checking notification settings: $e. All notifications will be allowed by default for this message as a fallback.");
    }

    // Check master switch using userPreferences
    if (!(userPreferences['receiveAllNotifications'] ?? true)) {
      print("PushNotifications: 'receiveAllNotifications' is off. Dialog will not be shown.");
      return;
    }

    // THIS IS THE ORIGINAL 'message.data' ACCESS, NOW CORRECTLY PLACED
    final Map<String, dynamic> data = message.data;
    String? type = data['type'] as String?;
    bool specificTypeEnabled = true;

    switch (type) {
      case 'profile_view':
        specificTypeEnabled = userPreferences['profileViewNotifications'] ?? true;
        break;
      case 'new_like':
        specificTypeEnabled = userPreferences['newLikeNotifications'] ?? true;
        break;
      case 'mutual_match':
        specificTypeEnabled = userPreferences['newMatchNotifications'] ?? true;
        break;
    }

    if (!specificTypeEnabled) {
      print("PushNotifications: Notifications for type '$type' are off ('${_getSettingKeyForType(type)}'). Dialog will not be shown.");
      return;
    }

    // THE REST OF THE DIALOG DISPLAY LOGIC, NOW CORRECTLY INSIDE THE METHOD

    String dialogTitle = message.notification?.title ?? "New Notification";
    String dialogBody = message.notification?.body ?? "You have a new message.";
    // 'type' is already defined above from message.data, can reuse 'notificationType' if preferred
    // String? notificationType = data['type'] as String?;

    if (type == 'profile_view') { // Using 'type' directly
      dialogTitle = data['viewingUserName'] != null ? "${data['viewingUserName']} viewed your profile!" : "Profile View";
    } else if (type == 'new_like') {
      dialogTitle = data['likingUserName'] != null ? "${data['likingUserName']} likes you!" : "New Like";
    } else if (type == 'mutual_match') {
      dialogTitle = "It's a Match!";
    }

    if (context.mounted) { // 'mounted' is a property of State objects, ensure context is from a mounted widget
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(dialogTitle),
            content: SingleChildScrollView(child: Text(dialogBody)),
            actions: [
              TextButton(
                child: const Text("Dismiss"),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              TextButton(
                child: const Text("View"),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _handleNotificationTapNavigation(data, dialogContext);
                },
              ),
            ],
          );
        },
      );
    } else {
      print("PushNotifications: Context not mounted, cannot show dialog for foreground message.");
    }
  } // <<< ENSURE THIS IS THE CORRECT CLOSING BRACE FOR THE METHOD


  String _getSettingKeyForType(String? type) {
    switch (type) {
      case 'profile_view': return 'profileViewNotifications';
      case 'new_like': return 'newLikeNotifications';
      case 'mutual_match': return 'newMatchNotifications';
      default: return 'unknown_type';
    }
  }

  void _handleNotificationTapNavigation(Map<String, dynamic> data, BuildContext? context) {
    print("PushNotifications: Handling tap navigation for data: $data with context: $context");
    // Example:
    // String? type = data['type'] as String?;
    // String? relatedItemId = data['relatedItemId'] as String?;
    // if (context != null && type == 'profile_view' && relatedItemId != null) {
    //   Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen(userId: relatedItemId)));
    // } else if (Get.isRegistered<>() && type == 'profile_view' && relatedItemId != null) { // If using GetX and context might be null
    //    Get.to(() => UserProfileScreen(userId: relatedItemId));
    // }
    // Add your navigation logic here
  }
}


// TODO: Define your NotificationDialogBox widget (example structure)
// class NotificationDialogBox extends StatelessWidget {
//   final String profilePhoto;
//   final String name;
//   // ... other fields like age, city, profession from your original commented code
//
//   const NotificationDialogBox({
//     Key? key,
//     required this.profilePhoto,
//     required this.name,
//     // ...
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text('New Notification from $name'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Image.network(profilePhoto), // Handle errors for network image
//           Text('Name: $name'),
//           // ... display other details
//         ],
//       ),
//       actions: [
//         TextButton(
//           child: const Text("View"),
//           onPressed: () {
//             // TODO: Navigate to user's profile or relevant screen
//             Navigator.of(context).pop();
//           },
//         ),
//         TextButton(
//           child: const Text("Dismiss"),
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//         ),
//       ],
//     );
//   }
// }
