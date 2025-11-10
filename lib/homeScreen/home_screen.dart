import 'package:eavzappl/pushNotifications/push_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

    _tabScreensList = [
      const SwipingScreen(),
      ViewReceivedScreen(),
      const FavouriteSentScreen(),
      const LikeSentLikeReceivedScreen(),
      UserDetailsScreen(userID: FirebaseAuth.instance.currentUser!.uid),
    ];

    // Defer the initialization until after the first frame is rendered.
    // This ensures that all GetX bindings from main.dart are complete.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Check if the widget is still in the tree
        _initializeNotifications();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    // Now it's safe to call Get.find()
    final pushNotifications = Get.find<PushNotifications>();
    await pushNotifications.initialize(context);
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_red_eye),
            label: "Views",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: "Favourites",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Likes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
      body: IndexedStack(
        index: _screenIndex,
        children: _tabScreensList,
      ),
    );
  }
}
