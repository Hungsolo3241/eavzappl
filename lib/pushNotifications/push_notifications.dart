import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // Required for Firebase.initializeApp in background handler
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart'; // For BuildContext and showDialog
// import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Optional: for foreground local notifications
// import 'dart:convert'; // For jsonEncode if using flutter_local_notifications payload

// IMPORTANT: The true background handler must be a top-level function,
// usually in your main.dart file, and registered with
// FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
// before runApp(). Example:
/*
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase is initialized here too
  print("Handling a background message: ${message.messageId}");
  // Add any custom logic here, e.g., showing a local notification if configured
}
*/

class PushNotifications {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // late BuildContext _appContext; // Storing context like this can be risky. Prefer passing it.

  // Optional: For displaying local notifications, especially for foreground messages
  // final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize(BuildContext context) async {
    // _appContext = context; // Avoid storing context like this if possible.

    // Initialize local notifications plugin (if using)
    // await _initializeLocalNotifications();

    // 1. Request Permissions (iOS and Android 13+)
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

    // 2. Get FCM Token & Save/Update it on your server
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
        // For foreground messages, FCM doesn't show a system notification by default.
        // Option A: Display your custom in-app dialog (using the passed context)
        openAppAndShowNotification(context, message);

        // Option B: Use flutter_local_notifications to show a system-like notification (if configured)
        // _showLocalNotification(message);
      }
    });

    // 4. Handle Background Messages (when the user taps on the notification and app opens)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('PushNotifications: Message clicked and opened app from background!');
      print('PushNotifications: Message data: ${message.data}');
      // TODO: Implement navigation to a specific part of your app based on message.data
      // Example: _handleNotificationTapNavigation(message.data, context); // Pass context if needed for navigation
    });

    // 5. Handle Terminated Messages (app opened from a terminated state by tapping the notification)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('PushNotifications: App opened from terminated state by a notification!');
      print('PushNotifications: Initial Message data: ${initialMessage.data}');
      // TODO: Implement navigation based on initialMessage.data.
      // Navigation here might be more complex as the widget tree is just being built.
      // Often, this involves passing data to your initial route/widget.
      // Example: _handleNotificationTapNavigation(initialMessage.data, null); // Context might not be available yet or needed differently
    }
  }

  Future<void> _getAndSaveFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("PushNotifications: FCM Token: $token");
      _saveTokenToDatabase(token);
    }
  }

  void _saveTokenToDatabase(String token) {
    // TODO: Implement this method to save the token to Firestore (or your backend)
    // against the currently logged-in user. This is CRUCIAL.
    // Example (ensure you have current user's ID, e.g., from FirebaseAuth):
    // String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // if (currentUserId != null) {
    //   FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(currentUserId)
    //     .set({'fcmTokens': FieldValue.arrayUnion([token])}, SetOptions(merge: true))
    //     .then((_) => print("PushNotifications: FCM token saved for user $currentUserId"))
    //     .catchError((error) => print("PushNotifications: Failed to save FCM token: $error"));
    // } else {
    //   print("PushNotifications: User not logged in, cannot save FCM token.");
    // }
    print("PushNotifications: TODO: Implement _saveTokenToDatabase for token: $token");
  }

  // Example method for handling navigation (you'll need to define this based on your app's routing)
  // void _handleNotificationTapNavigation(Map<String, dynamic> data, BuildContext? context) {
  //   print("PushNotifications: Navigating with data: $data");
  //   // String? screen = data['screen']; // Example: expect 'screen' in payload
  //   // if (screen == '/chat' && data['chatId'] != null) {
  //   //   if (context != null && context.mounted) {
  //   //     Navigator.of(context).pushNamed('/chat', arguments: data['chatId']);
  //   //   } else {
  //   //     // Handle navigation when context is not available (e.g., for terminated state)
  //   //     // This might involve setting some global state or passing initial route params.
  //   //   }
  //   // }
  // }

  // --- Optional: flutter_local_notifications setup (if you choose to use it) ---
  // Future<void> _initializeLocalNotifications() async {
  //   const AndroidInitializationSettings initializationSettingsAndroid =
  //       AndroidInitializationSettings('@mipmap/ic_launcher'); // Replace with your app icon
  //   final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
  //       onDidReceiveLocalNotification: (id, title, body, payload) async {
  //     // Older iOS callback
  //   });
  //   final InitializationSettings initializationSettings = InitializationSettings(
  //     android: initializationSettingsAndroid,
  //     iOS: initializationSettingsIOS,
  //   );
  //   await _localNotificationsPlugin.initialize(initializationSettings,
  //       onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
  //     if (notificationResponse.payload != null) {
  //       print('PushNotifications: Local notification payload: ${notificationResponse.payload}');
  //       // Map<String, dynamic> data = jsonDecode(notificationResponse.payload!);
  //       // _handleNotificationTapNavigation(data, _appContext); // Be careful with stored context
  //     }
  //   });
  // }

  // Future<void> _showLocalNotification(RemoteMessage message) async {
  //   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  //     'your_channel_id', // Must be unique
  //     'Your Channel Name',
  //     channelDescription: 'Notifications from Your App',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );
  //   const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
  //   await _localNotificationsPlugin.show(
  //     message.hashCode, // Unique ID
  //     message.notification?.title,
  //     message.notification?.body,
  //     platformDetails,
  //     payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
  //   );
  // }
  // --- End Optional ---

  // Modified to accept RemoteMessage and BuildContext, with corrected string logic
  Future<void> openAppAndShowNotification(BuildContext context, RemoteMessage message) async {
    print("PushNotifications: Attempting to show in-app notification for message: ${message.messageId}");
    // String? senderId = message.data['senderId']; // Example: assuming 'senderId' from payload

    // TODO: Fetch user data based on senderId or other data from message.data
    // TODO: Create and show your NotificationDialogBox widget

    // Placeholder dialog:
    if (context.mounted) { // Check if the context is still valid
      String dialogTitle = message.notification?.title ?? "New Notification";
      String dialogBody = message.notification?.body ?? "You have a new message.";

      if (message.data.isNotEmpty) {
        dialogBody += "\n\nData: ${message.data.toString()}";
      }

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(dialogTitle),
            content: SingleChildScrollView( // In case content is long
              child: Text(dialogBody),
            ),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              )
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
