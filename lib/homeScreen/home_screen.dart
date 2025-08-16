import 'package:flutter/material.dart';

import '../tabScreens/favourite_sent_favourite_received_screen.dart';
import '../tabScreens/like_sent_like_received_screen.dart';
import '../tabScreens/swiping_screen.dart';
import '../tabScreens/user_details_screen.dart';
import '../tabScreens/view_sent_view_received_screen.dart';

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
    ViewSentViewReceivedScreen(),
    FavouriteSentFavouriteReceivedScreen(),
    LikeSentLikeReceivedScreen(),
    UserDetailsScreen(userID: '')
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        onTap: (indexNumber)
        {
          setState(() {
            screenIndex = indexNumber;
          });
        },
        type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
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
      body: tabScreensList[screenIndex],
    );
  }
}
