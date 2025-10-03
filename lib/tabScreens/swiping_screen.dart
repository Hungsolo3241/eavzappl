import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/filter_preferences.dart';
import 'package:eavzappl/models/person.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:eavzappl/controllers/like_controller.dart';

class SwipingScreen extends StatefulWidget {
  const SwipingScreen({super.key});

  @override
  State<SwipingScreen> createState() => _SwipingScreenState();
}

class _SwipingScreenState extends State<SwipingScreen> {
  final ProfileController profileController = Get.find<ProfileController>();
  int _currentPageIndex = 0;
  final LikeController likeController = Get.find();

  void _showFilterModalBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: _FilterSheetContent(
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

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            if (profileController.loadingStatus.value == ProfileLoadingStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (profileController.swipingProfileList.isEmpty) {
              return const Center(
                child: Text(
                  "No profiles match your criteria.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            return PageView.builder(
              itemCount: profileController.swipingProfileList.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final Person person = profileController.swipingProfileList[index];

                final String placeholderAsset = (person.orientation?.toLowerCase() == 'adam')
                    ? 'images/adam_avatar.jpeg'
                    : 'images/eves_avatar.jpeg';

                final String? imageUrl = person.profilePhoto;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    (imageUrl != null && imageUrl.isNotEmpty)
                        ? FadeInImage.assetNetwork(
                            placeholder: placeholderAsset,
                            image: imageUrl,
                            fit: BoxFit.cover,
                            imageErrorBuilder: (context, error, stackTrace) {
                              return Image.asset(placeholderAsset, fit: BoxFit.cover);
                            },
                          )
                        : Image.asset(placeholderAsset, fit: BoxFit.cover),
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
                            likeController: likeController,     // <-- ADD THIS
                          ),
                          const SizedBox(height: 16.0),
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
                icon: Icon(Icons.filter_list, color: Colors.yellow[700]),
                onPressed: _showFilterModalBottomSheet,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    required this.likeController, // This line is correct from your previous work
  });

  final Person person;
  final ProfileController profileController;
  final LikeController likeController; // <-- ADD THIS LINE

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
            activeIconAsset: 'images/full_fave.png',
            inactiveIconAsset: 'images/default_fave.png',
            isActive: isFavorite,
            tooltip: 'Favorite',
          );
        }),
        Obx(() {
          final likeStatus = person.uid != null ? likeController.getLikeStatus(person.uid!) : LikeStatus.none;          final bool canMessage = likeStatus == LikeStatus.mutualLike;
          return _buildActionButton(
            onPressed: canMessage
                ? () => _launchWhatsApp(person.phoneNumber)
                : () => Get.snackbar(
              "Message Unavailable",
              "You can only message users after a mutual like.",
            ),
            inactiveIconAsset: 'images/default_message.png',
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
            // --- AND THIS LINE ---
            isLoading: likeController.isTogglingLike.value,
            onPressed: () {
              HapticFeedback.lightImpact();
              if (person.uid != null) {
                // --- AND THIS LINE ---
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

  Widget _buildActionButton({
    required VoidCallback onPressed,
    String? inactiveIconAsset,
    String? activeIconAsset,
    bool isActive = false,
    bool isLoading = false,
    String tooltip = '',
    double iconSize = 40,
    Color? activeColor,
    Color? inactiveColor = Colors.blueGrey,
    LikeStatus? likeStatus,
  }) {
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
        case LikeStatus.likedBy: // <-- THE FIX IS HERE
          iconAsset = 'images/half_like.png';
          iconColor = null; // Assuming you want the default image color
          break;
        case LikeStatus.mutualLike:
          iconAsset = 'images/full_like.png';
          iconColor = Colors.yellow[700];
          break;
        case LikeStatus.none:
        default:
          iconAsset = 'images/default_like.png';
          iconColor = Colors.blueGrey;
          break;
      }
    } else {
      iconAsset = isActive ? (activeIconAsset ?? inactiveIconAsset!) : inactiveIconAsset!;
      iconColor = isActive ? (activeColor ?? Colors.yellow[700]) : inactiveColor;
    }

    return IconButton(
      icon: Image.asset(
        iconAsset,
        width: iconSize,
        height: iconSize,
        color: iconColor,
      ),
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

class _FilterSheetContent extends StatefulWidget {
  final ProfileController profileController;
  final ScrollController scrollController;

  const _FilterSheetContent({
    required this.profileController,
    required this.scrollController,
  });

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  late RangeValues _currentAgeRange;
  String? _selectedEthnicity;
  String? _selectedGender;
  String? _selectedProfession;

  static const List<String> _ethnicities = ["Any", "Asian", "Black", "Mixed", "White"];
  static const List<String> _professions = ["Any", "Student", "Freelancer", "Professional"];
  static const List<String> _genders = ["Any", "Male", "Female"];

  @override
  void initState() {
    super.initState();
    final currentFilters = widget.profileController.activeFilters.value;
    _currentAgeRange = currentFilters.ageRange ?? const RangeValues(18, 65);
    _selectedEthnicity = currentFilters.ethnicity ?? "Any";
    _selectedGender = currentFilters.gender ?? "Any";
    _selectedProfession = currentFilters.profession ?? "Any";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Center(
            child: Text(
              'Filter Profiles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Text('Age Range: ${_currentAgeRange.start.round()} - ${_currentAgeRange.end.round()}',
              style: const TextStyle(fontSize: 16)),
          RangeSlider(
            values: _currentAgeRange,
            min: 18,
            max: 100,
            divisions: 82,
            labels: RangeLabels(
              _currentAgeRange.start.round().toString(),
              _currentAgeRange.end.round().toString(),
            ),
            onChanged: (RangeValues values) {
              setState(() => _currentAgeRange = values);
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown("Gender", _selectedGender, _genders, (val) => setState(() => _selectedGender = val)),
          const SizedBox(height: 16),
          _buildDropdown("Profession", _selectedProfession, _professions, (val) => setState(() => _selectedProfession = val)),
          const SizedBox(height: 16),
          _buildDropdown("Ethnicity", _selectedEthnicity, _ethnicities, (val) => setState(() => _selectedEthnicity = val)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  widget.profileController.applyFilters(FilterPreferences.initial());
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                child: const Text('Clear Filters', style: TextStyle(color: Colors.black87)),
              ),
              ElevatedButton(
                onPressed: () {
                  final newFilters = FilterPreferences(
                    ageRange: _currentAgeRange,
                    ethnicity: _selectedEthnicity == "Any" ? null : _selectedEthnicity,
                    gender: _selectedGender == "Any" ? null : _selectedGender,
                    profession: _selectedProfession == "Any" ? null : _selectedProfession,
                  );
                  widget.profileController.applyFilters(newFilters);
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      value: items.contains(currentValue) ? currentValue : items.first,
      isExpanded: true,
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}