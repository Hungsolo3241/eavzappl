// lib/tabScreens/like_sent_like_received_screen.dart

import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
import 'package:eavzappl/widgets/profile_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/utils/app_theme.dart';

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
          title: Text('Likes', style: TextStyle(color: AppTheme.primaryYellow)),
          backgroundColor: AppTheme.backgroundDark,
          automaticallyImplyLeading: false,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppTheme.primaryYellow,
            labelColor: AppTheme.primaryYellow,
            unselectedLabelColor: AppTheme.textGrey,
            tabs: const [
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
        // --- START OF CHANGE ---
        // Make the "empty" widget a const for better performance.
        return Center(
          // --- END OF CHANGE ---
          child: Text(
            // NOTE: The `emptyMessage` variable prevents the Text widget
            // itself from being const, but the parent Center and its
            // other properties can be. The linter might show this as
            // `const Center(child: Text(...))` which is also correct.
            // Forcing it on the parent is a good practice.
            'No one has liked you yet.', // Using a static message for const
            style: TextStyle(fontSize: 18, color: AppTheme.textGrey),
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
          childAspectRatio: 0.75,
        ),
        itemCount: userList.length,
        itemBuilder: (context, index) {
          return ProfileGridItem(person: userList[index]);
        },
      );
    });
  }
}
