// lib/widgets/filter_sheet_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer';

import '../controllers/profile_controller.dart';
import '../models/filter_preferences.dart';
import 'package:eavzappl/utils/app_constants.dart';
import 'package:eavzappl/controllers/location_controller.dart';

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
  // State variables for the UI
  late RangeValues _currentAgeRange;
  String? _selectedGender;
  String? _selectedProfession;
  String? _selectedEthnicity;
  String? _selectedRelationshipStatus;
  String? _selectedHeight;
  String? _selectedBodyType;
  String? _selectedIncome;
  bool? _wantsHost;
  bool? _wantsTravel;
  String? _selectedCountry;
  String? _selectedProvince;
  String? _selectedCity;

  // Lists for dropdowns
  late List<String> _countries;
  late List<String> _provinces;
  late List<String> _cities;

  @override
  void initState() {
    super.initState();
    final locationController = Get.find<LocationController>();
    _countries = locationController.getCountries();

    // Load the currently active filters from the controller
    final currentFilters = widget.profileController.activeFilters.value;

    // Initialize UI state from the loaded filters, falling back to a neutral value
    _currentAgeRange = currentFilters.ageRange ?? const RangeValues(18, 100);
    _selectedGender = currentFilters.gender;
    _selectedProfession = currentFilters.profession;
    _selectedEthnicity = currentFilters.ethnicity;
    _selectedRelationshipStatus = currentFilters.relationshipStatus;
    _selectedHeight = currentFilters.height;
    _selectedBodyType = currentFilters.bodyType;
    _selectedIncome = currentFilters.income;
    _wantsHost = currentFilters.wantsHost;
    _wantsTravel = currentFilters.wantsTravel;

    _selectedCountry = currentFilters.country;
    // Populate province/city lists based on saved country/province
    _provinces = ["Any", ...locationController.getProvinces(currentFilters.country)];
    _selectedProvince = currentFilters.province;
    _cities = ["Any", ...locationController.getCities(currentFilters.country, currentFilters.province)];
    _selectedCity = currentFilters.city;
  }

  void _updateProvinces(String? country) {
    final locationController = Get.find<LocationController>();
    final newProvinces = locationController.getProvinces(country);

    setState(() {
      _selectedCountry = country;
      _provinces = ["Any", ...newProvinces];
      _selectedProvince = null; // Reset province
      _cities = ["Any"];
      _selectedCity = null; // Reset city
    });
  }

  void _updateCities(String? province) {
    final locationController = Get.find<LocationController>();
    final newCities = locationController.getCities(_selectedCountry, province);
    setState(() {
      _selectedProvince = province;
      _cities = ["Any", ...newCities];
      _selectedCity = null; // Reset city
    });
  }

  // ============ IN filter_sheet_widget.dart ============

  void _applyFilters() {
    // Create a new FilterPreferences object from the current UI state
    final newFilters = FilterPreferences(
      ageRange: _currentAgeRange,
      gender: _selectedGender,
      profession: _selectedProfession,
      ethnicity: _selectedEthnicity,
      relationshipStatus: _selectedRelationshipStatus,
      height: _selectedHeight,
      bodyType: _selectedBodyType,
      income: _selectedIncome,
      wantsHost: _wantsHost,
      wantsTravel: _wantsTravel,
      country: _selectedCountry,
      province: _selectedProvince,
      city: _selectedCity,
    );

    // THIS IS THE CORRECT WAY TO APPLY FILTERS:
    // 1. Set the activeFilters value
    widget.profileController.activeFilters.value = newFilters;
    // 2. Call the method to fetch new profiles
    widget.profileController.fetchSwipingProfiles();

    log('Applied filters: ${newFilters.toJson()}');
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    // THIS IS THE CORRECT WAY TO RESET:
    // 1. Set activeFilters to the clean initial state
    widget.profileController.activeFilters.value = FilterPreferences.initial();
    // 2. Call the method to fetch new profiles
    widget.profileController.fetchSwipingProfiles();

    Navigator.of(context).pop();
  }

// =======================================================


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Center(
              child: Text('Filter Profiles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 20),

            // Age Range Slider
            Text('Age Range: ${_currentAgeRange.start.round()} - ${_currentAgeRange.end.round()}', style: const TextStyle(fontSize: 16, color: Colors.white70)),
            RangeSlider(
              values: _currentAgeRange,
              min: 18,
              max: 85,
              divisions: 82,
              labels: RangeLabels(_currentAgeRange.start.round().toString(), _currentAgeRange.end.round().toString()),
              onChanged: (RangeValues values) => setState(() => _currentAgeRange = values),
              activeColor: Colors.yellow[700],
              inactiveColor: Colors.grey[700],
            ),
            const SizedBox(height: 16),

            // Dropdowns
            _buildDropdown("Gender", _selectedGender, AppConstants.genders, (val) => setState(() => _selectedGender = val)),
            const SizedBox(height: 16),
            _buildDropdown("Profession", _selectedProfession, AppConstants.professions, (val) => setState(() => _selectedProfession = val)),
            const SizedBox(height: 16),
            _buildDropdown("Ethnicity", _selectedEthnicity, AppConstants.ethnicities, (val) => setState(() => _selectedEthnicity = val)),
            const SizedBox(height: 16),
            _buildDropdown("Relationship Status", _selectedRelationshipStatus, AppConstants.relationshipStatuses, (val) => setState(() => _selectedRelationshipStatus = val)),
            const SizedBox(height: 16),
            _buildDropdown("Height", _selectedHeight, AppConstants.heights, (val) => setState(() => _selectedHeight = val)),
            const SizedBox(height: 16),
            _buildDropdown("Body Type", _selectedBodyType, AppConstants.bodyTypes, (val) => setState(() => _selectedBodyType = val)),
            const SizedBox(height: 16),
            _buildDropdown("Income", _selectedIncome, AppConstants.incomeBrackets, (val) => setState(() => _selectedIncome = val)),
            const SizedBox(height: 16),

            // Location Dropdowns
            _buildDropdown("Country", _selectedCountry, _countries, (val) => _updateProvinces(val)),
            const SizedBox(height: 16),
            _buildDropdown("State/Province", _selectedProvince, _provinces, (val) => _updateCities(val)),
            const SizedBox(height: 16),
            _buildDropdown("City", _selectedCity, _cities, (val) => setState(() => _selectedCity = val)),
            const SizedBox(height: 16),

            // Switches
            SwitchListTile(
              title: const Text('Wants to Host', style: TextStyle(fontSize: 16, color: Colors.white70)),
              value: _wantsHost ?? false,
              onChanged: (bool value) => setState(() => _wantsHost = value),
              activeColor: Colors.yellow[700],
              tileColor: Colors.grey[850],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Wants to Travel', style: TextStyle(fontSize: 16, color: Colors.white70)),
              value: _wantsTravel ?? false,
              onChanged: (bool value) => setState(() => _wantsTravel = value),
              activeColor: Colors.yellow[700],
              tileColor: Colors.grey[850],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
            const SizedBox(height: 24),

            // Buttons
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? currentValue, List<String> items, ValueChanged<String?> onChanged) {
    // If the currentValue is null, the dropdown will show the hintText ("Any")
    // If the currentValue is a valid item, it will be shown.
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
      value: (currentValue != null && items.contains(currentValue)) ? currentValue : null,
      hint: const Text("Any", style: TextStyle(color: Colors.white70)), // Shows "Any" when value is null
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
