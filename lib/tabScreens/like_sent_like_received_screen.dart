import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LikeSentLikeReceivedScreen extends StatefulWidget {
  const LikeSentLikeReceivedScreen({super.key});

  @override
  State<LikeSentLikeReceivedScreen> createState() =>
      _LikeSentLikeReceivedScreenState();
}

class _LikeSentLikeReceivedScreenState
    extends State<LikeSentLikeReceivedScreen> {
  bool isLikeSentTabActive = true; // true for "Liked by me", false for "Likes on me"
  final ProfileController profileController = Get.find<ProfileController>();

  String _getImageUrl(Person person) {
    if (person.profilePhoto != null && person.profilePhoto!.isNotEmpty) {
      return person.profilePhoto!;
    }
    // Fallback placeholder if profilePhoto is null or empty
    // Consider Eve/Adam specific placeholders if orientation is available and desired
    return 'https://via.placeholder.com/150';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.8),
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: () {
                    if (!isLikeSentTabActive) {
                      setState(() {
                        isLikeSentTabActive = true;
                      });
                    }
                  },
                  child: Text(
                    "They Liked", // Changed from "Liked"
                    style: TextStyle(
                      color: isLikeSentTabActive
                          ? Colors.yellow[700]
                          : Colors.blueGrey,
                      fontWeight: isLikeSentTabActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 20,
                    ),
                  )),
              const Text(
                '  |  ',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              TextButton(
                  onPressed: () {
                    if (isLikeSentTabActive) {
                      setState(() {
                        isLikeSentTabActive = false;
                      });
                    }
                  },
                  child: Text(
                    "I Liked", // Changed from "Likes"
                    style: TextStyle(
                      color: !isLikeSentTabActive
                          ? Colors.yellow[700]
                          : Colors.blueGrey,
                      fontWeight: !isLikeSentTabActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 20,
                    ),
                  ))
            ],
          ),
        ),
        body: Obx(() {
          List<Person> displayedProfiles;
          String emptyListMessage;

          if (isLikeSentTabActive) { // "They Liked" (Profiles that liked the current user)
            displayedProfiles = profileController.usersProfileList.value
                .where((person) =>
            person.likeStatus.value ==
                LikeStatus.targetUserLikedCurrentUser ||
                person.likeStatus.value == LikeStatus.mutualLike)
                .toList();
            emptyListMessage = "No one has liked you yet.";
          } else { // "I Liked" (Profiles the current user has liked)
            displayedProfiles = profileController.usersProfileList.value
                .where((person) =>
            person.likeStatus.value == LikeStatus.currentUserLiked ||
                person.likeStatus.value == LikeStatus.mutualLike)
                .toList();
            emptyListMessage = "You haven't liked anyone yet.";
          }

          if (displayedProfiles.isEmpty) {
            return Center(
              child: Text(
                emptyListMessage,
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
              childAspectRatio: 0.75,
            ),
            itemCount: displayedProfiles.length,
            itemBuilder: (context, index) {
              final Person person = displayedProfiles[index];
              final String imageUrl = _getImageUrl(person);

              return InkWell(
                onTap: () {
                  if (person.uid != null) {
                    Get.to(() => UserDetailsScreen(userID: person.uid!));
                  } else {
                    Get.snackbar('Error', 'User ID is missing.');
                  }
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 4.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                    null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image,
                                  size: 50, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${person.name ?? 'N/A'} • ${person.age ?? 'N/A'}',
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
            },
          );
        }));
  }
}
