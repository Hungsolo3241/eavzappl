import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart' as model;// Import UserSettingsScreen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../accountSettingsScreen/user_settings_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  final String? userID;
  const UserDetailsScreen({super.key, this.userID});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  model.Person? _user;
  List<String> _sliderImages = [];
  bool _isLoading = true;
  bool _userFound = true;
  String _effectiveUserID = '';

  ProfileController? _profileController;

  late PageController _pageController;
  Timer? _carouselTimer;

  final String evePlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Feves_avatar.jpeg?alt=media&token=75b9c3f5-72c1-42db-be5c-471cc0d88c05';
  final String adamPlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Fadam_avatar.jpeg?alt=media&token=997423ec-96a4-42d6-aea8-c8cb80640ca0';
  final String genericPlaceholderUrl = 'https://via.placeholder.com/400?text=No+Image';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    try {
      _profileController = Get.find<ProfileController>();
    } catch (e) {
      print("UserDetailsScreen: Could not find ProfileController. Obscuring logic might not work as expected. Error: $e");
    }
    _determineUserIDAndFetchData().then((_) {
      if (mounted && _userFound && _sliderImages.isNotEmpty) {
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _carouselTimer?.cancel();
    if (!mounted || _sliderImages.isEmpty) return;

    _carouselTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || !_pageController.hasClients || _pageController.page == null) {
        timer.cancel();
        return;
      }
      int nextPage = _pageController.page!.round() + 1;
      if (nextPage >= _sliderImages.length) {
        nextPage = 0;
      }
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _signOutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      print("Error signing out: $e");
      Get.snackbar(
        "Logout Failed",
        "An error occurred while trying to sign out. Please try again.",
        backgroundColor: Colors.blueGrey,
        colorText: Colors.green,
      );
    }
  }

  Future<void> _determineUserIDAndFetchData() async {
    String? idToFetch = widget.userID;
    if (idToFetch == null || idToFetch.isEmpty) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        idToFetch = currentUser.uid;
      } else {
        if (mounted) setState(() { _isLoading = false; _userFound = false; });
        return;
      }
    }
    _effectiveUserID = idToFetch;
    if (_effectiveUserID.isEmpty) {
      if (mounted) setState(() { _isLoading = false; _userFound = false; });
      return;
    }
    await _retrieveUserData(_effectiveUserID);
  }

  Future<void> _retrieveUserData(String userIDToFetch) async {
    if (userIDToFetch.isEmpty) {
      if (mounted) setState(() { _isLoading = false; _userFound = false; });
      return;
    }
    if (mounted) setState(() { _isLoading = true; });
    try {
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userIDToFetch)
          .get();

      if (mounted && snapshot.exists && snapshot.data() != null) {
        _user = model.Person.fromDataSnapshot(snapshot);
        final data = snapshot.data() as Map<String, dynamic>;
        List<String> images = [];
        String placeholderUrlToUse;
        final String? orientation = _user?.orientation?.toLowerCase();
        if (orientation == 'eve') {
          placeholderUrlToUse = evePlaceholderUrl;
        } else if (orientation == 'adam') {
          placeholderUrlToUse = adamPlaceholderUrl;
        } else {
          placeholderUrlToUse = genericPlaceholderUrl;
        }
        for (int i = 1; i <= 5; i++) {
          String? imageUrl = data['urlImage$i'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            images.add(imageUrl);
          } else {
            images.add(placeholderUrlToUse);
          }
        }
        _sliderImages = images;
        _userFound = true;
      } else {
        _userFound = false;
      }
    } catch (e) {
      print("Error retrieving user data for ID $userIDToFetch: $e");
      _userFound = false;
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  String _getDisplayImageUrl(String? mainProfilePhoto, String? orientation) {
    if (mainProfilePhoto != null && mainProfilePhoto.isNotEmpty) {
      return mainProfilePhoto;
    }
    final String? lowerOrientation = orientation?.toLowerCase();
    if (lowerOrientation == 'eve') return evePlaceholderUrl;
    if (lowerOrientation == 'adam') return adamPlaceholderUrl;
    return genericPlaceholderUrl;
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value, {bool isLink = false}) {
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
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
                decoration: isLink ? TextDecoration.underline : null,
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

  Widget _buildImageCarousel() {
    List<String> imagesToShow = _sliderImages;
    if (imagesToShow.length != 5) {
      print("UserDetailsScreen: WARNING - _sliderImages length is not 5. Forcing 5 placeholders.");
      String fallbackPlaceholder = _getDisplayImageUrl(null, _user?.orientation);
      imagesToShow = List.generate(5, (_) => fallbackPlaceholder);
    }

    return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: PageView.builder(
          controller: _pageController,
          itemCount: imagesToShow.length,
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
                ));
              },
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                print("Error loading image in carousel: ${imagesToShow[index]}, Exception: $exception");
                return Image.network(_getDisplayImageUrl(null, _user?.orientation), fit: BoxFit.cover);
              },
            );
          },
        )
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 10.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitleTextStyle = const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold);
    final appBarIconTheme = const IconThemeData(color: Colors.green);
    final appBarBackgroundColor = Colors.black54;

    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(
              title: const Text("Loading Profile..."), centerTitle: true,
              titleTextStyle: appBarTitleTextStyle, iconTheme: appBarIconTheme, backgroundColor: appBarBackgroundColor),
          body: const Center(child: CircularProgressIndicator(color: Colors.green)));
    }

    if (!_userFound || _user == null) {
      String message = "User details could not be loaded.";
      if (FirebaseAuth.instance.currentUser == null && widget.userID == null) {
        message = "Please log in to see your profile.";
      } else if (!_userFound && _effectiveUserID.isNotEmpty) {
        message = "Profile for user ID '$_effectiveUserID' not found.";
      } else if (!_userFound) {
        message = "User not found.";
      }
      return Scaffold(
          appBar: AppBar(
              title: const Text("Profile Information"), centerTitle: true,
              titleTextStyle: appBarTitleTextStyle, iconTheme: appBarIconTheme, backgroundColor: appBarBackgroundColor),
          body: Center(
            child: Text(
              message,
              style: const TextStyle(fontSize: 18, color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ));
    }

    final user = _user!;
    final bool isCurrentUserProfile = (widget.userID == null || widget.userID!.isEmpty || widget.userID == FirebaseAuth.instance.currentUser?.uid) &&
        FirebaseAuth.instance.currentUser?.uid == _effectiveUserID;

    bool shouldObscureDetails = false;
    if (!isCurrentUserProfile && _profileController?.currentUserProfile.value != null) {
      final String? viewerOrientation = _profileController!.currentUserProfile.value!.orientation?.toLowerCase();
      final String? viewedProfileOrientation = user.orientation?.toLowerCase();
      if (viewerOrientation == 'adam' && viewedProfileOrientation == 'eve') {
        shouldObscureDetails = true;
      }
    }

    final bool isAdamProfile = user.orientation?.toLowerCase() == 'adam';

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUserProfile ? "My Profile" : (user.name ?? "User Profile")),
        centerTitle: true,
        titleTextStyle: appBarTitleTextStyle,
        iconTheme: appBarIconTheme, // For back arrow if not current user's profile
        backgroundColor: appBarBackgroundColor,
        actions: <Widget>[
          if (isCurrentUserProfile) ...[ // Use spread operator for multiple conditional widgets
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.green), // Settings Icon
              tooltip: 'Settings',
              onPressed: () {
                Get.to(() => const UserSettingsScreen()); // Navigate to UserSettingsScreen
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.green),
              tooltip: 'Logout',
              onPressed: () {
                _signOutUser();
              },
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildImageCarousel(),
            _buildSectionTitle(context, "Personal Information"),
            _buildDetailRow(context, "Name", user.name),
            if (user.age != null) _buildDetailRow(context, "Age", user.age.toString()),
            _buildDetailRow(context, "Gender", user.gender),
            _buildDetailRow(context, "Email", shouldObscureDetails ? "Protected" : user.email),
            _buildDetailRow(context, "Phone", shouldObscureDetails ? "Protected" : user.phoneNumber),
            _buildDetailRow(context, "Country", user.country),
            _buildDetailRow(context, "Province", user.province),
            _buildDetailRow(context, "City", user.city),
            _buildDetailRow(context, "Profession", user.profession),
            _buildDetailRow(context, "Income", user.income),
            if (user.publishedDateTime != null)
              _buildDetailRow(context, "Joined", DateFormat.yMMMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(user.publishedDateTime!))),

            _buildSectionTitle(context, "Looking/Available For"),
            _buildBooleanDetailRow(context, "Breakfast", user.lookingForBreakfast),
            _buildBooleanDetailRow(context, "Lunch", user.lookingForLunch),
            _buildBooleanDetailRow(context, "Dinner", user.lookingForDinner),
            _buildBooleanDetailRow(context, "Long Term", user.lookingForLongTerm),

            if (!isAdamProfile) ...[
              _buildSectionTitle(context, "Appearance"),
              _buildDetailRow(context, "Height", user.height),
              _buildDetailRow(context, "Body Type", user.bodyType),
              _buildBooleanDetailRow(context, "Drinks Alcohol", user.drinkSelection),
              _buildBooleanDetailRow(context, "Smokes", user.smokeSelection),
              _buildBooleanDetailRow(context, "Likes Meat", user.meatSelection),
              _buildBooleanDetailRow(context, "Likes Greek", user.greekSelection),
              _buildBooleanDetailRow(context, "Can Host", user.hostSelection),
              _buildBooleanDetailRow(context, "Able to Travel", user.travelSelection),
              if (user.professionalVenues != null && user.professionalVenues!.isNotEmpty)
                _buildDetailRow(context, "Professional Venues", user.professionalVenues!.join(", ")),
              _buildDetailRow(context, "Private Venue", user.otherProfessionalVenue),
            ],

            if (!isAdamProfile) ...[
              _buildSectionTitle(context, "Background"),
              _buildDetailRow(context, "Ethnicity", user.ethnicity),
              _buildDetailRow(context, "Nationality", user.nationality),
              _buildDetailRow(context, "Languages", user.languages),
            ],

            if (!isAdamProfile) ...[
              _buildSectionTitle(context, "Social Media"),
              _buildDetailRow(context, "Instagram", user.instagram, isLink: true),
              _buildDetailRow(context, "Twitter", user.twitter, isLink: true),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
