import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
// --- STEP 1: Import the new reusable widget. ---
import 'package:eavzappl/widgets/profile_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/utils/app_theme.dart';

/// A screen that displays a grid of users who have viewed the current user's profile.
class ViewReceivedScreen extends StatelessWidget {
  const ViewReceivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The controller is found once when the widget is built.
    final ProfileController profileController = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Viewed Your Profile', style: TextStyle(color: AppTheme.primaryYellow)),
        backgroundColor: AppTheme.backgroundDark,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Obx(() {
        if (profileController.usersWhoViewedMe.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No one has viewed your profile yet.',
                style: TextStyle(fontSize: 18, color: AppTheme.textGrey),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // The list is reversed *once* before building the GridView.
        final reversedList = profileController.usersWhoViewedMe.reversed.toList();

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.75, // Matches the aspect ratio of the new widget
          ),
          itemCount: reversedList.length,
          itemBuilder: (context, index) {
            final Person person = reversedList[index];
            // --- STEP 2: Use the new reusable ProfileGridItem widget. ---
            return ProfileGridItem(person: person);
          },
        );
      }),
    );
  }
}

// --- STEP 3: The entire '_UserGridItem' class has been deleted. ---
