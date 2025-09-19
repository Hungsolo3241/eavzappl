import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Assuming you use Firebase Auth
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// IMPORTANT: The true background handler must be a top-level function,
// usually in your main.dart file, and registered with
// FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
// before runApp().
/*
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase is initialized here too
  print("Handling a background message: ${message.messageId}");
  print("Background message data: ${message.data}");
  // If you want to show a local notification for background messages (not when app is terminated)
  // you might need a local notification plugin here too.
}
*/

class PushNotifications {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // Use a GlobalKey<NavigatorState> if you need to navigate from places
  // where BuildContext is not readily available (like from initialMessage handler).
  // You would assign this key to your MaterialApp's navigatorKey.
  // static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize(BuildContext context) async {
    // 1. Request Permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('PushNotifications: User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('PushNotifications: User granted provisional permission');
    } else {
      print('PushNotifications: User declined or has not accepted permission');
    }

    // 2. Get FCM Token & Save/Update it
    await _getAndSaveFCMToken();
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print("PushNotifications: FCM Token Refreshed: $newToken");
      _saveTokenToDatabase(newToken);
    });

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('PushNotifications: Got a message whilst in the foreground!');
      print('PushNotifications: Message data: ${message.data}');

      if (message.notification != null) {
        print('PushNotifications: Message also contained a notification: ${message.notification}');
        // For foreground messages, show a custom in-app dialog/notification
        // You can make this dialog actionable, potentially calling _handleNotificationTapNavigation
        // if the user interacts with your custom in-app notification.
        showForegroundNotificationDialog(context, message);
      }
    });

    // 4. Handle Background Messages (when the user taps on the notification and app opens)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('PushNotifications: Message clicked and opened app from background!');
      print('PushNotifications: Message data: ${message.data}');
      _handleNotificationTapNavigation(message.data, context);
    });

    // 5. Handle Terminated Messages (app opened from a terminated state by tapping the notification)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('PushNotifications: App opened from terminated state by a notification!');
      print('PushNotifications: Initial Message data: ${initialMessage.data}');
      // For terminated state, context might not be directly available.
      // You might need to pass data to your initial route or use a GlobalKey<NavigatorState>.
      // For simplicity here, we'll try to use the passed context if available,
      // but a more robust solution might involve a global navigator key or a different strategy.
      _handleNotificationTapNavigation(initialMessage.data, context);
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
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .set({
          'fcmTokens': FieldValue.arrayUnion([token])
        }, SetOptions(merge: true));
        print("PushNotifications: FCM token saved for user $currentUserId");
      } catch (error) {
        print("PushNotifications: Failed to save FCM token: $error");
      }
    } else {
      print("PushNotifications: User not logged in, cannot save FCM token.");
    }
  }

  void _handleNotificationTapNavigation(Map<String, dynamic> data, BuildContext? context) {
    print("PushNotifications: Navigating with data: $data");
    final String? type = data['type'] as String?;

    // Ensure context is available and mounted if we plan to navigate.
    // If using a GlobalKey: final currentContext = navigatorKey.currentContext;
    final currentContext = context; // Using the context passed to initialize for now.

    if (currentContext == null || !currentContext.mounted) {
      print("PushNotifications: Navigation context not available or not mounted.");
      // Handle navigation when context is not available (e.g., for terminated state)
      // This might involve setting some global state or passing initial route params
      // to be picked up by your app's initial routing logic.
      // For example, you could store `data` in a global variable or a stream that
      // your main app widget listens to.
      return;
    }

    if (type == 'profile_view') {
      final String? viewingUserId = data['viewingUserId'] as String?;
      final String? viewingUserName = data['viewingUserName'] as String?;
      if (viewingUserId != null) {
        print("PushNotifications: Navigating to profile of $viewingUserName ($viewingUserId)");
        // TODO: Implement navigation to the profile screen
        // Example: Navigator.of(currentContext).pushNamed('/profile', arguments: viewingUserId);
      }
    } else if (type == 'new_like') {
      final String? likingUserId = data['likingUserId'] as String?;
      final String? likingUserName = data['likingUserName'] as String?;
      if (likingUserId != null) {
        print("PushNotifications: Navigating to profile of liker $likingUserName ($likingUserId)");
        // TODO: Implement navigation to the liker's profile screen or a "likes you" screen
        // Example: Navigator.of(currentContext).pushNamed('/profile', arguments: likingUserId);
      }
    } else if (type == 'mutual_match') {
      final String? matchId = data['matchId'] as String?;
      final String? otherUserId = data['otherUserId'] as String?;
      final String? otherUserName = data['otherUserName'] as String?;
      if (matchId != null && otherUserId != null) {
        print("PushNotifications: Navigating to chat with $otherUserName ($otherUserId), matchId: $matchId");
        // TODO: Implement navigation to the chat screen
        // Example: Navigator.of(currentContext).pushNamed('/chat', arguments: {'matchId': matchId, 'otherUserId': otherUserId});
      }
    } else {
      print("PushNotifications: Unknown notification type or no type received in data.");
      // TODO: Optionally navigate to a default screen or home screen
      // Example: Navigator.of(currentContext).pushNamed('/home');
    }
  }

  // Enhanced dialog for foreground messages
  Future<void> showForegroundNotificationDialog(BuildContext context, RemoteMessage message) async {
    final Map<String, dynamic> data = message.data;
    String dialogTitle = message.notification?.title ?? "New Notification";
    String dialogBody = message.notification?.body ?? "You have a new message.";
    String? type = data['type'] as String?;

    // Customize dialog further based on type if needed
    if (type == 'profile_view') {
      dialogTitle = data['viewingUserName'] != null ? "${data['viewingUserName']} viewed your profile!" : "Profile View";
    } else if (type == 'new_like') {
      dialogTitle = data['likingUserName'] != null ? "${data['likingUserName']} likes you!" : "New Like";
    } else if (type == 'mutual_match') {
      dialogTitle = "It's a Match!";
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(dialogTitle),
            content: SingleChildScrollView(
              child: Text(dialogBody),
            ),
            actions: [
              TextButton(
                child: const Text("Dismiss"),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              // Optionally add a "View" button that triggers navigation
              TextButton(
                child: const Text("View"),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Dismiss dialog first
                  _handleNotificationTapNavigation(data, context); // Use the main app context
                },
              ),
            ],
          );
        },
      );
    } else {
      print("PushNotifications: Context not mounted, cannot show dialog for foreground message.");
    }
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
