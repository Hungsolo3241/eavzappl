// lib/widgets/filter_sheet_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer';

import '../controllers/profile_controller.dart';
import '../models/filter_preferences.dart';
import 'package:eavzappl/utils/app_constants.dart';
import 'package:eavzappl/controllers/location_controller.dart';
import 'package:eavzappl/utils/app_theme.dart';

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
    final orientation = widget.profileController.currentUserOrientation;
    final bool isEveProfile = orientation?.toLowerCase() == 'eve';
    final bool isUserDataLoaded = orientation != null;

    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Text('Filter Profiles', style: AppTextStyles.heading2.copyWith(color: AppTheme.primaryYellow)),
              ),
              const SizedBox(height: 20),

              // Age Range Slider - Always visible
              Text('Age Range: ${_currentAgeRange.start.round()} - ${_currentAgeRange.end.round()}', style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)),
              RangeSlider(
                values: _currentAgeRange,
                min: 18,
                max: 85,
                divisions: 82,
                labels: RangeLabels(_currentAgeRange.start.round().toString(), _currentAgeRange.end.round().toString()),
                onChanged: (RangeValues values) => setState(() => _currentAgeRange = values),
                activeColor: AppTheme.primaryYellow,
                              inactiveColor: AppTheme.textGrey,
                            ),
                            const SizedBox(height: 16),
                
                            // Gender - Always visible
                            _buildDropdown("Gender", _selectedGender, AppConstants.genders, (val) => setState(() => _selectedGender = val)),
                            const SizedBox(height: 16),
                
                            // Filters to show for Eve profiles (and Adam profiles if user data is not loaded yet)
                            if (isEveProfile || !isUserDataLoaded) ...[
                              // Show only required filters for Eve
                              _buildDropdown("Ethnicity", AppConstants.ethnicities.contains(_selectedEthnicity) ? _selectedEthnicity : null, AppConstants.ethnicities, (val) => setState(() => _selectedEthnicity = val)),
                              const SizedBox(height: 16),
                              _buildDropdown("Relationship Status", AppConstants.relationshipStatuses.contains(_selectedRelationshipStatus) ? _selectedRelationshipStatus : null, AppConstants.relationshipStatuses, (val) => setState(() => _selectedRelationshipStatus = val)),
                              const SizedBox(height: 16),
                
                              // Location Dropdowns - Always visible for Eve
                              _buildDropdown("Country", _selectedCountry, _countries, (val) => _updateProvinces(val)),
                              const SizedBox(height: 16),
                              _buildDropdown("State/Province", _selectedProvince, _provinces, (val) => _updateCities(val)),
                              const SizedBox(height: 16),
                              _buildDropdown("City", _selectedCity, _cities, (val) => setState(() => _selectedCity = val)),
                              const SizedBox(height: 16),
                
                              // Host and Travel Toggles - Always visible for Eve
                              SwitchListTile(
                                title: Text('Wants to Host', style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)),
                                value: _wantsHost ?? false,
                                onChanged: (bool value) => setState(() => _wantsHost = value),
                                activeColor: AppTheme.primaryYellow,
                                tileColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: Text('Wants to Travel', style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)),
                                value: _wantsTravel ?? false,
                                onChanged: (bool value) => setState(() => _wantsTravel = value),
                                activeColor: AppTheme.primaryYellow,
                                tileColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              ),
                              const SizedBox(height: 24),
                            ] else ...[
                              // Show all filters for Adam
                              _buildDropdown("Profession", AppConstants.professions.contains(_selectedProfession) ? _selectedProfession : null, AppConstants.professions, (val) => setState(() => _selectedProfession = val)),
                              const SizedBox(height: 16),
                              _buildDropdown("Ethnicity", AppConstants.ethnicities.contains(_selectedEthnicity) ? _selectedEthnicity : null, AppConstants.ethnicities, (val) => setState(() => _selectedEthnicity = val)),
                              const SizedBox(height: 16),
                              _buildDropdown("Relationship Status", AppConstants.relationshipStatuses.contains(_selectedRelationshipStatus) ? _selectedRelationshipStatus : null, AppConstants.relationshipStatuses, (val) => setState(() => _selectedRelationshipStatus = val)),
                              const SizedBox(height: 16),
                              _buildDropdown("Height", AppConstants.heights.contains(_selectedHeight) ? _selectedHeight : null, AppConstants.heights, (val) => setState(() => _selectedHeight = val)),
                              const SizedBox(height: 16),
                              _buildDropdown("Body Type", AppConstants.bodyTypes.contains(_selectedBodyType) ? _selectedBodyType : null, AppConstants.bodyTypes, (val) => setState(() => _selectedBodyType = val)),
                              const SizedBox(height: 16),
                              _buildDropdown("Income", AppConstants.incomeBrackets.contains(_selectedIncome) ? _selectedIncome : null, AppConstants.incomeBrackets, (val) => setState(() => _selectedIncome = val)),
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
                                title: Text('Wants to Host', style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)),
                                value: _wantsHost ?? false,
                                onChanged: (bool value) => setState(() => _wantsHost = value),
                                activeColor: AppTheme.primaryYellow,
                                tileColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: Text('Wants to Travel', style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)),
                                value: _wantsTravel ?? false,
                                onChanged: (bool value) => setState(() => _wantsTravel = value),
                                activeColor: AppTheme.primaryYellow,
                                tileColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              ),
                              const SizedBox(height: 24),
                            ],
                
                            // Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                  onPressed: _resetFilters,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.textGrey),
                                  child: Text('Reset', style: AppTextStyles.body1.copyWith(color: Colors.white)),
                                ),
                                ElevatedButton(
                                  onPressed: _applyFilters,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                                  child: Text('Apply Filters', style: AppTextStyles.body1.copyWith(color: AppTheme.backgroundDark)),
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
                        labelStyle: AppTextStyles.body1.copyWith(color: AppTheme.textLight),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.textLight), borderRadius: BorderRadius.circular(8.0)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primaryYellow), borderRadius: BorderRadius.circular(8.0)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      ),
                      value: currentValue,
                      hint: Text("Any", style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)), // Shows "Any" when value is null
                      isExpanded: true,
                      dropdownColor: AppTheme.backgroundDark,
                      style: AppTextStyles.body1.copyWith(color: AppTheme.textLight),
                      items: items.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: onChanged,
                    );
                  }
                }
