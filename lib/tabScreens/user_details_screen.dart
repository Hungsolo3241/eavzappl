import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
import 'package:eavzappl/accountSettingsScreen/user_settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eavzappl/controllers/authentication_controller.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userID;

  const UserDetailsScreen({super.key, required this.userID});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final ProfileController _profileController = Get.find<ProfileController>();
  final String? _currentAuthUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _profileController.recordProfileView(widget.userID);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUserProfile = _currentAuthUserId == widget.userID;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userID)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScaffold();
          }
          if (snapshot.hasError) {
            log(
              'Error loading user details for ${widget.userID}',
              name: 'UserDetailsScreen',
              error: snapshot.error,
            );
            return _ErrorScaffold(
                message: 'Error loading profile: ${snapshot.error}');
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const _ErrorScaffold(
                message: 'Profile for user ID not found.');
          }

          final Map<String, dynamic> data = snapshot.data!.data()!;
          data['uid'] = snapshot.data!.id;
          final person = Person.fromJson(data);

          final bool isAdamProfile = person.orientation?.toLowerCase() == 'adam';

          return Scaffold(
            appBar: AppBar(
              title: Text(isCurrentUserProfile ? "My Profile" : (person.name ?? "User Profile")),
              centerTitle: true,
              actions: isCurrentUserProfile
                  ? [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: () {
                    Get.to(() => const UserSettingsScreen());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () async {
                    // Added for consistency with the settings screen
                    bool? confirmLogout = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.grey[850],
                          title: const Text('Log Out', style: TextStyle(color: Colors.blueGrey)),
                          content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmLogout == true) {
                      // Correctly find the controller and call the logout method to reset state.
                      final AuthenticationController authController = Get.find();
                      await authController.logoutUser();
                    }
                  },
                ),
              ]
                  : null,
            ),
            body: SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('images/userDetailsBackground.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _ProfileHeader(person: person),
                      const SizedBox(height: 20),
                      _ImageCarousel(person: person),
                      const SizedBox(height: 24),
                      if (!isCurrentUserProfile)
                        _ActionButtons(
                          person: person,
                          profileController: _profileController,
                        ),
                      _DetailSection(
                        title: "About",
                        details: {
                          "Profession": person.profession,
                          if (person.orientation?.toLowerCase() == 'eve')
                            "Venues": person.professionalVenues?.join(", "),
                          if (person.orientation?.toLowerCase() == 'eve')
                            "Other Venue": person.otherProfessionalVenue,
                          "Location": [person.city, person.province, person.country]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(", "),
                          "Ethnicity": person.ethnicity,
                        },
                      ),
                      if (person.orientation?.toLowerCase() == 'eve')
                        _SocialLinks(person: person),
                      if (!isAdamProfile || isCurrentUserProfile) ...[
                        _DetailSection(
                          title: "Appearance",
                          details: {
                            "Height": person.height,
                            "Body Type": person.bodyType,
                          },
                        ),
                        _DetailSection(
                          title: "Background",
                          details: {
                            "Nationality": person.nationality,
                            "Languages Spoken": person.languages,
                          },
                        ),
                      ],
                      _DetailSection(
                        title: "Looking/Available For",
                        isBoolean: true,
                        details: {
                          "Breakfast": person.lookingForBreakfast?.toString(),
                          "Lunch": person.lookingForLunch?.toString(),
                          "Dinner": person.lookingForDinner?.toString(),
                          "Long Term": person.lookingForLongTerm?.toString(),
                        },
                      ),
                      _DetailSection(
                        title: "Lifestyle",
                        isBoolean: true,
                        details: {
                          "Drinks": person.drinkSelection?.toString(),
                          "Smokes": person.smokeSelection?.toString(),
                          "Eats Meat": person.meatSelection?.toString(),
                          "Greek Life": person.greekSelection?.toString(),
                          "Enjoys Hosting": person.hostSelection?.toString(),
                          "Travels": person.travelSelection?.toString(),
                        },
                      ),
                      if (!isAdamProfile)
                        _DetailSection(
                          title: "",
                          details: {"Income Range": person.income},
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  const _ErrorScaffold({required this.message});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Error")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context) {
    final String defaultAvatarAsset =
    (person.orientation?.toLowerCase() == 'adam')
        ? 'images/adam_avatar.jpeg'
        : 'images/eves_avatar.jpeg';

    final String? profilePhotoUrl = person.profilePhoto;

    return Column(
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 70,
          backgroundColor: Colors.grey.shade700,
          child: ClipOval( // Use ClipOval to make the FadeInImage circular
            child: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
              ? FadeInImage.assetNetwork(
                  placeholder: defaultAvatarAsset,
                  image: profilePhotoUrl,
                  fit: BoxFit.cover,
                  width: 140, // double the radius
                  height: 140, // double the radius
                  imageErrorBuilder: (context, error, stackTrace) {
                    // This is the fallback if the network image fails to load
                    return Image.asset(
                      defaultAvatarAsset,
                      fit: BoxFit.cover,
                      width: 140,
                      height: 140,
                    );
                  },
                )
              : Image.asset( // This is the fallback if the URL is null/empty from the start
                  defaultAvatarAsset,
                  fit: BoxFit.cover,
                  width: 140,
                  height: 140,
                ),
          ),
        ),
        const SizedBox(height: 16),
        if (person.name != null && person.name!.isNotEmpty)
          Text(
            person.age != null ? '${person.name} • ${person.age}' : person.name!,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.yellow[700],
              shadows: [
                const Shadow(
                    blurRadius: 2.0,
                    color: Colors.black54,
                    offset: Offset(1, 1))
              ],
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.person});
  final Person person;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late final PageController _pageController;
  Timer? _carouselTimer;

  List<String> get _sliderImages {
    final images = <String>{};
    final person = widget.person;

    void addIfValid(String? url) {
      if (url != null && url.isNotEmpty) {
        images.add(url);
      }
    }

    addIfValid(person.profilePhoto);
    addIfValid(person.urlImage1);
    addIfValid(person.urlImage2);
    addIfValid(person.urlImage3);
    addIfValid(person.urlImage4);
    addIfValid(person.urlImage5);

    return images.toList();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _carouselTimer?.cancel();
    if (_sliderImages.length > 1 && mounted) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_pageController.hasClients) {
          int nextPage = _pageController.page!.toInt() + 1;
          if (nextPage >= _sliderImages.length) {
            nextPage = 0;
          }
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _sliderImages;
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: PageView.builder(
        controller: _pageController,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: images[index],
            fit: BoxFit.cover,
            placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
            const Center(child: Icon(Icons.broken_image)),
          );
        },
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.person,
    required this.profileController,
  });

  final Person person;
  final ProfileController profileController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Obx(() => _buildActionButton(
            isLoading: profileController.isTogglingFavorite.value,
            onPressed: () => profileController.toggleFavoriteStatus(person.uid!),
            activeIconAsset: 'images/full_fave.png',
            inactiveIconAsset: 'images/default_fave.png',
            isActive: profileController.isFavorite(person.uid!),
            tooltip: 'Favorite',
          )),
          Obx(() {
            final bool canMessage =
                profileController.getLikeStatus(person.uid!) == LikeStatus.mutualLike;
            return _buildActionButton(
              onPressed: canMessage
                  ? () => _launchWhatsApp(person.phoneNumber)
                  : () => Get.snackbar(
                "Message Unavailable",
                "You can only message users after a mutual like.",
              ),
              inactiveIconAsset: 'images/default_whatsapp.png',
              isActive: canMessage,
              tooltip: canMessage ? 'Message on WhatsApp' : 'Message (Requires Mutual Like)',
            );
          }),
          Obx(() {
            final likeStatus = profileController.getLikeStatus(person.uid!);
            return _buildActionButton(
              isLoading: profileController.isTogglingLike.value,
              onPressed: () => profileController.toggleLike(person.uid!),
              likeStatus: likeStatus,
              tooltip: 'Like',
            );
          }),
        ],
      ),
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
    LikeStatus? likeStatus,
  }) {
    if (isLoading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
      );
    }

    String iconAsset;
    Color? iconColor;

    if (likeStatus != null) {
      switch (likeStatus) {
        case LikeStatus.liked:
          iconAsset = 'images/half_like.png';
          iconColor = null;
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
      iconColor = isActive ? Colors.yellow[700] : Colors.blueGrey;
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
    final Uri whatsappUri = Uri.parse("https://wa.me/$phoneNumber");
    try {
      if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
        Get.snackbar("WhatsApp Error", "Could not open WhatsApp.");
      }
    } catch (e) {
      log('WhatsApp Launch Error', name: 'UserDetailsScreen', error: e);
      Get.snackbar("WhatsApp Error", "An error occurred trying to open WhatsApp.");
    }
  }
}

