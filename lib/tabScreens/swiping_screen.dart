import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart'; // Import UserDetailsScreen
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SwipingScreen extends StatefulWidget {
  const SwipingScreen({super.key});

  @override
  State<SwipingScreen> createState() => _SwipingScreenState();
}

class _SwipingScreenState extends State<SwipingScreen> {
  final ProfileController profileController = Get.put(ProfileController());

  // Placeholder URLs
  final String evePlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Feves_avatar.jpeg?alt=media&token=75b9c3f5-72c1-42db-be5c-471cc0d88c05';
  final String adamPlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Fadam_avatar.jpeg?alt=media&token=997423ec-96a4-42d6-aea8-c8cb80640ca0';
  final String genericPlaceholderUrl = 'https://via.placeholder.com/400?text=No+Image';

  String _getImageUrl(Person profile) {
    if (profile.profilePhoto != null && profile.profilePhoto!.isNotEmpty) {
      return profile.profilePhoto!;
    } else {
      // Orientation should be lowercase from ProfileController/data handling
      if (profile.orientation == 'eve') {
        return evePlaceholderUrl;
      } else if (profile.orientation == 'adam') {
        return adamPlaceholderUrl;
      } else {
        return genericPlaceholderUrl; // Fallback if orientation is missing or unexpected
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (profileController.allUsersProfileList.isEmpty) {
          return const Center(
            child: Text(
              "Finding profiles...",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return PageView.builder(
          itemCount: profileController.allUsersProfileList.length,
          controller: PageController(
            initialPage: 0,
            viewportFraction: 1.0,
          ),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final Person eachProfileInfo = profileController.allUsersProfileList[index];
            final String imageUrl = _getImageUrl(eachProfileInfo);

            return Stack( // Use Stack to overlay information on the image
              fit: StackFit.expand, // Make stack fill the PageView item
              children: [
                // Background Image
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageUrl), // Use the determined imageUrl
                      fit: BoxFit.cover,
                      // Optional: Add an errorBuilder for NetworkImage
                      onError: (exception, stackTrace) {
                        // This can help you debug if an image URL fails to load
                        print('Error loading image for ${eachProfileInfo.name}: $exception');
                        // You could set a state to show a different placeholder here if desired
                      },
                    ),
                  ),
                ),

                // Gradient Overlay for better text visibility
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.5, 0.7, 1.0],
                    ),
                  ),
                ),

                // User Information Overlay
                Positioned(
                  bottom: 40.0,
                  left: 16.0,
                  right: 16.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          if (eachProfileInfo.uid != null) {
                            Get.to(() => UserDetailsScreen(userID: eachProfileInfo.uid!));
                          } else {
                            Get.snackbar("Error", "User ID is missing, cannot open details.",
                                backgroundColor: Colors.redAccent, colorText: Colors.white);
                          }
                        },
                        child: Text(
                          eachProfileInfo.name ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 2.0, color: Colors.black54, offset: Offset(1, 1)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${eachProfileInfo.age?.toString() ?? ''}${eachProfileInfo.age != null && eachProfileInfo.city != null && eachProfileInfo.city!.isNotEmpty ? ' • ' : ''}${eachProfileInfo.city ?? ''}'.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          shadows: [
                            Shadow(blurRadius: 1.0, color: Colors.black45, offset: Offset(1, 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

