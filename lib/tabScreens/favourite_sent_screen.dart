// lib/tabScreens/favourite_sent_screen.dart

import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
// --- START: STEP 1 ---
// Import the new reusable widget.
import 'package:eavzappl/widgets/profile_grid_item.dart';
// --- END: STEP 1 ---
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/utils/app_theme.dart';


class FavouriteSentScreen extends StatelessWidget {
  const FavouriteSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the already initialized controller.
    final ProfileController profileController = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Favourites', style: TextStyle(color: AppTheme.primaryYellow)),
        backgroundColor: AppTheme.backgroundDark,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Obx(() {
        // Correctly get the list of favorite Person objects from the controller.
        final List<Person> favouriteProfiles = profileController.usersIHaveFavourited;

        if (favouriteProfiles.isEmpty) {
          return const Center(
            child: Text(
              "You haven't favorited anyone yet.",
              style: TextStyle(fontSize: 18, color: AppTheme.textGrey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.75, // Aspect ratio can be adjusted if needed
          ),
          itemCount: favouriteProfiles.length,
          itemBuilder: (context, index) {
            // --- START: STEP 2 ---
            // Use the new reusable ProfileGridItem widget.
            return ProfileGridItem(person: favouriteProfiles[index]);
            // --- END: STEP 2 ---
          },
        );
      }),
    );
  }
}

// --- START: STEP 3 ---
// The entire '_FavoriteGridItem' class has been deleted.
// --- END: STEP 3 ---
