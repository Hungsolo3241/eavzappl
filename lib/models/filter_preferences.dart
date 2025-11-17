import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'filter_preferences.g.dart';

/// A custom converter to handle the serialization and deserialization of the
/// Flutter-specific [RangeValues] object.
class RangeValuesConverter implements JsonConverter<RangeValues?, Map<String, dynamic>?> {
  const RangeValuesConverter();

  @override
  RangeValues? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return RangeValues(
      (json['start'] as num).toDouble(),
      (json['end'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic>? toJson(RangeValues? object) {
    if (object == null) {
      return null;
    }
    return {
      'start': object.start,
      'end': object.end,
    };
  }
}

// The incorrect @RangeValuesConverter() annotation has been removed from here.
@JsonSerializable()
class FilterPreferences extends Equatable {
  final String? gender;
  final String? ethnicity;
  final bool? wantsHost;
  final bool? wantsTravel;
  final String? profession;
  final String? country;
  final String? province;
  final String? city;
  final String? relationshipStatus;
  final String? height;             // ADDED
  final String? bodyType;           // ADDED
  final String? income;             // ADDED


  @JsonKey(name: 'ageRange')
  @RangeValuesConverter()
  final RangeValues? ageRange;

  const FilterPreferences({
    this.gender,
    this.ethnicity,
    this.wantsHost,
    this.wantsTravel,
    this.profession,
    this.country,
    this.province,
    this.city,
    this.ageRange,
    this.relationshipStatus,
    this.height,                    // ADDED
    this.bodyType,                  // ADDED
    this.income,                    // ADDED
  });

  double? get minAge => ageRange?.start;
  double? get maxAge => ageRange?.end;
  bool get hostsOnly => wantsHost ?? false;
  bool get travelersOnly => wantsTravel ?? false;


  factory FilterPreferences.initial() => const FilterPreferences(
    gender: null,
    ethnicity: null,
    wantsHost: null,
    wantsTravel: null,
    profession: null,
    country: null,
    province: null,
    city: null,
    relationshipStatus: null,
    height: null,
    bodyType: null,
    income: null,
    ageRange: RangeValues(18, 85), // A safe, full range
  );


  factory FilterPreferences.fromJson(Map<String, dynamic> json) =>
      _$FilterPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$FilterPreferencesToJson(this);

  FilterPreferences copyWith({
    String? gender,
    String? ethnicity,
    bool? wantsHost,
    bool? wantsTravel,
    String? profession,
    String? country,
    String? province,
    String? city,
    RangeValues? ageRange,
    String? relationshipStatus,
    String? height,                 // ADDED
    String? bodyType,               // ADDED
    String? income,     }) {

    return FilterPreferences(
      gender: gender ?? this.gender,
      ethnicity: ethnicity ?? this.ethnicity,
      wantsHost: wantsHost ?? this.wantsHost,
      wantsTravel: wantsTravel ?? this.wantsTravel,
      profession: profession ?? this.profession,
      country: country ?? this.country,
      province: province ?? this.province,
      city: city ?? this.city,
      ageRange: ageRange ?? this.ageRange,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      height: height ?? this.height,                          // ADD THIS
      bodyType: bodyType ?? this.bodyType,                    // ADD THIS
      income: income ?? this.income,                          // ADD THIS
    );
  }

  @override
  List<Object?> get props => [
    gender,
    ethnicity,
    wantsHost,
    wantsTravel,
    profession,
    country,
    province,
    city,
    ageRange,
    relationshipStatus,
    height,                         // ADDED
    bodyType,                       // ADDED
    income,                         // ADDED
  ];
}