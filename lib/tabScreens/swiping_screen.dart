// GEMINI_WRITE_TEST
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
      if (profile.orientation == 'eve') {
        return evePlaceholderUrl;
      } else if (profile.orientation == 'adam') {
        return adamPlaceholderUrl;
      } else {
        return genericPlaceholderUrl;
      }
    }
  }

  Widget _buildInfoPill(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      margin: const EdgeInsets.only(right: 6.0, bottom: 6.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
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

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            print('Error loading image for ${eachProfileInfo.name}: $exception');
                          },
                        ),
                      ),
                    ),
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
                    Positioned(
                      bottom: 20.0, // Adjusted bottom padding to make space for buttons
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
                                color: Colors.green,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 0.0, color: Colors.black54, offset: Offset(1, 1)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '${eachProfileInfo.age?.toString() ?? ''}${eachProfileInfo.age != null && eachProfileInfo.city != null && eachProfileInfo.city!.isNotEmpty ? ' • ' : ''}${eachProfileInfo.city ?? ''}'.trim(),
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                              shadows: [
                                Shadow(blurRadius: 1.0, color: Colors.black45, offset: Offset(1, 1)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Wrap(
                            spacing: 6.0,
                            runSpacing: 4.0,
                            children: [
                              if (eachProfileInfo.profession != null && eachProfileInfo.profession!.isNotEmpty)
                                _buildInfoPill(eachProfileInfo.profession!),
                              if (eachProfileInfo.ethnicity != null && eachProfileInfo.ethnicity!.isNotEmpty)
                                _buildInfoPill(eachProfileInfo.ethnicity!),
                              if (eachProfileInfo.travelSelection == true)
                                _buildInfoPill("Travels"),
                              if (eachProfileInfo.hostSelection == true)
                                _buildInfoPill("Hosts"),
                              if (eachProfileInfo.meatSelection == true)
                                _buildInfoPill("Meat"),
                              if (eachProfileInfo.greekSelection == true)
                                _buildInfoPill("Greek"),
                              if (eachProfileInfo.smokeSelection == true)
                                _buildInfoPill("Smokes"),
                            ],
                          ),
                          const SizedBox(height: 8.0), // Space before the action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Image.asset('images/default_fave.png', width: 45, height: 45, color: Colors.black54),
                                onPressed: () {
                                  print('Like button tapped for ${eachProfileInfo.name}');
                                  // TODO: Implement like functionality
                                },
                                tooltip: 'Like',
                              ),
                              IconButton(
                                icon: Image.asset('images/default_message.png', width: 90, height: 90, color: Colors.black54),
                                onPressed: () {
                                  print('Message button tapped for ${eachProfileInfo.name}');
                                  // TODO: Implement message functionality
                                },
                                tooltip: 'Message',
                              ),
                              IconButton(
                                icon: Image.asset('images/default_like.png', width: 45, height: 45, color: Colors.black54),
                                onPressed: () {
                                  print('Favorite button tapped for ${eachProfileInfo.name}');
                                  // TODO: Implement favorite functionality
                                },
                                tooltip: 'Favorite',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }),
          Positioned(
            top: statusBarHeight + 8.0,
            right: 8.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                tooltip: 'Filter Profiles',
                onPressed: () {
                  print("Filter button tapped!");
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

