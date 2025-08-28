// GEMINI_WRITE_TEST
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/filter_preferences.dart';
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
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            print(
                                'Error loading image for ${eachProfileInfo.name}: $exception');
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
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 18,
                              shadows: [
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
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Favorite Button - MODIFIED with Obx and .value
                              Obx(() => IconButton(
                                icon: Image.asset(
                                  (eachProfileInfo.isFavorite.value) // Use .value for RxBool
                                      ? 'images/full_fave.png'
                                      : 'images/default_fave.png',
                                  width: 45,
                                  height: 45,
                                  color: (eachProfileInfo.isFavorite.value) // Use .value for RxBool
                                      ? null                      // No tint for active state
                                      : Colors.blueGrey,
                                ),
                                onPressed: () {
                                  print("SwipingScreen: Favorite button pressed for ${eachProfileInfo.name}, UID: ${eachProfileInfo.uid}, current isFavorite: ${eachProfileInfo.isFavorite.value}"); // Use .value
                                  if (eachProfileInfo.uid != null) {
                                    profileController.toggleFavoriteStatus(eachProfileInfo.uid!);
                                  } else {
                                    Get.snackbar(
                                        "Error",
                                        "Cannot update favorite status: User ID is missing.",
                                        backgroundColor: Colors.redAccent,
                                        colorText: Colors.white
                                    );
                                    print('Error: Favorite button tapped but UID is null for ${eachProfileInfo.name}');
                                  }
                                },
                                tooltip: 'Favorite',
                              )),

                              Obx(() {
                                bool canMessage = eachProfileInfo.likeStatus.value == LikeStatus.mutualLike;
                                return IconButton(
                                  icon: Image.asset(
                                    'images/default_message.png',
                                    width: 90,
                                    height: 90,
                                    // Color still indicates active/inactive state
                                    color: canMessage ? Colors.green : Colors.blueGrey.withOpacity(0.5),
                                  ),
                                  onPressed: () { // onPressed is no longer null
                                    if (canMessage) {
                                      // Action for when messaging is allowed
                                      print('Message button tapped for ${eachProfileInfo.name}, UID: ${eachProfileInfo.uid}. MUTUAL LIKE CONFIRMED.');
                                      Get.snackbar(
                                        "Mutual Like!",
                                        "You and ${eachProfileInfo.name ?? 'this user'} have liked each other. Messaging enabled!",
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                      // TODO: Get.to(() => ChatScreen(targetUserId: eachProfileInfo.uid!));
                                    } else {
                                      // Action for when messaging is NOT allowed (show Snackbar)
                                      Get.snackbar(
                                        "Message Unavailable",
                                        "You can only message users after a mutual like.",
                                        backgroundColor: Colors.orangeAccent,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.TOP, // Optional: show at top
                                      );
                                    }
                                  },
                                  tooltip: canMessage ? 'Message' : 'Message (Requires Mutual Like)',
                                );
                              }),

                              Obx(() {
                                String likeIconAsset;
                                Color? likeIconColor;

                                switch (eachProfileInfo.likeStatus.value) {
                                  case LikeStatus.currentUserLiked:
                                  case LikeStatus.targetUserLikedCurrentUser: // MODIFIED - Added this case
                                    likeIconAsset = 'images/half_like.png';
                                    likeIconColor = null;
                                    break;
                                  case LikeStatus.mutualLike:
                                    likeIconAsset = 'images/full_like.png';
                                    likeIconColor = null;
                                    break;
                                  case LikeStatus.none:
                                  default:
                                    likeIconAsset = 'images/default_like.png';
                                    likeIconColor = Colors.blueGrey;
                                    break;
                                }

                                return IconButton(
                                  icon: Image.asset(
                                    likeIconAsset,
                                    width: 45,
                                    height: 45,
                                    color: likeIconColor,
                                  ),
                                  onPressed: () {
                                    if (eachProfileInfo.uid != null) {
                                      print('Like button tapped for ${eachProfileInfo.name}, UID: ${eachProfileInfo.uid}, current status: ${eachProfileInfo.likeStatus.value}');
                                      profileController.toggleLike(eachProfileInfo.uid!);
                                    } else {
                                      Get.snackbar(
                                          "Error",
                                          "Cannot process like: User ID is missing.",
                                          backgroundColor: Colors.redAccent,
                                          colorText: Colors.white
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
                icon: const Icon(Icons.filter_list, color: Colors.white),
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

  List<String> _countries = [];
  List<String> _provinces = [];
  List<String> _cities = [];

  final List<String> _ethnicities = [
    "Any", "Asian", "Black", "Mixed", "White", "Other"
  ];
  final List<String> _professions = [
    "Any", "Student", "Freelancer", "Professional"
  ];
  final List<String> _genders = ["Any", "Male", "Female"];

  @override
  void initState() {
    super.initState();
    final currentFilters = widget.profileController.activeFilters.value;
    _currentAgeRange = currentFilters.ageRange ?? const RangeValues(18, 65);
    _selectedEthnicity = currentFilters.ethnicity ?? "Any";
    _selectedGender = currentFilters.gender ?? "Any";
    _wantsHost = currentFilters.wantsHost;
    _wantsTravel = currentFilters.wantsTravel;
    _selectedProfession = currentFilters.profession ?? "Any";
    _selectedCountry = currentFilters.country ?? "Any";

    _countries = africanLocations.keys.toList();

    if (_selectedCountry != null && _selectedCountry != "Any" && africanLocations.containsKey(_selectedCountry)) {
      _provinces = africanLocations[_selectedCountry!]!.keys.toList();
      _selectedProvince = currentFilters.province ?? "Any";
      if (_selectedProvince != null && _selectedProvince != "Any" && africanLocations[_selectedCountry!]!.containsKey(_selectedProvince)) {
        _cities = africanLocations[_selectedCountry!]![_selectedProvince!]!;
        _selectedCity = currentFilters.city ?? "Any";
        if(!_cities.contains(_selectedCity)){
          _selectedCity = "Any";
        }
      } else {
        _cities = [];
        _selectedCity = "Any";
      }
    } else {
      _provinces = [];
      _cities = [];
      _selectedProvince = "Any";
      _selectedCity = "Any";
    }
  }

  void _updateProvinces(String? country) {
    setState(() {
      _selectedCountry = country;
      _selectedProvince = "Any";
      _selectedCity = "Any";
      if (country != null && country != "Any" && africanLocations.containsKey(country)) {
        _provinces = africanLocations[country]!.keys.toList();
      } else {
        _provinces = [];
      }
      _cities = [];
    });
  }

  void _updateCities(String? province) {
    setState(() {
      _selectedProvince = province;
      _selectedCity = "Any";
      if (_selectedCountry != null && _selectedCountry != "Any" &&
          province != null && province != "Any" &&
          africanLocations.containsKey(_selectedCountry) &&
          africanLocations[_selectedCountry!]!.containsKey(province)) {
        _cities = africanLocations[_selectedCountry!]![province]!;
      } else {
        _cities = [];
      }
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
