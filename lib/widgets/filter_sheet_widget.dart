// lib/widgets/filter_sheet_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer'; // Make sure log is imported

import '../controllers/profile_controller.dart';
import '../models/filter_preferences.dart';

class FilterSheetWidget extends StatefulWidget {
  final ProfileController profileController;
  final ScrollController scrollController;

  const FilterSheetWidget({
    super.key,
    required this.profileController,
    required this.scrollController,
  });

  @override
  State<FilterSheetWidget> createState() => _FilterSheetWidgetState();
}

class _FilterSheetWidgetState extends State<FilterSheetWidget> {
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

  // Location data
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
      'Bangkok Metropolitan Region': [
        'Any',
        'Bangkok',
        'Nonthaburi',
        'Samut Prakan'
      ],
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

  // Dropdown list definitions
  late List<String> _countries;
  late List<String> _provinces;
  late List<String> _cities;

  static const List<String> _ethnicities = [
    "Any",
    "Asian",
    "Black",
    "Mixed",
    "White"
  ];
  static const List<String> _professions = [
    "Any",
    "Student",
    "Freelancer",
    "Professional"
  ];
  static const List<String> _genders = ["Any", "Male", "Female"];
  static const List<String> _relationshipStatuses = [
    "Any",
    "Single",
    "Married",
    "Divorced"
  ];

  @override
  void initState() {
    super.initState();
    _countries = _allLocations.keys.toList();
    final currentFilters = widget.profileController.activeFilters.value;

    // --- START: CRASH FIX ---
    final RangeValues initialRange = currentFilters.ageRange ?? const RangeValues(18, 100);
    const double minAge = 18.0;
    const double maxAge = 100.0; // The max value from your RangeSlider
    _currentAgeRange = RangeValues(
      initialRange.start.clamp(minAge, maxAge),
      initialRange.end.clamp(minAge, maxAge),
    );
    if (_currentAgeRange.start > _currentAgeRange.end) {
      _currentAgeRange = RangeValues(_currentAgeRange.end, _currentAgeRange.end);
    }
    // --- END: CRASH FIX ---

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
    final newProvinces = (country != null && country != "Any")
        ? _allLocations[country]!.keys.toList()
        : <String>["Any"];

    if (!fromInit) {
      setState(() {
        _selectedCountry = country;
        _provinces = newProvinces;
        _selectedProvince = "Any";
        _cities = ["Any"];
        _selectedCity = "Any";
      });
    } else {
      _provinces = newProvinces;
    }
  }

  void _updateCities(String? province, {bool fromInit = false}) {
    final newCities = (_selectedCountry != null && _selectedCountry != "Any" &&
        province != null && province != "Any")
        ? _allLocations[_selectedCountry]![province]!
        : <String>["Any"];

    if (!fromInit) {
      setState(() {
        _selectedProvince = province;
        _cities = newCities;
        _selectedCity = "Any";
      });
    } else {
      _cities = newCities;
    }
  }

  void _applyFilters() {
    final newFilters = FilterPreferences(
      ageRange: _currentAgeRange,
      ethnicity: _selectedEthnicity == "Any" ? null : _selectedEthnicity,
      gender: _selectedGender == "Any" ? null : _selectedGender,
      profession: _selectedProfession == "Any" ? null : _selectedProfession,
      relationshipStatus: _selectedRelationshipStatus == "Any"
          ? null
          : _selectedRelationshipStatus,
      wantsHost: _wantsHost,
      wantsTravel: _wantsTravel,
      country: _selectedCountry == "Any" ? null : _selectedCountry,
      province: _selectedProvince == "Any" ? null : _selectedProvince,
      city: _selectedCity == "Any" ? null : _selectedCity,
    );
    widget.profileController.updateAndApplyFilters(newFilters);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    widget.profileController.resetFilters();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // This is your original, superior UI, now using SingleChildScrollView
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important for scroll view
          children: <Widget>[
            const Center(
              child: Text('Filter Profiles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 20),

            Text('Age Range: ${_currentAgeRange.start.round()} - ${_currentAgeRange.end.round()}', style: const TextStyle(fontSize: 16, color: Colors.white70)),
            RangeSlider(
              values: _currentAgeRange,
              min: 18,
              max: 100, // Matching the original UI's max
              divisions: 82,
              labels: RangeLabels(_currentAgeRange.start.round().toString(), _currentAgeRange.end.round().toString()),
              onChanged: (RangeValues values) => setState(() => _currentAgeRange = values),
              activeColor: Colors.yellow[700],
              inactiveColor: Colors.grey[700],
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

            _buildDropdown("Country", _selectedCountry, _countries, (val) => _updateProvinces(val)),
            const SizedBox(height: 16),
            _buildDropdown("State/Province", _selectedProvince, _provinces, (val) => _updateCities(val)),
            const SizedBox(height: 16),
            _buildDropdown("City", _selectedCity, _cities, (val) => setState(() => _selectedCity = val)),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Wants to Host', style: TextStyle(fontSize: 16, color: Colors.white70)),
              value: _wantsHost ?? false, // Default to false for the switch UI
              onChanged: (bool value) => setState(() => _wantsHost = value),
              secondary: Icon(_wantsHost == true ? Icons.night_shelter : Icons.night_shelter_outlined, color: Colors.white70),
              activeColor: Colors.yellow[700],
              tileColor: Colors.grey[850],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Wants to Travel', style: TextStyle(fontSize: 16, color: Colors.white70)),
              value: _wantsTravel ?? false, // Default to false for the switch UI
              onChanged: (bool value) => setState(() => _wantsTravel = value),
              secondary: Icon(_wantsTravel == true ? Icons.flight_takeoff : Icons.flight_land, color: Colors.white70),
              activeColor: Colors.yellow[700],
              tileColor: Colors.grey[850],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _resetFilters,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                  child: const Text('Reset', style: TextStyle(color: Colors.black87)),
                ),
                ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[700]),
                  child: const Text('Apply Filters', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
            const SizedBox(height: 40), // Padding at the bottom for scroll
          ],
        ),
      ),
    );
  }

  // Your original, superior dropdown builder
  Widget _buildDropdown(String label, String? currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[850],
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow[700]!), borderRadius: BorderRadius.circular(8.0)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      value: (currentValue != null && items.contains(currentValue)) ? currentValue : items.first,
      isExpanded: true,
      dropdownColor: Colors.grey[900],
      style: const TextStyle(color: Colors.white),
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
