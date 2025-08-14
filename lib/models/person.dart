import 'package:cloud_firestore/cloud_firestore.dart';

class Person
{
  // Personal Info
  String? uid;
  String? profilePhoto;
  String? email;
  String? password;
  String? phoneNumber;
  String? name;
  int? age;
  String? gender;
  String? orientation;
  String? username;
  String? country;
  String? province;
  String? city;
  bool? lookingForBreakfast;
  bool? lookingForLunch;
  bool? lookingForDinner;
  bool? lookingForLongTerm;
  int? publishedDateTime;

  // Appearance
  String? height;
  String? bodyType;

  // Lifestyle
  bool? drinkSelection;
  bool? smokeSelection;
  bool? meatSelection;
  bool? greekSelection;
  bool? hostSelection;
  bool? travelSelection;
  String? profession;
  String? income;

  // Professional Venues
  List<String>? professionalVenues;
  String? otherProfessionalVenue;

  // Background
  String? ethnicity;
  String? nationality;
  String? languages;

  // Social Media
  String? instagram;
  String? twitter;

  Person({
    this.uid,
    this.profilePhoto,
    this.email,
    this.password,
    this.phoneNumber,
    this.name,
    this.age,
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

    // Appearance
    this.height,
    this.bodyType,

    // Lifestyle
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

    // Background
    this.ethnicity,
    this.nationality,
    this.languages,

    // Social Media
    this.instagram,
    this.twitter,
});

  static Person fromDataSnapshot(DocumentSnapshot snapshot)
  {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;
    return Person(
      uid: dataSnapshot['uid'] as String?,
      profilePhoto: dataSnapshot['profilePhoto'],
      email: dataSnapshot['email'],
      password: dataSnapshot['password'],
      phoneNumber: dataSnapshot['phoneNumber'],
      name: dataSnapshot['name'],
      age: dataSnapshot['age'],
      gender: dataSnapshot['gender'],
      orientation: dataSnapshot['orientation'],
      username: dataSnapshot['username'],
      country: dataSnapshot['country'],
      province: dataSnapshot['province'],
      city: dataSnapshot['city'],
      lookingForBreakfast: dataSnapshot['lookingForBreakfast'],
      lookingForLunch: dataSnapshot['lookingForLunch'],
      lookingForDinner: dataSnapshot['lookingForDinner'],
      lookingForLongTerm: dataSnapshot['lookingForLongTerm'],
      publishedDateTime: dataSnapshot['publishedDateTime'],

      // Appearance
      height: dataSnapshot['height'],
      bodyType: dataSnapshot['bodyType'],

      // Lifestyle
      drinkSelection: dataSnapshot['drinkSelection'],
      smokeSelection: dataSnapshot['smokeSelection'],
      meatSelection: dataSnapshot['meatSelection'],
      greekSelection: dataSnapshot['greekSelection'],
      hostSelection: dataSnapshot['hostSelection'],
      travelSelection: dataSnapshot['travelSelection'],
      profession: dataSnapshot['profession'],
      income: dataSnapshot['income'],
      professionalVenues: dataSnapshot['professionalVenues'],
      otherProfessionalVenue: dataSnapshot['otherProfessionalVenue'],

      // Background
      ethnicity: dataSnapshot['ethnicity'],
      nationality: dataSnapshot['nationality'],
      languages: dataSnapshot['languages'],

      // Social Media
      instagram: dataSnapshot['instagram'],
      twitter: dataSnapshot['twitter'],
    );
  }

  Map<String, dynamic> toJson()=>
      {
        // Personal info
        'profilePhoto': profilePhoto,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'name': name,
        'age': age,
        'gender': gender,
        'orientation': orientation,
        'username': username,
        'country': country,
        'province': province,
        'city': city,
        'lookingForBreakfast': lookingForBreakfast,
        'lookingForLunch': lookingForLunch,
        'lookingForDinner': lookingForDinner,
        'lookingForLongTerm': lookingForLongTerm,
        'publishedDateTime': publishedDateTime,

        // Appearance
        'height': height,
        'bodyType': bodyType,

        // Lifestyle
        'drinkSelection': drinkSelection,
        'smokeSelection': smokeSelection,
        'meatSelection': meatSelection,
        'greekSelection': greekSelection,
        'hostSelection': hostSelection,
        'travelSelection': travelSelection,
        'profession': profession,
        'income': income,
        'professionalVenues': professionalVenues,
        'otherProfessionalVenue': otherProfessionalVenue,

        // Background
        'ethnicity': ethnicity,
        'nationality': nationality,
        'languages': languages,

        // Social Media
        'instagram': instagram,
        'twitter': twitter,
      };
}