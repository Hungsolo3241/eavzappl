import 'package:eavzappl/pushNotifications/push_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer';

import '../tabScreens/favourite_sent_screen.dart';
import '../tabScreens/like_sent_like_received_screen.dart';
import '../tabScreens/swiping_screen.dart';
import '../tabScreens/user_details_screen.dart';
import '../tabScreens/view_received.dart';
import 'package:eavzappl/utils/app_theme.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _screenIndex = 0;
  late final List<Widget> _tabScreensList;

  @override
  void initState() {
    super.initState();
    
    // ✅ SAFE: Build tab list with null-safe user ID
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    
    _tabScreensList = [
      const SwipingScreen(),
      ViewReceivedScreen(),
      const FavouriteSentScreen(),
      const LikeSentLikeReceivedScreen(),
      // ✅ FIX: Use null-aware operator and provide fallback
      UserDetailsScreen(
        userID: userId ?? 'error', // Fallback will show error screen
      ),
    ];

    // Defer notification initialization until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && userId != null) {
        _initializeNotifications();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      final pushNotifications = Get.find<PushNotifications>();
      await pushNotifications.initialize(context);
    } catch (e) {
      log('Error initializing notifications: $e', name: 'HomeScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        onTap: (indexNumber) {
          setState(() {
            _screenIndex = indexNumber;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.backgroundDark,
        selectedItemColor: AppTheme.primaryYellow,
        unselectedItemColor: AppTheme.textGrey,
        currentIndex: _screenIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.remove_red_eye), label: "Views"),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: "Favourites"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Likes"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      body: IndexedStack(
        index: _screenIndex,
        children: _tabScreensList,
      ),
    );
  }
}

