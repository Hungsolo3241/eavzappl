// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filter_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FilterPreferences _$FilterPreferencesFromJson(Map<String, dynamic> json) =>
    FilterPreferences(
      gender: json['gender'] as String?,
      ethnicity: json['ethnicity'] as String?,
      wantsHost: json['wantsHost'] as bool?,
      wantsTravel: json['wantsTravel'] as bool?,
      profession: json['profession'] as String?,
      country: json['country'] as String?,
      province: json['province'] as String?,
      city: json['city'] as String?,
      ageRange: const RangeValuesConverter().fromJson(
        json['ageRange'] as Map<String, dynamic>?,
      ),
      relationshipStatus: json['relationshipStatus'] as String?,
      height: json['height'] as String?,
      bodyType: json['bodyType'] as String?,
      income: json['income'] as String?,
    );

Map<String, dynamic> _$FilterPreferencesToJson(FilterPreferences instance) =>
    <String, dynamic>{
      'gender': instance.gender,
      'ethnicity': instance.ethnicity,
      'wantsHost': instance.wantsHost,
      'wantsTravel': instance.wantsTravel,
      'profession': instance.profession,
      'country': instance.country,
      'province': instance.province,
      'city': instance.city,
      'relationshipStatus': instance.relationshipStatus,
      'height': instance.height,
      'bodyType': instance.bodyType,
      'income': instance.income,
      'ageRange': const RangeValuesConverter().toJson(instance.ageRange),
    };
