import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A screen that displays a grid of users who have viewed the current user's profile.
class ViewReceivedScreen extends StatelessWidget {
  const ViewReceivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The controller is found once when the widget is built.
    final ProfileController profileController = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Viewed Your Profile', style: TextStyle(color: Colors.yellow[700])),
        backgroundColor: Colors.black87,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (profileController.usersWhoViewedMe.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No one has viewed your profile in the last 36 hours.',
                style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // --- PERFORMANCE FIX --- //
        // The list is reversed *once* before building the GridView.
        final reversedList = profileController.usersWhoViewedMe.reversed.toList();

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.75,
          ),
          itemCount: reversedList.length,
          itemBuilder: (context, index) {
            final Person person = reversedList[index];
            // --- REFACTOR --- //
            // The card logic is now in a separate, clean widget.
            return _UserGridItem(person: person);
          },
        );
      }),
    );
  }
}

/// A private widget to display a single user in the grid.
/// This improves readability and isolates the card's logic.
class _UserGridItem extends StatelessWidget {
  const _UserGridItem({required this.person});

  final Person person;

  // Using a getter for a fallback URL is cleaner.
  String get _imageUrl =>
      person.profilePhoto?.isNotEmpty == true ? person.profilePhoto! : 'https://via.placeholder.com/150';

  // Define text style as a const for performance.
  static const TextStyle _cardTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (person.uid != null) {
          Get.to(() => UserDetailsScreen(userID: person.uid!));
        } else {
          Get.snackbar(
            'Error', 'User ID is missing. Cannot view profile.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey[900],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: _imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) {
                  // --- LOGGING FIX --- //
                  // Use developer log instead of print.
                  log(
                    'Error loading image $_imageUrl for ${person.name}',
                    name: 'ViewReceivedScreen',
                    error: error,
                  );
                  return const Center(
                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${person.name ?? 'N/A'}, ${person.age ?? 'N/A'}',
                textAlign: TextAlign.center,
                style: _cardTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