class _SocialLinks extends StatelessWidget {
  const _SocialLinks({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: "Social Media",
      details: {
        if (person.instagram?.isNotEmpty == true) "Instagram": "@${person.instagram!}",
        if (person.twitter?.isNotEmpty == true) "Twitter": "@${person.twitter!}",
      },
      onTapOverrides: {
        "Instagram": () => _launchUrlFromString(
            'https://instagram.com/${person.instagram!.replaceAll('@', '')}'),
        "Twitter": () => _launchUrlFromString(
            'https://twitter.com/${person.twitter!.replaceAll('@', '')}'),
      },
    );
  }

  Future<void> _launchUrlFromString(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not launch $urlString');
    }
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Map<String, String?> details;
  final Map<String, VoidCallback> onTapOverrides;
  final bool isBoolean;

  const _DetailSection({
    required this.title,
    required this.details,
    this.onTapOverrides = const {},
    this.isBoolean = false,
  });

  @override
  Widget build(BuildContext context) {
    final filteredDetails = Map.fromEntries(
        details.entries.where((e) => e.value != null && e.value!.isNotEmpty));

    if (filteredDetails.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.yellow[700]),
            ),
          if (title.isNotEmpty) const SizedBox(height: 12),
          ...filteredDetails.entries.map((entry) {
            final key = entry.key;
            final value = entry.value!;
            final onTap = onTapOverrides[key];

            Widget content = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    key,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blueGrey[200]),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    isBoolean ? (value == 'true' ? 'Yes' : 'No') : value,
                    style: TextStyle(
                        color: onTap != null ? Colors.blue : Colors.white),
                  ),
                ),
              ],
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: onTap != null
                  ? InkWell(onTap: onTap, child: content)
                  : content,
            );
          }),
        ],
      ),
    );
  }
}
