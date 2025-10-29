import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:eavzappl/controllers/like_controller.dart';
import 'package:eavzappl/widgets/filter_sheet_widget.dart';
import 'package:eavzappl/utils/image_constants.dart';


class SwipingScreen extends StatefulWidget {
  const SwipingScreen({super.key});

  @override
  State<SwipingScreen> createState() => _SwipingScreenState();
}

class _SwipingScreenState extends State<SwipingScreen> {
  final ProfileController profileController = Get.find<ProfileController>();
  final LikeController likeController = Get.find();
  DateTime? _lastPressedAt;

  // Method to show the filter bottom sheet
  void _showFilterModalBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: FilterSheetWidget(
                profileController: profileController,
                scrollController: controller,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    // In the build method
    return PopScope(
        canPop: false, // Prevents automatic back navigation
        onPopInvoked: (didPop) async {
          if (didPop) {
            // This case should not happen because canPop is false, but as a safeguard.
            return;
          }

          final now = DateTime.now();
          // If _lastPressedAt is null or it was more than 2 seconds ago
          if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            // Store the current time
            _lastPressedAt = now;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Press back again to exit',
                  style: TextStyle(color: Colors.white), // Set text color to white for contrast
                ),
                backgroundColor: Colors.black.withOpacity(0.8), // Black background with 80% opacity
                behavior: SnackBarBehavior.floating, // Makes the SnackBar float above the content
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24), // Add rounded corners
                ),
                margin: const EdgeInsets.only(
                    bottom: 40,
                    right: 20,
                    left: 20),
                duration: const Duration(seconds: 2),
              ),
            );

          } else {
            // If the back button is pressed again within 2 seconds, exit the app.
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: Stack(
          children: [
          Obx(() {
            if (profileController.loadingStatus.value == ProfileLoadingStatus.loading ||
                profileController.loadingStatus.value == ProfileLoadingStatus.initial) {

              return const Center(child: CircularProgressIndicator());
            }

            if (profileController.swipingProfileList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "No profiles match your criteria.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      // This re-uses the exact same method as the filter icon!
                      onPressed: _showFilterModalBottomSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Adjust Filters"),
                    ),
                  ],
                ),
              );
            }


            return RefreshIndicator(
              // Call the new method in your ProfileController
                onRefresh: () => profileController.refreshSwipingProfiles(),
                // Optional: Style the loading spinner to match your app's theme
                color: Colors.yellow[700],
                child: PageView.builder(
                  itemCount: profileController.swipingProfileList.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                // Check if there is a next profile and if it has a photo
                if ((index + 1) < profileController.swipingProfileList.length) {
                  final nextPerson = profileController.swipingProfileList[index + 1];
                  if (nextPerson.profilePhoto != null && nextPerson.profilePhoto!.isNotEmpty) {
                    // Pre-cache the next image. This runs in the background.
                    precacheImage(
                      CachedNetworkImageProvider(nextPerson.profilePhoto!),
                      context,
                    );

                  }
                }
                final Person person = profileController.swipingProfileList[index];
                final String placeholderAsset = (person.orientation?.toLowerCase() == 'adam')
                    ? ImageConstants.adamAvatar
                    : ImageConstants.eveAvatar;
                final String? imageUrl = person.profilePhoto;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl ?? '',
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      placeholder: (context, url) => Container(color: Colors.black),
                      errorWidget: (context, url, error) => Image.asset(
                        placeholderAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const _GradientOverlay(),
                    Positioned(
                      bottom: 20.0,
                      left: 16.0,
                      right: 16.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileDetails(person: person),
                          const SizedBox(height: 16.0),
                          _ActionButtons(
                            person: person,
                            profileController: profileController,
                            likeController: likeController,
                          ),
                          const SizedBox(height: 16.0),
                        ],
                      ),
                    ),
                  ],
                );
              },
            )
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
                icon: Icon(Icons.filter_list, color: Colors.yellow[700]),
                onPressed: _showFilterModalBottomSheet,
              ),
            ),
          ),
        ],
      ),
    )
    );
  }
}

// This widget is already const, which is perfect.
class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
    );
  }
}


class _ProfileDetails extends StatelessWidget {

