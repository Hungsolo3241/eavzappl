import 'package:json_annotation/json_annotation.dart';

part 'person.g.dart';

// The LikeStatus enum is better defined here or in a dedicated file if it's
// used across different models or controllers.
enum LikeStatus {
  none, // Default state
  liked, // Current user has liked the target, but not mutual (half-like)
  mutualLike, // Both users have liked each other (full-like)
}

@JsonSerializable(
  explicitToJson: true, // Needed for nested objects if any were present
  createToJson: true,
  anyMap: true, // Allows for a dynamic map from Firestore
)
class Person {
  // Personal Info
  @JsonKey(name: 'uid')
  final String? uid;

  @JsonKey(name: 'profilePhoto')
  final String? profilePhoto;

  @JsonKey(name: 'email')
  final String? email;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'age')
  final int? age;

  @JsonKey(name: 'phoneNumber')
  final String? phoneNumber;

  @JsonKey(name: 'gender')
  final String? gender;

  @JsonKey(name: 'orientation')
  final String? orientation;

  @JsonKey(name: 'username')
  final String? username;

  @JsonKey(name: 'country')
  final String? country;

  @JsonKey(name: 'province')
  final String? province;

  @JsonKey(name: 'city')
  final String? city;

  @JsonKey(name: 'lookingForBreakfast')
  final bool? lookingForBreakfast;

  @JsonKey(name: 'lookingForLunch')
  final bool? lookingForLunch;

  @JsonKey(name: 'lookingForDinner')
  final bool? lookingForDinner;

  @JsonKey(name: 'lookingForLongTerm')
  final bool? lookingForLongTerm;

  @JsonKey(name: 'publishedDateTime')
  final int? publishedDateTime;

  // Appearance
  @JsonKey(name: 'height')
  final String? height;

  @JsonKey(name: 'bodyType')
  final String? bodyType;

  @JsonKey(name: 'drinkSelection')
  final bool? drinkSelection;

  @JsonKey(name: 'smokeSelection')
  final bool? smokeSelection;

  @JsonKey(name: 'meatSelection')
  final bool? meatSelection;

  @JsonKey(name: 'greekSelection')
  final bool? greekSelection;

  @JsonKey(name: 'hostSelection')
  final bool? hostSelection;

  @JsonKey(name: 'travelSelection')
  final bool? travelSelection;

  @JsonKey(name: 'profession')
  final String? profession;

  @JsonKey(name: 'income')
  final String? income;

  @JsonKey(name: 'professionalVenues')
  final List<String>? professionalVenues;

  @JsonKey(name: 'otherProfessionalVenue')
  final String? otherProfessionalVenue;

  // Background
  @JsonKey(name: 'ethnicity')
  final String? ethnicity;

  @JsonKey(name: 'nationality')
  final String? nationality;

  @JsonKey(name: 'languages')
  final String? languages;

  // Social Media
  @JsonKey(name: 'instagram')
  final String? instagram;

  @JsonKey(name: 'twitter')
  final String? twitter;

  // Gallery Images
  @JsonKey(name: 'urlImage1')
  final String? urlImage1;

  @JsonKey(name: 'urlImage2')
  final String? urlImage2;

  @JsonKey(name: 'urlImage3')
  final String? urlImage3;

  @JsonKey(name: 'urlImage4')
  final String? urlImage4;

  @JsonKey(name: 'urlImage5')
  final String? urlImage5;

  // Note: Reactive properties like isFavorite, isLiked, hasMessage, and likeStatus
  // have been removed. This state describes the relationship between the current
  // user and this Person, and should be managed in a controller that holds this Person object.

  const Person({
    this.uid,
    this.profilePhoto,
    this.email,
    this.name,
    this.age,
    this.phoneNumber,
    this.gender,
    this.orientation,
    this.username,
    this.country,
    this.province,
    this.city,
    this.lookingForBreakfast,
    this.lookingForLunch,
    this.lookingForDinner,
    this.lookingForLongTerm,
    this.publishedDateTime,
    this.height,
    this.bodyType,
    this.drinkSelection,
    this.smokeSelection,
    this.meatSelection,
    this.greekSelection,
    this.hostSelection,
    this.travelSelection,
    this.profession,
    this.income,
    this.professionalVenues,
    this.otherProfessionalVenue,
    this.ethnicity,
    this.nationality,
    this.languages,
    this.instagram,
    this.twitter,
    this.urlImage1,
    this.urlImage2,
    this.urlImage3,
    this.urlImage4,
    this.urlImage5,
  });

  /// Connect the generated [_$PersonFromJson] function to the `fromJson` factory.
  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PersonToJson(this);

  /// Creates a copy of the current Person with the given fields replaced
  /// with the new values.
  Person copyWith({
    String? uid,
    String? profilePhoto,
    String? email,
    String? name,
    int? age,
    String? phoneNumber,
    String? gender,
    String? orientation,
    String? username,
    String? country,
    String? province,
    String? city,
    bool? lookingForBreakfast,
    bool? lookingForLunch,
    bool? lookingForDinner,
    bool? lookingForLongTerm,
    int? publishedDateTime,
    String? height,
    String? bodyType,
    bool? drinkSelection,
    bool? smokeSelection,
    bool? meatSelection,
    bool? greekSelection,
    bool? hostSelection,
    bool? travelSelection,
    String? profession,
    String? income,
    List<String>? professionalVenues,
    String? otherProfessionalVenue,
    String? ethnicity,
    String? nationality,
    String? languages,
    String? instagram,
    String? twitter,
    String? urlImage1,
    String? urlImage2,
    String? urlImage3,
    String? urlImage4,
    String? urlImage5,
  }) {
    return Person(
      uid: uid ?? this.uid,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      orientation: orientation ?? this.orientation,
      username: username ?? this.username,
      country: country ?? this.country,
      province: province ?? this.province,
      city: city ?? this.city,
      lookingForBreakfast: lookingForBreakfast ?? this.lookingForBreakfast,
      lookingForLunch: lookingForLunch ?? this.lookingForLunch,
      lookingForDinner: lookingForDinner ?? this.lookingForDinner,
      lookingForLongTerm: lookingForLongTerm ?? this.lookingForLongTerm,
      publishedDateTime: publishedDateTime ?? this.publishedDateTime,
      height: height ?? this.height,
      bodyType: bodyType ?? this.bodyType,
      drinkSelection: drinkSelection ?? this.drinkSelection,
      smokeSelection: smokeSelection ?? this.smokeSelection,
      meatSelection: meatSelection ?? this.meatSelection,
      greekSelection: greekSelection ?? this.greekSelection,
      hostSelection: hostSelection ?? this.hostSelection,
      travelSelection: travelSelection ?? this.travelSelection,
      profession: profession ?? this.profession,
      income: income ?? this.income,
      professionalVenues: professionalVenues ?? this.professionalVenues,
      otherProfessionalVenue: otherProfessionalVenue ?? this.otherProfessionalVenue,
      ethnicity: ethnicity ?? this.ethnicity,
      nationality: nationality ?? this.nationality,
      languages: languages ?? this.languages,
      instagram: instagram ?? this.instagram,
      twitter: twitter ?? this.twitter,
      urlImage1: urlImage1 ?? this.urlImage1,
      urlImage2: urlImage2 ?? this.urlImage2,
      urlImage3: urlImage3 ?? this.urlImage3,
      urlImage4: urlImage4 ?? this.urlImage4,
      urlImage5: urlImage5 ?? this.urlImage5,
    );
  }
}
