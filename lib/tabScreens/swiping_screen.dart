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
import 'package:transparent_image/transparent_image.dart';


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
          initialChildSize: 0.7, // Increased size to better fit location dropdowns
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
                    // Use CachedNetworkImage for optimized loading and caching
                    CachedNetworkImage(
                      imageUrl: imageUrl ?? '', // Use the image URL or an empty string if null
                      fit: BoxFit.cover,
                      // Placeholder widget to show while the image is loading
                      placeholder: (context, url) => Container(
                        color: Colors.black, // A solid background is better than transparent
                        child: Center(
                          child: Image.asset(placeholderAsset, fit: BoxFit.cover),
                        ),
                      ),
                      // Error widget to display the local placeholder if the network image fails
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

// _GradientOverlay, _ProfileDetails, and _ActionButtons widgets remain the same as your provided code.
// I'm omitting them here for brevity but they are part of the final code.

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
            activeIconAsset: 'images/full_fave.png',
            inactiveIconAsset: 'images/default_fave.png',
            isActive: isFavorite,
            tooltip: 'Favorite',
          );
        }),
        Obx(() {
          final likeStatus = person.uid != null ? likeController.getLikeStatus(person.uid!) : LikeStatus.none;
          final bool canMessage = likeStatus == LikeStatus.mutualLike;
          return _buildActionButton(
            onPressed: canMessage
                ? () => _launchWhatsApp(person.phoneNumber)
                : () => Get.snackbar(
                "Message Unavailable", "You can only message users after a mutual like."),
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


// --- START: CORRECTED _FilterSheetContent WIDGET ---
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
  // State variables for filters
  late RangeValues _currentAgeRange;
  String? _selectedEthnicity;
  String? _selectedGender;
  String? _selectedProfession;
  String? _selectedRelationshipStatus;

  bool? _wantsHost;
  bool? _wantsTravel;

  String? _selectedCountry;
  String? _selectedProvince;
  String? _selectedCity;

  // --- LOCAL DATA FOR LOCATIONS (No external package needed) ---
  // ... (the _allLocations map is unchanged) ...
  final Map<String, Map<String, List<String>>> _allLocations = {
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


  // ... (dropdown list definitions are unchanged) ...
  List<String> _countries = [];
  List<String> _provinces = [];
  List<String> _cities = [];

  static const List<String> _ethnicities = ["Any", "Asian", "Black", "Mixed", "White"];
  static const List<String> _professions = ["Any", "Student", "Freelancer", "Professional"];
  static const List<String> _genders = ["Any", "Male", "Female"];
  static const List<String> _relationshipStatuses = ["Any", "Single", "Married", "Divorced"];


  @override
  void initState() {
    super.initState();
    _countries = _allLocations.keys.toList();
    final currentFilters = widget.profileController.activeFilters.value;

    // Initialize all filter values from the controller
    _currentAgeRange = currentFilters.ageRange ?? const RangeValues(18, 65);
    _selectedEthnicity = currentFilters.ethnicity ?? "Any";
    _selectedGender = currentFilters.gender ?? "Any";
    _selectedProfession = currentFilters.profession ?? "Any";
    _selectedRelationshipStatus = currentFilters.relationshipStatus ?? "Any";

    _wantsHost = currentFilters.wantsHost;
    _wantsTravel = currentFilters.wantsTravel;

    _selectedCountry = currentFilters.country ?? "Any";
    _updateProvinces(_selectedCountry, fromInit: true);
    _selectedProvince = currentFilters.province ?? "Any";
    _updateCities(_selectedProvince, fromInit: true);
    _selectedCity = currentFilters.city ?? "Any";
  }

  void _updateProvinces(String? country, {bool fromInit = false}) {
    if (!fromInit) {
      setState(() {
        _selectedCountry = country;
        _selectedProvince = "Any";
        _selectedCity = "Any";
        _provinces = (country != null && country != "Any") ? _allLocations[country]!.keys.toList() : [];
        _cities = [];
      });
    } else {
      _provinces = (country != null && country != "Any") ? _allLocations[country]!.keys.toList() : [];
    }
  }

  void _updateCities(String? province, {bool fromInit = false}) {
    if (!fromInit) {
      setState(() {
        _selectedProvince = province;
        _selectedCity = "Any";
        _cities = (province != null && province != "Any" && _selectedCountry != null)
            ? _allLocations[_selectedCountry]![province]!
            : [];
      });
    } else {
      _cities = (province != null && province != "Any" && _selectedCountry != null)
          ? _allLocations[_selectedCountry]![province]!
          : [];
    }
  }


  void _applyFilters() {
    final newFilters = FilterPreferences(
      ageRange: _currentAgeRange,
      ethnicity: _selectedEthnicity == "Any" ? null : _selectedEthnicity,
      gender: _selectedGender == "Any" ? null : _selectedGender,
      profession: _selectedProfession == "Any" ? null : _selectedProfession,
      relationshipStatus: _selectedRelationshipStatus == "Any" ? null : _selectedRelationshipStatus,

      wantsHost: _wantsHost,
      wantsTravel: _wantsTravel,

      country: _selectedCountry == "Any" ? null : _selectedCountry,
      province: _selectedProvince == "Any" ? null : _selectedProvince,
      city: _selectedCity == "Any" ? null : _selectedCity,
    );
    widget.profileController.activeFilters.value = newFilters;
    Navigator.pop(context);
  }

  void _clearFilters() {
    widget.profileController.activeFilters.value = FilterPreferences.initial();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // --- START: FIX LAYOUT AND SCROLLING ---
    // Use SingleChildScrollView inside the sheet. DraggableScrollableSheet handles the dragging.
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Center(
              child: Text('Filter Profiles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 20),

            // --- Form Fields ---
            Text('Age Range: ${_currentAgeRange.start.round()} - ${_currentAgeRange.end.round()}', style: const TextStyle(fontSize: 16, color: Colors.white70)),
            RangeSlider(
              values: _currentAgeRange, min: 18, max: 100, divisions: 82,
              labels: RangeLabels(_currentAgeRange.start.round().toString(), _currentAgeRange.end.round().toString()),
              onChanged: (RangeValues values) => setState(() => _currentAgeRange = values),
            ),
            const SizedBox(height: 16),
            _buildDropdown("Gender", _selectedGender, _genders, (val) => setState(() => _selectedGender = val)),
            const SizedBox(height: 16),
            _buildDropdown("Profession", _selectedProfession, _professions, (val) => setState(() => _selectedProfession = val)),
            const SizedBox(height: 16),
            _buildDropdown("Ethnicity", _selectedEthnicity, _ethnicities, (val) => setState(() => _selectedEthnicity = val)),
            const SizedBox(height: 16),
            _buildDropdown("Relationship Status", _selectedRelationshipStatus, _relationshipStatuses, (val) => setState(() => _selectedRelationshipStatus = val)),
            const SizedBox(height: 16),

            // --- MANUAL LOCATION DROPDOWNS ---
            _buildDropdown("Country", _selectedCountry, _countries, (val) => _updateProvinces(val)),
            const SizedBox(height: 16),
            if (_provinces.isNotEmpty) ...[
              _buildDropdown("State/Province", _selectedProvince, _provinces, (val) => _updateCities(val)),
              const SizedBox(height: 16),
            ],
            if (_cities.isNotEmpty) ...[
              _buildDropdown("City", _selectedCity, _cities, (val) => setState(() => _selectedCity = val)),
              const SizedBox(height: 16),
            ],

            SwitchListTile(
              title: const Text('Wants to Host', style: TextStyle(fontSize: 16, color: Colors.white70)),
              value: _wantsHost ?? false,
              onChanged: (bool value) => setState(() => _wantsHost = value),
              secondary: Icon(_wantsHost == true ? Icons.night_shelter : Icons.night_shelter_outlined, color: Colors.white70),
              activeColor: Colors.yellow[700],
            ),
            SwitchListTile(
              title: const Text('Wants to Travel', style: TextStyle(fontSize: 16, color: Colors.white70)),
              value: _wantsTravel ?? false,
              onChanged: (bool value) => setState(() => _wantsTravel = value),
              secondary: Icon(_wantsTravel == true ? Icons.flight_takeoff : Icons.flight_land, color: Colors.white70),
              activeColor: Colors.yellow[700],
            ),

            const SizedBox(height: 24),

            // --- Action Buttons ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _clearFilters,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                  child: const Text('Clear Filters', style: TextStyle(color: Colors.black87)),
                ),
                ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply Filters'),
                ),
              ],
            ),
            const SizedBox(height: 20), // Add padding at the bottom
          ],
        ),
      ),
    );
  }

  // ... (_buildDropdown helper method is unchanged) ...
  Widget _buildDropdown(String label, String? currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow[700]!)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      value: items.contains(currentValue) ? currentValue : (items.isNotEmpty ? items.first : null),
      isExpanded: true,
      dropdownColor: Colors.grey[850],
      style: TextStyle(color: Colors.white),
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
