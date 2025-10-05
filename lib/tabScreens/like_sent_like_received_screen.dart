// lib/tabScreens/like_sent_like_received_screen.dart

import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
// --- STEP 1: Import the new reusable widget. ---
import 'package:eavzappl/widgets/profile_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LikeSentLikeReceivedScreen extends StatelessWidget {
  const LikeSentLikeReceivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the single controller needed for the entire screen.
    final ProfileController profileController = Get.find<ProfileController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Likes', style: TextStyle(color: Colors.yellow[700])),
          backgroundColor: Colors.black87,
          automaticallyImplyLeading: false,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.yellow,
            labelColor: Colors.yellow,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Likes Sent'),
              Tab(text: 'Likes Received'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // "Likes Sent" Tab now uses the simplified grid view widget.
            _LikesGridView(
              userList: profileController.usersIHaveLiked,
              emptyMessage: "You haven't liked anyone yet.",
            ),
            // "Likes Received" Tab also uses the simplified grid view widget.
            _LikesGridView(
              userList: profileController.usersWhoHaveLikedMe,
              emptyMessage: "No one has liked you yet.",
            ),
          ],
        ),
      ),
    );
  }
}

/// A reusable widget to display a grid of users.
/// This widget itself has been simplified.
class _LikesGridView extends StatelessWidget {
  const _LikesGridView({
    required this.userList,
    required this.emptyMessage,
  });

  final RxList<Person> userList;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (userList.isEmpty) {
        return Center(
          child: Text(
            emptyMessage,
            style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
            textAlign: TextAlign.center,
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.75, // Matches the new widget's aspect ratio
        ),
        itemCount: userList.length,
        itemBuilder: (context, index) {
          // --- STEP 2: Use the new reusable ProfileGridItem widget. ---
          return ProfileGridItem(person: userList[index]);
        },
      );
    });
  }
}

// --- STEP 3: The entire '_UserGridItem' class has been deleted. ---