  const _ProfileDetails({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            if (person.uid != null) {

              Get.to(() => UserDetailsScreen(userID: person.uid!));
            }
          },
          child: Text(
            person.name ?? 'N/A',
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black87, blurRadius: 1.0)],
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          '${person.age ?? ''}${person.age != null && person.city?.isNotEmpty == true ? ' • ' : ''}${person.city ?? ''}',
          style: TextStyle(
            color: Colors.yellow[700],
            fontSize: 18,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 1.0)],
          ),
        ),
        const SizedBox(height: 16.0),
        Wrap(
          spacing: 6.0,
          runSpacing: 4.0,
          children: [
            if (person.profession?.isNotEmpty == true) _buildInfoPill(person.profession!),
            if (person.travelSelection == true) _buildInfoPill("Travels"),
            if (person.hostSelection == true) _buildInfoPill("Hosts"),
            if (person.meatSelection == true) _buildInfoPill("Meat"),
            if (person.greekSelection == true) _buildInfoPill("Greek"),
            if (person.smokeSelection == true) _buildInfoPill("Smokes"),
            if (person.drinkSelection == true) _buildInfoPill("Drinks"),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      margin: const EdgeInsets.only(right: 6.0, bottom: 6.0),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.6),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.blueGrey, fontSize: 12.0),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {

  const _ActionButtons({
    required this.person,
    required this.profileController,
    required this.likeController,
  });

  final Person person;
  final ProfileController profileController;
  final LikeController likeController;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Obx(() {
          final bool isFavorite = person.uid != null ? profileController.isFavorite(person.uid!) : false;
          return _buildActionButton(
            isLoading: profileController.isTogglingFavorite.value,
            onPressed: () {
              HapticFeedback.lightImpact();
              if (person.uid != null) {
                profileController.toggleFavoriteStatus(person.uid!);
              }
            },
            activeIconAsset: ImageConstants.faveFull,
            inactiveIconAsset: ImageConstants.faveDefault,
            isActive: isFavorite,
            tooltip: 'Favorite',
          );
        }),
        Obx(() {
          final likeStatus = person.uid != null ? likeController.getLikeStatus(person.uid!) : LikeStatus.none;
          final bool canMessage = likeStatus == LikeStatus.mutualLike;
          return _buildActionButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              if (canMessage) {
                _launchWhatsApp(person.phoneNumber);
              } else {
                Get.snackbar("Message Unavailable", "You can only message users after a mutual like.");
              }
            },
            inactiveIconAsset: ImageConstants.messageDefault,
            isActive: canMessage,
            tooltip: canMessage ? 'Message' : 'Message (Requires Mutual Like)',
            iconSize: 75,
            activeColor: Colors.yellow[700],
            inactiveColor: Colors.blueGrey.withOpacity(0.5),
          );
        }),
        Obx(() {
          final likeStatus = person.uid != null ? likeController.getLikeStatus(person.uid!) : LikeStatus.none;
          return _buildActionButton(
            isLoading: likeController.isTogglingLike.value,
            onPressed: () {
              HapticFeedback.lightImpact();
              if (person.uid != null) {
                likeController.toggleLike(person.uid!);
              }
            },
            likeStatus: likeStatus,
            tooltip: 'Like',
          );
        }),
      ],
    );
  }

  Widget _buildActionButton(
      {required VoidCallback onPressed,
        String? inactiveIconAsset,
        String? activeIconAsset,
        bool isActive = false,
        bool isLoading = false,
        String tooltip = '',
        double iconSize = 40,
        Color? activeColor,
        Color? inactiveColor = Colors.blueGrey,
        LikeStatus? likeStatus}) {
    if (isLoading) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation(Colors.white)),
        ),
      );
    }
    String iconAsset;
    Color? iconColor;
    if (likeStatus != null) {
      switch (likeStatus) {
        case LikeStatus.liked:
        case LikeStatus.likedBy:
          iconAsset = ImageConstants.likeHalf;
          iconColor = null;
          break;
        case LikeStatus.mutualLike:
          iconAsset = ImageConstants.likeFull;
          iconColor = Colors.yellow[700];
          break;
        case LikeStatus.none:
        default:
          iconAsset = ImageConstants.likeDefault;
          iconColor = Colors.blueGrey;
          break;
      }
    } else {
      iconAsset = isActive ? (activeIconAsset ?? inactiveIconAsset!) : inactiveIconAsset!;
      iconColor = isActive ? (activeColor ?? Colors.yellow[700]) : inactiveColor;
    }
    return IconButton(
      icon: Image.asset(iconAsset, width: iconSize, height: iconSize, color: iconColor),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Future<void> _launchWhatsApp(String? phoneNumber) async {
    if (phoneNumber?.isNotEmpty != true) {
      Get.snackbar("Message Error", "User's phone number is not available.");
      return;
    }
    try {
      final Uri whatsappUri = Uri.parse("https://api.whatsapp.com/send?phone=$phoneNumber");
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar("WhatsApp Error", "Could not open WhatsApp.");
      }
    } catch (e) {
      log('Could not launch WhatsApp', name: 'SwipingScreen', error: e);
      Get.snackbar("WhatsApp Error", "An error occurred trying to open WhatsApp.");
    }
  }
}
