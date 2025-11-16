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
import 'package:flutter/scheduler.dart'; // Add this import

import 'package:eavzappl/controllers/like_controller.dart';
import 'package:eavzappl/widgets/filter_sheet_widget.dart';
import 'package:eavzappl/utils/image_constants.dart';
import 'package:eavzappl/utils/app_theme.dart';


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
                color: AppTheme.backgroundDark.withOpacity(0.5),
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

  return PopScope(
    canPop: false,
    onPopInvoked: (didPop) async {
      final now = DateTime.now();
      if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
        _lastPressedAt = now;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Press back again to exit',
              style: TextStyle(color: AppTheme.textGrey),
            ),
            backgroundColor: AppTheme.backgroundDark.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            margin: const EdgeInsets.only(bottom: 40, right: 20, left: 20),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        SystemNavigator.pop();
      }
    },
    child: Scaffold(
      body: Stack(
        children: [
          Obx(() {
            if (!likeController.isInitialized.value ||
                profileController.loadingStatus.value == ProfileLoadingStatus.loading ||
                profileController.loadingStatus.value == ProfileLoadingStatus.initial) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading profiles...', style: TextStyle(color: AppTheme.textGrey)),
                  ],
                ),
              );
            } else if (profileController.swipingProfileList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "No profiles match your criteria.",
                      style: AppTextStyles.body1.copyWith(color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showFilterModalBottomSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: AppTheme.backgroundDark,
                      ),
                      child: const Text("Adjust Filters"),
                    ),
                  ],
                ),
              );
            } else {
              return RefreshIndicator(
                onRefresh: () => profileController.refreshSwipingProfiles(),
                color: AppTheme.primaryYellow,
                child: PageView.builder(
                  itemCount: profileController.swipingProfileList.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    // Pre-cache the next 2-3 images for a smoother swiping experience
                    for (int i = 1; i <= 3; i++) {
                      if ((index + i) < profileController.swipingProfileList.length) {
                        final nextPerson = profileController.swipingProfileList[index + i];
                        if (nextPerson.profilePhoto != null && nextPerson.profilePhoto!.isNotEmpty) {
                          precacheImage(
                            CachedNetworkImageProvider(nextPerson.profilePhoto!),
                            context,
                          );
                        }
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
                          placeholder: (context, url) => Container(color: AppTheme.backgroundDark),
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
                ),
              );
            }
          }),
          
          Positioned(
            top: statusBarHeight + 8.0,
            right: 8.0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list, color: AppTheme.primaryYellow),
                onPressed: _showFilterModalBottomSheet,
              ),
            ),
          ),
        ],
      ),
    ),
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
            AppTheme.backgroundDark.withOpacity(0.1),
            AppTheme.backgroundDark.withOpacity(0.7),
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
    // Define the status indicator widget
    Widget statusIndicator = const SizedBox.shrink(); // Empty by default
    if (person.orientation?.toLowerCase() == 'eve') {
      statusIndicator = Container(
        margin: const EdgeInsets.only(left: 8.0), // Margin on the left for spacing
        width: 12.0,
        height: 12.0,
        decoration: BoxDecoration(
          color: (person.isAvailable ?? true) ? Colors.greenAccent : Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.textGrey, width: 1.5), // Use blueGrey for border
        ),
      );
    }

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  person.name ?? 'N/A',
                  style: AppTextStyles.heading1.copyWith(color: AppTheme.textGrey, shadows: const [Shadow(color: AppTheme.backgroundDark, blurRadius: 1.0)]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              statusIndicator, // Placed on the right side of the name
            ],
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          '${person.age ?? ''}${person.age != null && person.city?.isNotEmpty == true ? ' • ' : ''}${person.city ?? ''}',
          style: AppTextStyles.body1.copyWith(color: AppTheme.primaryYellow, shadows: const [Shadow(color: AppTheme.backgroundDark, blurRadius: 1.0)]),
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
        color: AppTheme.backgroundDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppTheme.textGrey),
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
              HapticFeedback.mediumImpact();
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
              HapticFeedback.mediumImpact();
              if (canMessage) {
                _launchWhatsApp(person.phoneNumber);
              } else {
                // Use ScaffoldMessenger to show the snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      "You can only message users after a mutual like.",
                      style: TextStyle(color: AppTheme.textLight),
                    ),
                    backgroundColor: AppTheme.backgroundDark.withOpacity(0.8),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height - 150,
                      right: 20,
                      left: 20,
                    ),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'DISMISS',
                      textColor: AppTheme.primaryYellow,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                );
              }
            },
            inactiveIconAsset: ImageConstants.messageDefault,
            isActive: canMessage,
            tooltip: canMessage ? 'Message' : 'Message (Requires Mutual Like)',
            iconSize: 75,
            activeColor: AppTheme.primaryYellow,
            inactiveColor: AppTheme.textGrey,
          );
        }),
        Obx(() {
          final likeStatus = person.uid != null ? likeController.getLikeStatus(person.uid!) : LikeStatus.none;
          return _buildActionButton(
            isLoading: likeController.isTogglingLike.value,
            onPressed: () {
              HapticFeedback.mediumImpact();
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
        Color? inactiveColor = AppTheme.textGrey,
        LikeStatus? likeStatus}) {
    if (isLoading) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation(AppTheme.textGrey)),
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
          iconColor = AppTheme.primaryYellow;
          break;
        case LikeStatus.none:
        default:
          iconAsset = ImageConstants.likeDefault;
          iconColor = AppTheme.textGrey;
          break;
      }
    } else {
      iconAsset = isActive ? (activeIconAsset ?? inactiveIconAsset!) : inactiveIconAsset!;
      iconColor = isActive ? (activeColor ?? AppTheme.primaryYellow) : inactiveColor;
    }
    return IconButton(
      icon: Image.asset(iconAsset, width: iconSize, height: iconSize, color: iconColor),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Future<void> _launchWhatsApp(String? phoneNumber) async {
    if (phoneNumber?.isNotEmpty != true) {
      Get.snackbar("Message Error", "User's phone number is not available.", colorText: AppTheme.textLight);
      return;
    }
    try {
      final Uri whatsappUri = Uri.parse("https://api.whatsapp.com/send?phone=$phoneNumber");
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar("WhatsApp Error", "Could not open WhatsApp.", colorText: AppTheme.textLight);
      }
    } catch (e) {
      log('Could not launch WhatsApp', name: 'SwipingScreen', error: e);
      Get.snackbar("WhatsApp Error", "An error occurred trying to open WhatsApp.", colorText: AppTheme.textLight);
    }
  }
}
