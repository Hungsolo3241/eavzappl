import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/controllers/profile_controller.dart'; // Import ProfileController
import 'package:eavzappl/models/person.dart' as model; // aliased to avoid conflict
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import Get for Get.find
import 'package:intl/intl.dart';

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

  final String evePlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Feves_avatar.jpeg?alt=media&token=75b9c3f5-72c1-42db-be5c-471cc0d88c05';
  final String adamPlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Fadam_avatar.jpeg?alt=media&token=997423ec-96a4-42d6-aea8-c8cb80640ca0';
  final String genericPlaceholderUrl = 'https://via.placeholder.com/400?text=No+Image';

  // Lazy initialization for ProfileController
  ProfileController? _profileController;

  @override
  void initState() {
    super.initState();
    // It's generally safer to ensure GetX bindings are ready if finding immediately.
    // However, ProfileController is likely put by an earlier screen (SwipingScreen or HomeScreen).
    // If there's a risk of it not being ready, consider WidgetsBinding.instance.addPostFrameCallback
    try {
      _profileController = Get.find<ProfileController>();
    } catch (e) {
      print("UserDetailsScreen: Could not find ProfileController. Obscuring logic might not work as expected. Error: $e");
      // Proceed without it, obscuring logic will default to not obscuring based on viewer.
    }
    _determineUserIDAndFetchData();
  }

  Future<void> _determineUserIDAndFetchData() async {
    String? idToFetch = widget.userID;
    print("UserDetailsScreen: Initial widget.userID = ${widget.userID}");

    if (idToFetch == null || idToFetch.isEmpty) {
      print("UserDetailsScreen: widget.userID is null or empty, attempting to get current user.");
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        idToFetch = currentUser.uid;
        print("UserDetailsScreen: Current user found. UID = $idToFetch");
      } else {
        setState(() {
          _isLoading = false;
          _userFound = false;
        });
        print("UserDetailsScreen: CRITICAL - No userID provided and no current user logged in (currentUser is null).");
        return;
      }
    } else {
      print("UserDetailsScreen: Using provided widget.userID = $idToFetch");
    }

    if (idToFetch == null || idToFetch.isEmpty) {
      print("UserDetailsScreen: CRITICAL - idToFetch is null or empty before assigning to _effectiveUserID.");
      setState(() { _isLoading = false; _userFound = false; });
      return;
    }
    _effectiveUserID = idToFetch;
    if (_effectiveUserID.isEmpty) {
      print("UserDetailsScreen: CRITICAL - _effectiveUserID is empty before calling _retrieveUserData.");
      setState(() { _isLoading = false; _userFound = false; });
      return;
    }
    _retrieveUserData(_effectiveUserID);
  }

  Future<void> _retrieveUserData(String userIDToFetch) async {
    if (userIDToFetch.isEmpty) {
      print("UserDetailsScreen: CRITICAL - Attempted to retrieve user data with an empty userIDToFetch.");
      setState(() { _isLoading = false; _userFound = false; });
      return;
    }
    setState(() { _isLoading = true; });
    try {
      print("UserDetailsScreen: Retrieving user data for ID: $userIDToFetch");
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userIDToFetch)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        print("UserDetailsScreen: Document found for ID: $userIDToFetch");
        _user = model.Person.fromDataSnapshot(snapshot);
        final data = snapshot.data() as Map<String, dynamic>;
        List<String> images = [];
        for (int i = 1; i <= 5; i++) {
          if (data['urlImage$i'] != null && (data['urlImage$i'] as String).isNotEmpty) {
            images.add(data['urlImage$i'] as String);
          }
        }
        _sliderImages = images;
        _userFound = true;
      } else {
        _userFound = false;
        print("UserDetailsScreen: User document not found for ID: $userIDToFetch");
      }
    } catch (e) {
      print("Error retrieving user data for ID $userIDToFetch: $e");
      _userFound = false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDisplayImageUrl(String? mainProfilePhoto, String? orientation) {
    if (mainProfilePhoto != null && mainProfilePhoto.isNotEmpty) {
      return mainProfilePhoto;
    }
    if (orientation == 'eve') return evePlaceholderUrl;
    if (orientation == 'adam') return adamPlaceholderUrl;
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
          Text('$label: ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isLink ? Colors.blue : null,
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
    if (imagesToShow.isEmpty && _user?.profilePhoto != null && _user!.profilePhoto!.isNotEmpty) {
      imagesToShow = [_getDisplayImageUrl(_user!.profilePhoto, _user!.orientation)];
    } else if (imagesToShow.isEmpty) {
      imagesToShow = [_getDisplayImageUrl(null, _user?.orientation)];
    }
    return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        color: Colors.grey[300],
        child: imagesToShow.isNotEmpty
            ? PageView.builder(
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
            : Center(child: Icon(Icons.person, size: 100, color: Colors.grey[500])));
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0, bottom: 10.0),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
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
          body: const Center(child: CircularProgressIndicator()));
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
          body: Center(child: Text(message, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center)));
    }

    final user = _user!;
    final bool isCurrentUserProfile = (widget.userID == null || widget.userID!.isEmpty || widget.userID == FirebaseAuth.instance.currentUser?.uid) &&
        FirebaseAuth.instance.currentUser?.uid == _effectiveUserID;

    // Obscuring Logic
    bool shouldObscureDetails = false;
    if (!isCurrentUserProfile && _profileController?.currentUserProfile.value != null) {
      final String? viewerOrientation = _profileController!.currentUserProfile.value!.orientation?.toLowerCase();
      final String? viewedProfileOrientation = user.orientation?.toLowerCase();
      if (viewerOrientation == 'adam' && viewedProfileOrientation == 'eve') {
        shouldObscureDetails = true;
      }
    }
    if (shouldObscureDetails) {
      print("UserDetailsScreen: Obscuring email/phone for Adam viewing Eve's profile.");
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUserProfile ? "My Profile" : (user.name ?? "User Profile")),
        centerTitle: true,
        titleTextStyle: appBarTitleTextStyle,
        iconTheme: appBarIconTheme,
        backgroundColor: appBarBackgroundColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildImageCarousel(),
            _buildSectionTitle(context, "Personal Information"),
            _buildDetailRow(context, "Name", user.name),
            _buildDetailRow(context, "Username", user.username),
            if (user.age != null) _buildDetailRow(context, "Age", user.age.toString()),
            _buildDetailRow(context, "Gender", user.gender),
            _buildDetailRow(context, "Orientation", user.orientation),
            _buildDetailRow(context, "Email", shouldObscureDetails ? "Protected" : user.email),
            _buildDetailRow(context, "Phone", shouldObscureDetails ? "Protected" : user.phoneNumber),
            _buildDetailRow(context, "Country", user.country),
            _buildDetailRow(context, "Province", user.province),
            _buildDetailRow(context, "City", user.city),
            if (user.publishedDateTime != null)
              _buildDetailRow(context, "Joined", DateFormat.yMMMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(user.publishedDateTime!))),
            _buildSectionTitle(context, "Looking For"),
            _buildBooleanDetailRow(context, "Breakfast", user.lookingForBreakfast),
            _buildBooleanDetailRow(context, "Lunch", user.lookingForLunch),
            _buildBooleanDetailRow(context, "Dinner", user.lookingForDinner),
            _buildBooleanDetailRow(context, "Long Term", user.lookingForLongTerm),
            _buildSectionTitle(context, "Appearance"),
            _buildDetailRow(context, "Height", user.height),
            _buildDetailRow(context, "Body Type", user.bodyType),
            _buildDetailRow(context, "Profession", user.profession),
            _buildDetailRow(context, "Income", user.income),
            _buildBooleanDetailRow(context, "Drinks Alcohol", user.drinkSelection),
            _buildBooleanDetailRow(context, "Smokes", user.smokeSelection),
            _buildBooleanDetailRow(context, "Eats Meat", user.meatSelection),
            _buildBooleanDetailRow(context, "Likes Greek Food", user.greekSelection),
            _buildBooleanDetailRow(context, "Can Host", user.hostSelection),
            _buildBooleanDetailRow(context, "Enjoys Traveling", user.travelSelection),
            if (user.professionalVenues != null && user.professionalVenues!.isNotEmpty)
              _buildDetailRow(context, "Professional Venues", user.professionalVenues!.join(", ")),
            _buildDetailRow(context, "Other Venue", user.otherProfessionalVenue),
            _buildSectionTitle(context, "Background"),
            _buildDetailRow(context, "Ethnicity", user.ethnicity),
            _buildDetailRow(context, "Nationality", user.nationality),
            _buildDetailRow(context, "Languages", user.languages),
            _buildSectionTitle(context, "Social Media"),
            _buildDetailRow(context, "Instagram", user.instagram, isLink: true),
            _buildDetailRow(context, "Twitter", user.twitter, isLink: true),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
