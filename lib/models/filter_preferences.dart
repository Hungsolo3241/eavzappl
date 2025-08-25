import 'package:flutter/material.dart';

class FilterPreferences {
  RangeValues? ageRange;
  String? gender;
  String? ethnicity; // "Any" will be represented by null or a specific string
  bool? wantsHost;    // true for "Yes", false for "No", null for "Any"
  bool? wantsTravel;  // true for "Yes", false for "No", null for "Any"
  String? profession;
  String? country;
  String? province;
  String? city;

  FilterPreferences({
    this.ageRange,
    this.gender,
    this.ethnicity = "Any", // Default to "Any"
    this.wantsHost,
    this.wantsTravel,
    this.profession = "Any", // Default to "Any"
    this.country,
    this.province,
    this.city,
  });

  // Method to check if any filters are actively set
  bool isDefault() {
    return ageRange == null &&
        (ethnicity == null || ethnicity == "Any") &&
        (gender == null || gender == "Any") &&
        wantsHost == null &&
        wantsTravel == null &&
        (profession == null || profession == "Any") &&
        (country == null || country!.isEmpty || country == "Any") &&
        (province == null || province!.isEmpty || province == "Any") &&
        (city == null || city!.isEmpty || city == "Any");
  }

  // copyWith method to easily create a new instance with updated values
  FilterPreferences copyWith({
    RangeValues? ageRange,
    String? ethnicity,
    String? gender,
    bool? wantsHost,
    bool? wantsTravel,
    String? profession,
    String? country,
    String? province,
    String? city,
    bool clearAgeRange = false,
    bool clearEthnicity = false,
    bool clearGender = false,
    bool clearWantsHost = false,
    bool clearWantsTravel = false,
    bool clearProfession = false,
    bool clearCountry = false,
    bool clearProvince = false,
    bool clearCity = false,
  }) {
    return FilterPreferences(
      ageRange: clearAgeRange ? null : ageRange ?? this.ageRange,
      ethnicity: clearEthnicity ? "Any" : ethnicity ?? this.ethnicity,
      gender: clearGender ? "Any" : gender ?? this.gender,
      wantsHost: clearWantsHost ? null : wantsHost ?? this.wantsHost,
      wantsTravel: clearWantsTravel ? null : wantsTravel ?? this.wantsTravel,
      profession: clearProfession ? "Any" : profession ?? this.profession,
      country: clearCountry ? null : country ?? this.country,
      province: clearProvince ? null : province ?? this.province,
      city: clearCity ? null : city ?? this.city,
    );
  }
}
