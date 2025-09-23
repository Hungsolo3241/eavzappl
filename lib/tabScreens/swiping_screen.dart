// GEMINI_WRITE_TEST
import 'package:cached_network_image/cached_network_image.dart'; // Added import
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/filter_preferences.dart';
import 'package:eavzappl/models/person.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart'; // Import UserDetailsScreen
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SwipingScreen extends StatefulWidget {
  const SwipingScreen({super.key});

  @override
  State<SwipingScreen> createState() => _SwipingScreenState();
}

class _SwipingScreenState extends State<SwipingScreen> {
  final ProfileController profileController = Get.put(ProfileController());

  // Loading states
  final RxBool _isLiking = false.obs;
  final RxBool _isFavoriting = false.obs;

  // Placeholder URLs
  final String evePlaceholderUrl =
      'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.appspot.com/o/placeholder%2Feves_avatar.jpeg?alt=media&token=75b9c3f5-72c1-42db-be5c-471cc0d88c05';
  final String adamPlaceholderUrl =
      'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.appspot.com/o/placeholder%2Fadam_avatar.jpeg?alt=media&token=997423ec-96a4-42d6-aea8-c8cb80640ca0';
  final String genericPlaceholderUrl =
      'https://via.placeholder.com/400?text=No+Image';

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
        color: Colors.black.withAlpha((255 * 0.6).round()), // Updated withAlpha
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.blueGrey, fontSize: 12.0),
      ),
    );
  }

  void _showFilterModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6, // Start at 60% of screen height
          minChildSize: 0.3,   // Min at 30%
          maxChildSize: 0.9,   // Max at 90%
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration( // Keep BoxDecoration for rounded corners
                color: Colors.black.withOpacity(0.8), // MODIFIED: Semi-transparent black
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: _FilterSheetContent( // This should be fine as _FilterSheetContent is defined below
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
    int currentPageIndex = 0; // Keep track of current page for logging

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            // ADDED PRINT STATEMENT
            print("SwipingScreen: Obx rebuilding. Profile count: ${profileController.filteredUsersProfileList.length}");
            if (profileController.filteredUsersProfileList.isNotEmpty && profileController.filteredUsersProfileList.length > currentPageIndex) {
              final currentUserForLog = profileController.filteredUsersProfileList[currentPageIndex];
              // ADDED PRINT STATEMENT & MODIFIED to use .value for RxBool
              print("SwipingScreen: Obx - User at index $currentPageIndex: ${currentUserForLog.name}, isFavorite: ${currentUserForLog.isFavorite.value}");
            }

            if (profileController.allUsersProfileList.isEmpty &&
                profileController.filteredUsersProfileList.isEmpty) {
              return const Center(
                child: Text(
                  "Finding profiles...",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            } else if (profileController.filteredUsersProfileList.isEmpty) {
              return const Center(
                child: Text(
                  "No profiles match your criteria.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            return PageView.builder(
              itemCount: profileController.filteredUsersProfileList.length,
              controller: PageController(
                initialPage: 0,
                viewportFraction: 1.0,
              ),
              onPageChanged: (index) { // Update current page index
                currentPageIndex = index;
              },
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) { // 'index' is the pageIndex for itemBuilder
                final Person eachProfileInfo =
                profileController.filteredUsersProfileList[index];
                final String imageUrl = _getImageUrl(eachProfileInfo);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage( // MODIFIED: Replaced Container with CachedNetworkImage
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.all(8.0), // Optional: for a little spacing from the edge
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0, // Optional: make it a bit smaller if desired
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent), // Optional: change color for visibility
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        print('Error loading image with CachedNetworkImage for ${eachProfileInfo.name}: $error');
                        // Optionally, return a more specific error placeholder image or icon
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                          ),
                        );
                      },
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha((255 * 0.1).round()), // Updated withAlpha
                            Colors.black.withAlpha((255 * 0.7).round()), // Updated withAlpha
                          ],
                          stops: const [0.5, 0.7, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20.0,
                      left: 16.0,
                      right: 16.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              if (eachProfileInfo.uid != null) {
                                Get.to(() => UserDetailsScreen(
                                    userID: eachProfileInfo.uid!));
                              } else {
                                Get.snackbar(
                                    "Error", "User ID is missing, cannot open details.",
                                    backgroundColor: Colors.redAccent,
                                    colorText: Colors.white);
                              }
                            },
                            child: Text(
                              eachProfileInfo.name ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                      blurRadius: 0.0,
                                      color: Colors.black87,
                                      offset: Offset(0, 0)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '${eachProfileInfo.age?.toString() ?? ''}${eachProfileInfo.age != null && eachProfileInfo.city != null && eachProfileInfo.city!.isNotEmpty ? ' • ' : ''}${eachProfileInfo.city ?? ''}'
                                .trim(),
                            style: TextStyle(
                              color: Colors.yellow[700],
                              fontSize: 18,
                              shadows: const [
                                Shadow(
                                    blurRadius: 1.0,
                                    color: Colors.black87,
                                    offset: Offset(0, 0)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Wrap(
                            spacing: 6.0,
                            runSpacing: 4.0,
                            children: [
                              if (eachProfileInfo.profession != null &&
                                  eachProfileInfo.profession!.isNotEmpty)
                                _buildInfoPill(eachProfileInfo.profession!),
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
                              if (eachProfileInfo.drinkSelection == true) // <-- ADDED LINE
                                _buildInfoPill("Drinks"),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Favorite Button - MODIFIED with Obx and .value
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
                                  eachProfileInfo.isFavorite.value // CORRECTED
                                      ? 'images/full_fave.png'
                                      : 'images/default_fave.png',
                                  width: 40,
                                  height: 40,
                                  color: eachProfileInfo.isFavorite.value ? Colors.yellow[700] : Colors.blueGrey, // CORRECTED
                                ),
                                onPressed: _isFavoriting.value
                                    ? null
                                    : () async {
                                  print(
                                      "SwipingScreen: Favorite button pressed for ${eachProfileInfo.name}, UID: ${eachProfileInfo.uid}, current isFavorite: ${eachProfileInfo.isFavorite.value}");
                                  if (eachProfileInfo.uid != null) {
                                    _isFavoriting.value = true; // Start loading
                                    try {
                                      // Assuming toggleFavoriteStatus returns the new favorite status (bool)
                                      final newFavoriteStatus = await profileController
                                          .toggleFavoriteStatus(eachProfileInfo.uid!);
                                      // Update the local Person object's observable.
                                      // This is important if ProfileController doesn't directly update
                                      // the isFavorite property of the Person objects in its lists
                                      // in a way that GetX automatically picks up for this specific instance.
                                      // If toggleFavoriteStatus updates the underlying list item reactively,
                                      // this explicit update might be redundant but usually harmless.
                                      eachProfileInfo.isFavorite.value = newFavoriteStatus;
                                    } catch (e) {
                                      Get.snackbar("Error",
                                          "Failed to update favorite: ${e.toString()}",
                                          backgroundColor: Colors.redAccent,
                                          colorText: Colors.white,
                                          snackPosition: SnackPosition.BOTTOM);
                                      print(
                                          'Error updating favorite for ${eachProfileInfo.name}: $e');
                                    } finally {
                                      _isFavoriting.value = false; // Stop loading
                                    }
                                  } else {
                                    Get.snackbar("Error",
                                        "Cannot update favorite status: User ID is missing.",
                                        backgroundColor: Colors.redAccent,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM);
                                    print(
                                        'Error: Favorite button tapped but UID is null for ${eachProfileInfo.name}');
                                  }
                                },

                                tooltip: 'Favorite',
                              )),

                              Obx(() {
                                bool canMessage = eachProfileInfo.likeStatus.value == LikeStatus.mutualLike;
                                return IconButton(
                                  icon: Image.asset(
                                    'images/default_message.png',
                                    width: 75,
                                    height: 75,
                                    // Color still indicates active/inactive state
                                    color: canMessage ? Colors.yellow[700] : Colors.blueGrey.withOpacity(0.5),
                                  ),
                                  onPressed: () async { // MODIFIED: Made async
                                    if (canMessage) {
                                      final String? userPhoneNumber = eachProfileInfo.phoneNumber;

                                      if (userPhoneNumber != null && userPhoneNumber.isNotEmpty) {
                                        // Assumes format like +27821234567 or 27821234567.
                                        // Sanitize to remove any potential non-dial characters except a leading '+'.
                                        String formattedPhoneNumber = userPhoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

                                        if (!formattedPhoneNumber.startsWith('+') && RegExp(r'^\d+$').hasMatch(formattedPhoneNumber)) {
                                          // If it's all digits and doesn't start with '+', it might be a local number
                                          // or a number where country code is implied. For WhatsApp, it's safer
                                          // if it's in full international format. This part depends on how numbers are stored.
                                          // Assuming numbers are stored with country code (e.g. "27..." for SA or "+27...").
                                          // If the '+' is missing but country code digits are there, api.whatsapp.com often handles it.
                                        } else if (!formattedPhoneNumber.startsWith('+')) {
                                          Get.snackbar(
                                            "WhatsApp Warning",
                                            "Phone number format may not be ideal for WhatsApp (e.g., missing '+'). Number: $formattedPhoneNumber. Attempting anyway.",
                                            backgroundColor: Colors.orangeAccent,
                                            colorText: Colors.white,
                                            duration: const Duration(seconds: 5),
                                          );
                                        }

                                        final Uri whatsappUri = Uri.parse("https://api.whatsapp.com/send?phone=$formattedPhoneNumber");

                                        if (await canLaunchUrl(whatsappUri)) {
                                          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                                          Get.snackbar(
                                            "Opening WhatsApp...",
                                            "If WhatsApp doesn't open, please check if it's installed.",
                                            backgroundColor: Colors.green,
                                            colorText: Colors.white,
                                          );
                                        } else {
                                          Get.snackbar(
                                            "WhatsApp Error",
                                            "Could not open WhatsApp. Please ensure it's installed or the phone number ($formattedPhoneNumber) is valid.",
                                            backgroundColor: Colors.redAccent,
                                            colorText: Colors.white,
                                            duration: const Duration(seconds: 5),
                                          );
                                        }
                                      } else {
                                        // Phone number is missing or empty on the Person object
                                        Get.snackbar(
                                          "Message Error",
                                          "Cannot message on WhatsApp: User's phone number is not available.",
                                          backgroundColor: Colors.orangeAccent,
                                          colorText: Colors.white,
                                        );
                                      }
                                    } else {
                                      // This part (when canMessage is false) remains unchanged
                                      Get.snackbar(
                                        "Message Unavailable",
                                        "You can only message users after a mutual like.",
                                        backgroundColor: Colors.orangeAccent,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.TOP,
                                      );
                                    }
                                  },

                                  tooltip: canMessage ? 'Message' : 'Message (Requires Mutual Like)',
                                );
                              }),

                              // Like Button (added within the Row of action buttons)
                              Obx(() {
                                String likeIconAsset;
                                Color? likeIconColor;

                                // Determine like icon based on like status
                                switch (eachProfileInfo.likeStatus.value) {
                                  case LikeStatus.currentUserLiked:
                                  case LikeStatus.targetUserLikedCurrentUser:
                                    likeIconAsset = 'images/half_like.png';
                                    likeIconColor = null;
                                    break;
                                  case LikeStatus.mutualLike:
                                    likeIconAsset = 'images/full_like.png';
                                    likeIconColor = Colors.yellow[700];
                                    break;
                                  case LikeStatus.none:
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
                                      ? null // Disable if loading
                                      : () async {
                                    if (eachProfileInfo.uid != null) {
                                      _isLiking.value = true; // Start loading
                                      try {
                                        // Assuming toggleLike returns the new LikeStatus
                                        final newLikeStatus = await profileController.toggleLike(eachProfileInfo.uid!);
                                        // Update the local Person object's observable LikeStatus
                                        eachProfileInfo.likeStatus.value = newLikeStatus;
                                      } catch (e) {
                                        Get.snackbar(
                                          "Error",
                                          "Failed to process like: ${e.toString()}",
                                          backgroundColor: Colors.redAccent,
                                          colorText: Colors.white,
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                        print('Error processing like for ${eachProfileInfo.name}: $e');
                                      } finally {
                                        _isLiking.value = false; // Stop loading
                                      }
                                    } else {
                                      Get.snackbar(
                                        "Error",
                                        "Cannot process like: User ID is missing.",
                                        backgroundColor: Colors.redAccent,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      print('Error: Like button tapped but UID is null for ${eachProfileInfo.name}');
                                    }
                                  },
                                  tooltip: 'Like',
                                );
                              }),

                            ],
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
                color: Colors.black.withAlpha((255 * 0.3).round()),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.filter_list, color: Colors.yellow[700]),
                tooltip: 'Filter Profiles',
                onPressed: () {
                  _showFilterModalBottomSheet(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// _FilterSheetContent and its state class remain unchanged as per your file content.
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
  bool? _wantsHost;
  bool? _wantsTravel;
  String? _selectedProfession;
  String? _selectedCountry;
  String? _selectedProvince;
  String? _selectedCity;

  final Map<String, Map<String, List<String>>> africanLocations = {
    "Any": {},
    "South Africa": {
      "Any": [],
      "Gauteng": ["Any", "Johannesburg", "Pretoria", "Vereeniging"],
      "Western Cape": ["Any", "Cape Town", "Stellenbosch", "George"],
      "KwaZulu-Natal": ["Any", "Durban", "Pietermaritzburg", "Richards Bay"]
    },
    "Kenya": {
      "Any": [],
      "Nairobi": ["Any", "Westlands", "Kilimani", "Nairobi CBD"],
      "Mombasa": ["Any", "Nyali", "Old Town", "Likoni"],
      "Kisumu": ["Any", "Milimani", "CBD"]
    },
    "Nigeria": {
      "Any": [],
      "Lagos": ["Any", "Ikeja", "Lekki", "Victoria Island"],
      "Abuja": ["Any", "Central Business District", "Garki", "Wuse"],
      "Kano": ["Any", "Dala", "Fagge", "Nassarawa"]
    },
  };

  // --- START OF MODIFICATION 1: Define asianLocations and allLocations ---
  final Map<String, Map<String, List<String>>> asianLocations = {
    'Vietnam': {
      "Any": [],
      'Hanoi Capital Region': ['Any', 'Hanoi', 'Haiphong'],
      'Ho Chi Minh City Region': ['Any', 'Ho Chi Minh City', 'Can Tho'],
      'Da Nang Province': ['Any', 'Da Nang', 'Hoi An'],
    },
    'Thailand': {
      "Any": [],
      'Bangkok Metropolitan Region': ['Any', 'Bangkok', 'Nonthaburi', 'Samut Prakan'],
      'Chiang Mai Province': ['Any', 'Chiang Mai City', 'Chiang Rai City'],
      'Phuket Province': ['Any', 'Phuket Town', 'Patong'],
    },
    'Indonesia': {
      "Any": [],
      'Jakarta Special Capital Region': ['Any', 'Jakarta', 'South Tangerang'],
      'Bali Province': ['Any', 'Denpasar', 'Ubud', 'Kuta'],
      'West Java Province': ['Any', 'Bandung', 'Bogor'],
    }
  };

  late final Map<String, Map<String, List<String>>> allLocations;
  // --- END OF MODIFICATION 1 ---

  List<String> _countries = [];
  List<String> _provinces = [];
  List<String> _cities = [];

  final List<String> _ethnicities = [
    "Any", "Asian", "Black", "Mixed", "White"
  ];
  final List<String> _professions = [
    "Any", "Student", "Freelancer", "Professional"
  ];
  final List<String> _genders = ["Any", "Male", "Female"];

  @override
  void initState() {
    super.initState();
    // --- START OF MODIFICATION 2: Combine maps and update countriesList source ---
    allLocations = {}..addAll(africanLocations)..addAll(asianLocations);
    _countries = allLocations.keys.toList();
    // --- END OF MODIFICATION 2 ---

    final currentFilters = widget.profileController.activeFilters.value;
    _currentAgeRange = currentFilters.ageRange ?? const RangeValues(18, 65);
    _selectedEthnicity = currentFilters.ethnicity ?? "Any";
    _selectedGender = currentFilters.gender ?? "Any";
    _wantsHost = currentFilters.wantsHost;
    _wantsTravel = currentFilters.wantsTravel;
    _selectedProfession = currentFilters.profession ?? "Any";
    _selectedCountry = currentFilters.country ?? "Any";

    // --- START OF MODIFICATION 3: Use allLocations in initState filter loading logic ---
    if (_selectedCountry != null && _selectedCountry != "Any" && allLocations.containsKey(_selectedCountry)) {
      _provinces = allLocations[_selectedCountry!]!.keys.toList();
      _selectedProvince = currentFilters.province ?? "Any";
      if (_selectedProvince != null && _selectedProvince != "Any" && allLocations[_selectedCountry!]!.containsKey(_selectedProvince)) {
        _cities = allLocations[_selectedCountry!]![_selectedProvince!]!;
        _selectedCity = currentFilters.city ?? "Any";
        if(!_cities.contains(_selectedCity)){
          _selectedCity = "Any";
        }
      } else {
        _cities = []; // Clear cities if province is "Any" or not found in allLocations for the country
        _selectedCity = "Any";
      }
    } else {
      _provinces = [];
      _cities = [];
      _selectedProvince = "Any";
      _selectedCity = "Any";
    }
    // --- END OF MODIFICATION 3 ---
  }

  void _updateProvinces(String? country) {
    setState(() {
      _selectedCountry = country;
      _selectedProvince = "Any";
      _selectedCity = "Any";
      // --- START OF MODIFICATION 4: Use allLocations in _updateProvinces ---
      if (country != null && country != "Any" && allLocations.containsKey(country)) {
        _provinces = allLocations[country]!.keys.toList();
      } else {
        _provinces = [];
      }
      // --- END OF MODIFICATION 4 ---
      _cities = [];
    });
  }

  void _updateCities(String? province) {
    setState(() {
      _selectedProvince = province;
      _selectedCity = "Any";
      // --- START OF MODIFICATION 5: Use allLocations in _updateCities ---
      if (_selectedCountry != null && _selectedCountry != "Any" &&
          province != null && province != "Any" &&
          allLocations.containsKey(_selectedCountry) &&
          allLocations[_selectedCountry!]!.containsKey(province)) {
        _cities = allLocations[_selectedCountry!]![province]!;
      } else {
        _cities = [];
      }
      // --- END OF MODIFICATION 5 ---
    });
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

          Text('Age Range: ${_currentAgeRange.start.round()} - ${_currentAgeRange.end.round()}', style: const TextStyle(fontSize: 16)),
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
              setState(() {
                _currentAgeRange = values;
              });
            },
          ),
          const SizedBox(height: 16),

          _buildDropdown("Gender", _selectedGender, _genders, (val) {
            setState(() { _selectedGender = val; });
          }),
          const SizedBox(height: 16),

          _buildDropdown("Profession", _selectedProfession, _professions, (val) {
            setState(() { _selectedProfession = val; });
          }),
          const SizedBox(height: 16),

          _buildDropdown("Ethnicity", _selectedEthnicity, _ethnicities, (val) {
            setState(() { _selectedEthnicity = val; });
          }),
          const SizedBox(height: 16),

          _buildDropdown("Country", _selectedCountry, _countries, _updateProvinces),
          const SizedBox(height: 16),

          if (_selectedCountry != null && _selectedCountry != "Any")
            _buildDropdown("State/Province", _selectedProvince, _provinces, _updateCities),
          const SizedBox(height: 16),

          if (_selectedProvince != null && _selectedProvince != "Any")
            _buildDropdown("City", _selectedCity, _cities, (val) {
              setState(() { _selectedCity = val; });
            }),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Wants to Host', style: TextStyle(fontSize: 16)),
            value: _wantsHost ?? false,
            onChanged: (bool value) {
              setState(() {
                _wantsHost = value;
              });
            },
            secondary: Icon(_wantsHost == true ? Icons.night_shelter : Icons.night_shelter_outlined),
          ),

          SwitchListTile(
            title: const Text('Wants to Travel', style: TextStyle(fontSize: 16)),
            value: _wantsTravel ?? false,
            onChanged: (bool value) {
              setState(() {
                _wantsTravel = value;
              });
            },
            secondary: Icon(_wantsTravel == true ? Icons.flight_takeoff : Icons.flight_land),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentAgeRange = const RangeValues(18, 65);
                    _selectedEthnicity = "Any";
                    _selectedGender = "Any";
                    _wantsHost = null;
                    _wantsTravel = null;
                    _selectedProfession = "Any";
                    _selectedCountry = "Any";
                    _selectedProvince = "Any";
                    _selectedCity = "Any";
                    _provinces = [];
                    _cities = [];
                  });
                  widget.profileController.updateFilters(FilterPreferences());
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
                    wantsHost: _wantsHost,
                    wantsTravel: _wantsTravel,
                    profession: _selectedProfession == "Any" ? null : _selectedProfession,
                    country: _selectedCountry == "Any" ? null : _selectedCountry,
                    province: _selectedProvince == "Any" ? null : _selectedProvince,
                    city: _selectedCity == "Any" ? null : _selectedCity,
                  );
                  widget.profileController.updateFilters(newFilters);
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
      value: items.contains(currentValue) ? currentValue : (items.isNotEmpty ? items.first : null),
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
