import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart' as model; // Import UserSettingsScreen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../accountSettingsScreen/user_settings_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  final String? userID;
  const UserDetailsScreen({super.key, this.userID});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  String _effectiveUserID = '';
  ProfileController? _profileController;
  late PageController _pageController;
  Timer? _carouselTimer;
  String? _currentAuthUserId; // Added for current user's ID

  // Loading states
  final RxBool _isLiking = false.obs;
  final RxBool _isFavoriting = false.obs;

  // CORRECTED Placeholder URLs:
  final String evePlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Feves_avatar.jpeg?alt=media&token=75b9c3f5-72c1-42db-be5c-471cc0d88c05';
  final String adamPlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Fadam_avatar.jpeg?alt=media&token=997423ec-96a4-42d6-aea8-c8cb80640ca0';
  final String genericPlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Fplaceholder_avatar.png?alt=media&token=98256561-2bac-4595-8e54-58a5c486a427'; // Assuming you have a generic one at this correct domain too


  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // Initialize _pageController here
    _currentAuthUserId = FirebaseAuth.instance.currentUser?.uid; // Initialize current user ID
    // Attempt to find ProfileController, but handle if not found (e.g., during tests or if not set up)
    try {
      // It's better to assign directly to _profileController if it's not final
      _profileController = Get.find<ProfileController>();
    } catch (e) {
      print(
          "UserDetailsScreen: ProfileController not found via Get.find(). This might be okay if userID is provided directly or in certain testing scenarios. Error: $e");
      // _profileController will remain null if not found
    }

    _determineEffectiveUserID(); // Determine the user ID to use

    // --- ADDED THIS SECTION -- -
    // Record the profile view after the User ID has been determined
    // and after the first frame has been built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure the widget is still mounted, profileController is available,
      // and we have an effectiveUserID to record.
      // The recordProfileView method itself will check if it's a self-view.
      if (mounted && _profileController != null && _effectiveUserID.isNotEmpty) {
        print(
            "DEBUG: UserDetailsScreen initState - Attempting to call recordProfileView for User ID: $_effectiveUserID");
        _profileController!.recordProfileView(_effectiveUserID);
      } else {
        if (_profileController == null) {
          print(
              "DEBUG: UserDetailsScreen initState - ProfileController is null, cannot record view.");
        }
        if (_effectiveUserID.isEmpty) {
          print(
              "DEBUG: UserDetailsScreen initState - EffectiveUserID is empty, cannot record view.");
        }
      }
    });
    // --- END ADDED SECTION ---
  }


  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll(List<String> images) {
    _carouselTimer?.cancel(); // Cancel any existing timer to prevent duplicates
    if (images.length > 1 && mounted) { // Only start if there's more than one image and widget is mounted
      _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!mounted) { // Check again if widget is still mounted before proceeding
          timer.cancel();
          return;
        }
        if (_pageController.hasClients) {
          int nextPage = _pageController.page!.toInt() + 1;
          if (nextPage >= images.length) {
            nextPage = 0; // Loop back to the first image
          }
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 700), // Smooth transition
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }


  Future<void> _signOutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to LoginScreen, ensuring it's a full replacement of the navigation stack
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      // Show a snackbar or log the error
      Get.snackbar('Error Signing Out', "An unexpected error occurred: ${e.toString()}");
      print("Error signing out: $e");
    }
  }

  void _determineEffectiveUserID() {
    // Priority: widget.userID > currentUser.uid from ProfileController > currentUser.uid from FirebaseAuth
    // This allows overriding the displayed profile via widget parameter.
    final String? directUserID = widget.userID;
    //final String? profileControllerUserID = _profileController?.currentUserProfile.value?.uid; // This line might cause issues if currentUserProfile is not guaranteed.
    final String? firebaseAuthUserID = FirebaseAuth.instance.currentUser?.uid;

    if (directUserID != null && directUserID.isNotEmpty) {
      _effectiveUserID = directUserID;
    //} else if (profileControllerUserID != null && profileControllerUserID.isNotEmpty) { // Using _currentAuthUserId which is directly from FirebaseAuth
    //  _effectiveUserID = profileControllerUserID;
    } else if (firebaseAuthUserID != null && firebaseAuthUserID.isNotEmpty) {
      _effectiveUserID = firebaseAuthUserID;
    } else {
      _effectiveUserID = ""; // Fallback to empty string if no ID is found
    }
     _currentAuthUserId = firebaseAuthUserID; // Ensure _currentAuthUserId is set based on FirebaseAuth for consistency

    if (_effectiveUserID.isEmpty) {
      print("UserDetailsScreen: Critical - Effective User ID is empty after determination. Cannot load profile.");
      // Potentially show an error message or navigate back if this state is critical
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted){
          Get.snackbar("Error", "User ID could not be determined. Cannot display profile.");
          if (Get.key.currentState?.canPop() == true) {
            Get.back();
          }
        }
      });
    }
  }


  List<String> _extractSliderImages(Map<String, dynamic> data, String? orientationForPlaceholder) {
    final List<String> images = [];
    String placeholderUrlToUse;
    final String? lowerOrientation = orientationForPlaceholder?.toLowerCase();

    if (lowerOrientation == 'eve') {
      placeholderUrlToUse = evePlaceholderUrl;
    } else if (lowerOrientation == 'adam') {
      placeholderUrlToUse = adamPlaceholderUrl;
    } else {
      placeholderUrlToUse = genericPlaceholderUrl;
    }

    for (int i = 1; i <= 5; i++) {
      String? imageUrl = data['urlImage$i'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        images.add(imageUrl);
      } else {
        images.add(placeholderUrlToUse); // Add placeholder if URL is null or empty
      }
    }
    // Start auto-scroll after images are loaded and widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) _startAutoScroll(images);
    });
    return images;
  }


  String _getDisplayImageUrl(String? mainProfilePhoto, String? orientation) {
    if (mainProfilePhoto != null && mainProfilePhoto.isNotEmpty) {
      return mainProfilePhoto;
    }
    // Determine placeholder based on orientation
    final String? lowerOrientation = orientation?.toLowerCase();
    if (lowerOrientation == 'eve') return evePlaceholderUrl;
    if (lowerOrientation == 'adam') return adamPlaceholderUrl;
    return genericPlaceholderUrl; // Default generic placeholder
  }

  // MODIFIED _buildDetailRow to include onTap and adjust styling for links
  Widget _buildDetailRow(BuildContext context, String label, String? value, {bool isLink = false, VoidCallback? onTap}) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: onTap != null ? Colors.blueAccent : Colors.blueGrey, // Make link color distinct
                  decoration: isLink ? TextDecoration.underline : null,
                  decorationColor: onTap != null ? Colors.blueAccent : Colors.blueGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanDetailRow(BuildContext context, String label, bool? value) {
    if (value == null) return const SizedBox.shrink();
    return _buildDetailRow(context, label, value ? "Yes" : "No");
  }

  // ADDED _launchUrlFromString method
  Future<void> _launchUrlFromString(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not launch $urlString');
      print('Could not launch $urlString');
    }
  }


  Widget _buildImageCarousel(List<String> sliderImages, String? orientationForPlaceholder) {
    List<String> imagesToShow = sliderImages;

    // Ensure there are always 5 images for the carousel, using placeholders if necessary
    if (imagesToShow.isEmpty) {
      String fallbackPlaceholder = _getDisplayImageUrl(null, orientationForPlaceholder);
      imagesToShow = List.generate(5, (_) => fallbackPlaceholder);
    } else if (imagesToShow.length != 5) {
      // This case should ideally be handled by _extractSliderImages to always return 5
      print("UserDetailsScreen: WARNING - sliderImages length is ${imagesToShow.length}. Adjusting to 5.");
      String fallbackPlaceholder = _getDisplayImageUrl(null, orientationForPlaceholder);
      List<String> adjustedImages = List.from(imagesToShow); // Create a modifiable list
      while(adjustedImages.length < 5) {
        adjustedImages.add(fallbackPlaceholder);
      }
      imagesToShow = adjustedImages.sublist(0,5); // Ensure exactly 5
    }


    return Container(
        height: MediaQuery.of(context).size.height * 0.4, // Responsive height
        margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0), // Consistent margin
        clipBehavior: Clip.antiAlias, // Apply rounded corners to child
        decoration: BoxDecoration(
          color: Colors.grey[300], // Background for the carousel area
          borderRadius: BorderRadius.circular(12.0), // Rounded corners
        ),
        child: PageView.builder(
          controller: _pageController,
          itemCount: imagesToShow.length, // Should always be 5
          itemBuilder: (context, index) {
            return Image.network(
              imagesToShow[index],
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.blueGrey, // Consistent color
                ));
              },
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                // Log error and display a fallback placeholder
                print("Error loading image in carousel: ${imagesToShow[index]}, Exception: $exception");
                // Fallback to a generic placeholder or orientation-specific one
                return Image.network(_getDisplayImageUrl(null, orientationForPlaceholder), fit: BoxFit.cover);
              },
            );
          },
        )
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 10.0), // Consistent padding
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey, // Consistent color
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Consistent AppBar styling
    final appBarTitleTextStyle = const TextStyle(color: Colors.blueGrey, fontSize: 20, fontWeight: FontWeight.bold);
    final appBarIconTheme = const IconThemeData(color: Colors.blueGrey);
    final appBarBackgroundColor = Colors.black54; // Slightly transparent black

    if (_effectiveUserID.isEmpty) {
      // This check is important. If _effectiveUserID is empty, StreamBuilder might not behave as expected.
      // It's better to show a clear message or a loading indicator if the ID isn't ready.
      return Scaffold(
        appBar: AppBar(title: const Text("Profile Information"), centerTitle: true, titleTextStyle: appBarTitleTextStyle, iconTheme: appBarIconTheme, backgroundColor: appBarBackgroundColor),
        body: SafeArea( // MODIFIED: Added SafeArea
          child: const Center(child: Text("User ID not available. Cannot display profile.", style: TextStyle(fontSize: 18, color: Colors.blueGrey))),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("users").doc(_effectiveUserID).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              appBar: AppBar(title: const Text("Loading Profile..."), centerTitle: true, titleTextStyle: appBarTitleTextStyle, iconTheme: appBarIconTheme, backgroundColor: appBarBackgroundColor),
              body: SafeArea( // MODIFIED: Added SafeArea
                child: const Center(child: CircularProgressIndicator(color: Colors.blueGrey)),
              ));
        }

        if (snapshot.hasError) {
          print("Error in UserDetailsScreen StreamBuilder: ${snapshot.error}");
          return Scaffold(
              appBar: AppBar(title: const Text("Error"), centerTitle: true, titleTextStyle: appBarTitleTextStyle, iconTheme: appBarIconTheme, backgroundColor: appBarBackgroundColor),
              body: SafeArea( // MODIFIED: Added SafeArea
                child: const Center(child: Text("Error loading profile.", style: TextStyle(color: Colors.red, fontSize: 18))),
              ));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // More specific message if user ID is available but profile not found
          String message = _effectiveUserID.isNotEmpty // Should always be true here due to the check above, but good for safety
              ? "Profile for user ID '$_effectiveUserID' not found."
              : "Profile not found."; // This case should ideally not be reached if _effectiveUserID check is robust
          return Scaffold(
              appBar: AppBar(title: const Text("Profile Not Found"), centerTitle: true, titleTextStyle: appBarTitleTextStyle, iconTheme: appBarIconTheme, backgroundColor: appBarBackgroundColor),
              body: SafeArea( // MODIFIED: Added SafeArea
                child: Center(child: Text(message, style: const TextStyle(fontSize: 18, color: Colors.blueGrey), textAlign: TextAlign.center,)),
              ));
        }

        // Data is available, proceed to build the profile UI
        final userDoc = snapshot.data!;
        final user = model.Person.fromDataSnapshot(userDoc); // Use aliased model.Person
        final userDataMap = userDoc.data() as Map<String, dynamic>; // Ensure data is a map
        final List<String> sliderImages = _extractSliderImages(userDataMap, user.orientation);

        // Initialize favorite and like status from ProfileController
        if (_profileController != null && _currentAuthUserId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) { // Check if the widget is still in the tree
              final isCurrentlyFavorited = _profileController!.favoritedUserIds.contains(user.uid);
              if (user.isFavorite.value != isCurrentlyFavorited) {
                user.isFavorite.value = isCurrentlyFavorited;
              }
              // Assuming updateInitialLikeStatusForPerson is public in ProfileController
              _profileController!.updateInitialLikeStatusForPerson(user, _currentAuthUserId!);
            }
          });
        }

        final bool isCurrentUserProfile = (_currentAuthUserId == _effectiveUserID);

        // If it's not the current user's profile, obscure the details.
        //bool shouldObscureDetails = !isCurrentUserProfile; // This variable seems unused later, can be removed if not needed

        // Determine if the profile being viewed is an 'Adam' type profile
        final bool isAdamProfile = user.orientation?.toLowerCase() == 'adam';

        return Scaffold(
          appBar: AppBar(
            title: Text(isCurrentUserProfile ? "My Profile" : (user.name ?? "User Profile")), // Dynamic title
            centerTitle: true,
            titleTextStyle: appBarTitleTextStyle,
            iconTheme: appBarIconTheme,
            backgroundColor: appBarBackgroundColor,
            actions: <Widget>[
              if (isCurrentUserProfile) ...[
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.yellow[700]), // Consistent icon color
                  tooltip: 'Settings',
                  onPressed: () {
                    // Navigate to UserSettingsScreen, ensuring it exists and is correctly imported
                    Get.to(() => const UserSettingsScreen());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.blueGrey), // Consistent icon color
                  tooltip: 'Logout',
                  onPressed: _signOutUser,
                ),
              ]
            ],
          ),
          body: SafeArea( // MODIFIED: Added SafeArea
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(
                  'images/userDetailsBackground.jpeg', // Background image
                  fit: BoxFit.cover,
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Main Profile Image as a large CircleAvatar
                      Center(
                        child: CircleAvatar(
                          radius: 70, // Larger radius
                          backgroundColor: Colors.grey.shade700,
                          backgroundImage: NetworkImage(_getDisplayImageUrl(user.profilePhoto, user.orientation)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name and Age Section
                      if (user.name != null && user.name!.isNotEmpty)
                        Center(
                          child: Text(
                            user.age != null ? '${user.name} ⸰ ${user.age}' : user.name!,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow[700],
                              shadows: [Shadow(blurRadius: 2.0, color: Colors.black.withOpacity(0.5), offset: const Offset(1,1))],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 20),


                      // Image Carousel
                      _buildImageCarousel(sliderImages, user.orientation),
                      const SizedBox(height: 24),
                      
                      // --- ACTION BUTTONS ROW --- 
                      if (!isCurrentUserProfile && _profileController != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Favorite Button
                              // Favorite Button
                              Obx(() => IconButton(
                                icon: _isFavoriting.value // Check the loading state
                                    ? SizedBox( // If loading, show CircularProgressIndicator
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                                    ),
                                  ),
                                )
                                    : Image.asset( // If not loading, show the image
                                  user.isFavorite.value
                                      ? 'images/full_fave.png'
                                      : 'images/default_fave.png',
                                  width: 40,
                                  height: 40,
                                  color: user.isFavorite.value ? Colors.yellow[700] : Colors.blueGrey,
                                ),
                                onPressed: _isFavoriting.value
                                    ? null
                                    : () async {
                                  if (user.uid != null && _profileController != null) {
                                    _isFavoriting.value = true;
                                    try {
                                      final newFavStatus = await _profileController!.toggleFavoriteStatus(user.uid!);
                                      if (mounted) user.isFavorite.value = newFavStatus;
                                    } catch (e) {
                                      Get.snackbar("Error", "Failed to update favorite: ${e.toString()}", snackPosition: SnackPosition.BOTTOM);
                                    } finally {
                                      _isFavoriting.value = false;
                                    }
                                  } else {
                                    Get.snackbar("Error", "Cannot update favorite: User ID or controller missing.", snackPosition: SnackPosition.BOTTOM);
                                  }
                                },
                                tooltip: 'Favorite',
                              )),

                              // Message Button
                              Obx(() {
                                bool canMessage = user.likeStatus.value == model.LikeStatus.mutualLike;
                                return IconButton(
                                  icon: Image.asset(
                                    'images/default_whatsapp.png',
                                    width: 40, height: 40,
                                    color: canMessage ? Colors.greenAccent : Colors.blueGrey.withOpacity(0.7),
                                  ),
                                  onPressed: () async {
                                    if (canMessage) {
                                      final String? userPhoneNumber = user.phoneNumber; 
                                      if (userPhoneNumber != null && userPhoneNumber.isNotEmpty) {
                                        String formattedPhoneNumber = userPhoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
                                        if (!formattedPhoneNumber.startsWith('+') && RegExp(r'^\d+$').hasMatch(formattedPhoneNumber)) {
                                          // Optionally prepend country code
                                        } else if (!formattedPhoneNumber.startsWith('+')) {
                                           Get.snackbar("WhatsApp Warning", "Phone number format may not be ideal. Attempting anyway.", backgroundColor: Colors.orangeAccent);
                                        }
                                        await _launchUrlFromString("https://api.whatsapp.com/send?phone=$formattedPhoneNumber");
                                      } else {
                                        Get.snackbar("Message Error", "User's phone number is not available.");
                                      }
                                    } else {
                                      Get.snackbar("Message Unavailable", "You can only message users after a mutual like.", snackPosition: SnackPosition.TOP);
                                    }
                                  },
                                  tooltip: canMessage ? 'Message on WhatsApp' : 'Message (Requires Mutual Like)',
                                );
                              }),

                              // Like Button
                              Obx(() {
                                String likeIconAsset;
                                Color? likeIconColor;
                                switch (user.likeStatus.value) {
                                  case model.LikeStatus.currentUserLiked:
                                  case model.LikeStatus.targetUserLikedCurrentUser:
                                    likeIconAsset = 'images/half_like.png';
                                    likeIconColor = null; // Or specific color for half like
                                    break;
                                  case model.LikeStatus.mutualLike:
                                    likeIconAsset = 'images/full_like.png';
                                    likeIconColor = Colors.yellow[700];
                                    break;
                                  case model.LikeStatus.none:
                                  default:
                                    likeIconAsset = 'images/default_like.png';
                                    likeIconColor = Colors.blueGrey;
                                    break;
                                }
                                return IconButton(
                                  icon: _isLiking.value // Check the loading state
                                      ? SizedBox( // If loading, show CircularProgressIndicator
                                          width: 40,
                                          height: 40,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                                            ),
                                          ),
                                        )
                                      : Image.asset( // If not loading, show the image
                                          likeIconAsset,
                                          width: 40,
                                          height: 40,
                                          color: likeIconColor,
                                        ),
                                  onPressed: _isLiking.value
                                      ? null
                                      : () async {
                                    if (user.uid != null && _profileController != null) {
                                      _isLiking.value = true;
                                      try {
                                        final newLikeStatus = await _profileController!.toggleLike(user.uid!);
                                        if (mounted) user.likeStatus.value = newLikeStatus;
                                      } catch (e) {
                                        Get.snackbar("Error", "Failed to process like: ${e.toString()}", snackPosition: SnackPosition.BOTTOM);
                                      } finally {
                                        _isLiking.value = false;
                                      }
                                    } else {
                                      Get.snackbar("Error", "Cannot process like: User ID or controller missing.", snackPosition: SnackPosition.BOTTOM);
                                    }
                                  },

                                  tooltip: 'Like',
                                );
                              }),
                            ],
                          ),
                        ),
                      // --- END ACTION BUTTONS ROW ---

                      // User Details Section
                      _buildSectionTitle(context, "About"),
                      _buildDetailRow(context, "Profession", user.profession),
                      if (user.orientation?.toLowerCase() == 'eve' && user.professionalVenues != null && user.professionalVenues!.isNotEmpty)
                        _buildDetailRow(context, "Venues", user.professionalVenues!.join(", ")),
                      if (user.orientation?.toLowerCase() == 'eve' && user.otherProfessionalVenue != null && user.otherProfessionalVenue!.isNotEmpty)
                        _buildDetailRow(context, "Other Venue", user.otherProfessionalVenue),

                      _buildDetailRow(context, "Location", [user.city, user.province, user.country].where((s) => s != null && s.isNotEmpty).join(", ")),
                      _buildDetailRow(context, "Ethnicity", user.ethnicity),

                      // ADDED Tappable Instagram and Twitter links for Eve profiles
                      if (user.orientation?.toLowerCase() == 'eve') ...[
                        if (user.instagram != null && user.instagram!.isNotEmpty)
                          _buildDetailRow(
                            context,
                            "Instagram",
                            "@${user.instagram!}", // Display with @ symbol
                            isLink: true,
                            onTap: () => _launchUrlFromString('https://instagram.com/${user.instagram!.replaceAll('@', '')}'), // Remove @ if present for URL
                          ),
                        if (user.twitter != null && user.twitter!.isNotEmpty)
                          _buildDetailRow(
                            context,
                            "Twitter",
                            "@${user.twitter!}", // Display with @ symbol
                            isLink: true,
                            onTap: () => _launchUrlFromString('https://twitter.com/${user.twitter!.replaceAll('@', '')}'), // Remove @ if present for URL
                          ),
                      ],

                      //Appearance
                      if (!isAdamProfile || isCurrentUserProfile) ...[
                        if (!isAdamProfile) ...[
                          _buildSectionTitle(context, "Appearance"),
                          _buildDetailRow(context, "Height", user.height),
                          _buildDetailRow(context, "Body Type", user.bodyType),


                          _buildSectionTitle(context, "Background"),
                          _buildDetailRow(context, "Nationality", user.nationality),
                          _buildDetailRow(context, "Languages Spoken", user.languages),
                        ],
                      ],

                      //Looking for/available for
                      _buildSectionTitle(context, "Looking/Available For"),
                      _buildBooleanDetailRow(context, "Breakfast", user.lookingForBreakfast),
                      _buildBooleanDetailRow(context, "Lunch", user.lookingForLunch),
                      _buildBooleanDetailRow(context, "Dinner", user.lookingForDinner),
                      _buildBooleanDetailRow(context, "Long Term", user.lookingForLongTerm),



                      // Lifestyle Section
                      _buildSectionTitle(context, "Lifestyle"),
                      _buildBooleanDetailRow(context, "Drinks", user.drinkSelection),
                      _buildBooleanDetailRow(context, "Smokes", user.smokeSelection),
                      _buildBooleanDetailRow(context, "Eats Meat", user.meatSelection),
                      _buildBooleanDetailRow(context, "Greek Life", user.greekSelection),
                      _buildBooleanDetailRow(context, "Enjoys Hosting", user.hostSelection),
                      _buildBooleanDetailRow(context, "Travels", user.travelSelection),
                      if(user.income != null && user.income!.isNotEmpty && !isAdamProfile)
                        _buildDetailRow(context, "Income Range", user.income),


                      // Obscured Details Section (if applicable)
                      // if (shouldObscureDetails && isAdamProfile) ...[
                      //   const SizedBox(height: 20),
                      //   Center(
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(16.0),
                      //       child: Text(
                      //         "Further details are revealed upon mutual connection.",
                      //         textAlign: TextAlign.center,
                      //         style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      //           color: Colors.orangeAccent,
                      //           fontStyle: FontStyle.italic,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ],
                      const SizedBox(height: 70), // Space for floating action buttons if any
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
