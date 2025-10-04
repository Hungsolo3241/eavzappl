
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LikeSentLikeReceivedScreen extends StatelessWidget {
  const LikeSentLikeReceivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A single controller is needed for the entire screen.
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
            tabs: [
              Tab(text: 'Likes Sent'),
              Tab(text: 'Likes Received'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // "Likes Sent" Tab
            _LikesGridView(
              userList: profileController.usersIHaveLiked,
              emptyMessage: "You haven't liked anyone yet.",
            ),
            // "Likes Received" Tab
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

/// A reusable widget to display a grid of users for a given list of UIDs.
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
          return _UserGridItem(person: userList[index]);
        },
      );
    });
  }
}

/// A dedicated widget to display a single user in the likes grid.
/// A dedicated widget to display a single user in the likes grid.
class _UserGridItem extends StatelessWidget {
  const _UserGridItem({required this.person});

  final Person person;

  // --- START: IMPROVEMENT ---
  // Use local assets for placeholders instead of a network URL.
  String get _placeholderAsset {
    return person.orientation?.toLowerCase() == 'adam'
        ? 'images/adam_avatar.jpeg'
        : 'images/eves_avatar.jpeg';
  }
  // --- END: IMPROVEMENT ---

  @override
  Widget build(BuildContext context) {
    // This logic is now cleaner. We only need the real profile photo URL.
    final imageUrl = person.profilePhoto;

    return InkWell(
      onTap: () {
        if (person.uid != null) {
          Get.to(() => UserDetailsScreen(userID: person.uid!));
        } else {
          log(
            'Tap failed: UID is null for ${person.name}',
            name: 'LikesScreen',
          );
          Get.snackbar('Error', 'User ID is missing. Cannot open details.');
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              // Check if the URL from Firestore is valid
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.black54, // A dark background for the loader
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                ),
                errorWidget: (context, url, error) {
                  log(
                    'Error loading image $imageUrl for ${person.name}',
                    name: 'LikesScreen',
                    error: error,
                  );
                  // If the network image fails, show the local placeholder
                  return Image.asset(_placeholderAsset, fit: BoxFit.cover);
                },
              )
              // If there is no URL to begin with, show the local placeholder
                  : Image.asset(_placeholderAsset, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                person.age != null ? '${person.name ?? 'N/A'} • ${person.age}' : (person.name ?? 'N/A'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.yellow[700],
                ),
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

