import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

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
  final double? maxDistance;

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
    this.maxDistance,
  });

  double? get minAge => ageRange?.start;
  double? get maxAge => ageRange?.end;
  bool get hostsOnly => wantsHost ?? false;
  bool get travelersOnly => wantsTravel ?? false;

  /// A factory constructor for creating a new [FilterPreferences] instance
  /// with default values.
  factory FilterPreferences.initial() => const FilterPreferences(
    gender: 'Any',
    ethnicity: 'Any',
    profession: 'Any',
    wantsHost: null,
    wantsTravel: null,
    ageRange: RangeValues(18, 99),
    maxDistance: 100.0,
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
    double? maxDistance,
  }) {
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
      maxDistance: maxDistance ?? this.maxDistance,
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
    maxDistance,
  ];
}