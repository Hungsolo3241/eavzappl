import 'package:flutter/material.dart';

import '../tabScreens/favourite_sent_screen.dart';
import '../tabScreens/like_sent_like_received_screen.dart';
import '../tabScreens/swiping_screen.dart';
import '../tabScreens/user_details_screen.dart';
import '../tabScreens/view_received.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
{
  int screenIndex = 0;

  List tabScreensList =
  [
    SwipingScreen(),
    ViewReceivedScreen(),
    FavouriteSentScreen(),
    LikeSentLikeReceivedScreen(),
    UserDetailsScreen(userID: '')
  ];

  // --- DEBUG WRITE FUNCTION ---
  // Future<void> testFirestoreWrite() async {
  //   try {
  //     String? userId = FirebaseAuth.instance.currentUser?.uid;
  //     print('Attempting test write. Current User ID: $userId');
  //
  //     if (userId == null) {
  //       print('Test write failed: User not authenticated.');
  //       if (mounted) { // Check if the widget is still in the tree
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Test write failed: User not authenticated!')),
  //         );
  //       }
  //       return;
  //     }
  //
  //     await FirebaseFirestore.instance
  //         .collection('debug_writes') // A new collection name for this test
  //         .doc('testDoc_${DateTime.now().millisecondsSinceEpoch}')
  //         .set({
  //       'message': 'Test write from Flutter app',
  //       'timestamp': FieldValue.serverTimestamp(),
  //       'userId': userId,
  //     });
  //     print('Firestore test write successful!');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Test write successful! Check Firestore.')),
  //       );
  //     }
  //   } catch (e) {
  //     print('Firestore test write FAILED: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Test write FAILED: $e')),
  //       );
  //     }
  //   }
  // }
  // --- END OF FUNCTION ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(  // Added SafeArea
        bottom: true,
        top: false,
        left: false,
        right: false,
        child: BottomNavigationBar(
          onTap: (indexNumber)
          {
            setState(() {
              screenIndex = indexNumber;
            });
          },
          type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black,
            selectedItemColor: Colors.yellow[700],
            unselectedItemColor: Colors.blueGrey,
            currentIndex: screenIndex,
            items: const [

              // Swiping Screen
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),

              // Views
              BottomNavigationBarItem(
                icon: Icon(Icons.remove_red_eye),
                label: "Views",
              ),

              // Favourites
              BottomNavigationBarItem(
                icon: Icon(Icons.star),
                label: "Favourites",
              ),

              // Likes
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: "Likes",
              ),

              // profile
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ]
        ),
      ),

      // -----DEBUG WRITE FUNCTION Button---
      // body: Column( // Wrap body content in a Column
      //   children: [
      //     Expanded( // Make the current tab screen take up available space
      //       child: tabScreensList[screenIndex],
      //     ),
      //     // Add the test button at the bottom of the column
      //     Padding(
      //       padding: const EdgeInsets.all(16.0),
      //       child: ElevatedButton(
      //         onPressed: testFirestoreWrite,
      //         child: Text('Run Firestore Write Test'),
      //         style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), // Made color slightly different for visibility
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}
