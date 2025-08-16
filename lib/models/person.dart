import 'package:cloud_firestore/cloud_firestore.dart';

class Person
{
  //Personal Info
  String? uid;
  String? profilePhoto;
  String? email;
  String? password; // Consider if password should be stored in the Person model
  String? name;
  int? age; // Made nullable to handle potential null from Firestore
  String? phoneNumber;
  String? gender;
  String? orientation; // Added this field
  String? username; // Eve specific
  String? country; // Eve specific
  String? province; // Eve specific
  String? city; // Eve specific
  bool? lookingForBreakfast; // Eve specific
  bool? lookingForLunch; // Eve specific
  bool? lookingForDinner; // Eve specific
  bool? lookingForLongTerm; // Eve specific
  int? publishedDateTime;

  //Appearance - Eve specific
  String? height;
  String? bodyType;
  bool? drinkSelection;
  bool? smokeSelection;
  bool? meatSelection;
  bool? greekSelection;
  bool? hostSelection;
  bool? travelSelection;
  String? profession;
  String? income;
  List<String>? professionalVenues; // Field for multiple professional venues
  String? otherProfessionalVenue; // Field for other professional venue text

  //Background - Eve specific
  String? ethnicity;
  String? nationality;
  String? languages; // Can be a comma-separated string or a List<String>

  //Social Media - Eve specific
  String? instagram;
  String? twitter;


  Person({
    //Personal Info
    this.uid,
    this.profilePhoto,
    this.email,
    this.password,
    this.name,
    this.age,
    this.phoneNumber,
    this.gender,
    this.orientation, // Initialize in constructor
    this.username,
    this.country,
    this.province,
    this.city,
    this.lookingForBreakfast,
    this.lookingForLunch,
    this.lookingForDinner,
    this.lookingForLongTerm,
    this.publishedDateTime,

    //Appearance - Eve specific
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


    //Background - Eve specific
    this.ethnicity,
    this.nationality,
    this.languages,

    //Social Media - Eve specific
    this.instagram,
    this.twitter,
  });

  Map<String, dynamic> toJson() => {
    //Personal Info
    'uid': uid,
    'profilePhoto': profilePhoto,
    'email': email,
    'password': password,
    'name': name,
    'age': age,
    'phoneNumber': phoneNumber,
    'gender': gender,
    'orientation': orientation, // Include in toJson
    'username': username,
    'country': country,
    'province': province,
    'city': city,
    'lookingForBreakfast': lookingForBreakfast,
    'lookingForLunch': lookingForLunch,
    'lookingForDinner': lookingForDinner,
    'lookingForLongTerm': lookingForLongTerm,
    'publishedDateTime': publishedDateTime,

    //Appearance - Eve specific
    'height': height,
    'bodyType': bodyType,
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


    //Background - Eve specific
    'ethnicity': ethnicity,
    'nationality': nationality,
    'languages': languages,

    //Social Media - Eve specific
    'instagram': instagram,
    'twitter': twitter,
  };


  static Person fromDataSnapshot(DocumentSnapshot snapshot)
  {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return Person(
      //Personal Info
      uid: dataSnapshot['uid'] as String?, // Explicit cast
      profilePhoto: dataSnapshot['profilePhoto'] as String?, // Explicit cast
      email: dataSnapshot['email'] as String?, // Explicit cast
      password: dataSnapshot['password'] as String?, // Explicit cast
      name: dataSnapshot['name'] as String?, // Explicit cast
      age: dataSnapshot['age'] as int?, // Explicit cast, ensure Firestore stores as number
      phoneNumber: dataSnapshot['phoneNumber'] as String?, // Explicit cast
      gender: dataSnapshot['gender'] as String?, // Explicit cast
      orientation: dataSnapshot['orientation'] as String?, // Explicit cast
      username: dataSnapshot['username'] as String?, // Explicit cast
      country: dataSnapshot['country'] as String?, // Explicit cast
      province: dataSnapshot['province'] as String?, // Explicit cast
      city: dataSnapshot['city'] as String?, // Explicit cast
      lookingForBreakfast: dataSnapshot['lookingForBreakfast'] as bool?, // Explicit cast
      lookingForLunch: dataSnapshot['lookingForLunch'] as bool?, // Explicit cast
      lookingForDinner: dataSnapshot['lookingForDinner'] as bool?, // Explicit cast
      lookingForLongTerm: dataSnapshot['lookingForLongTerm'] as bool?, // Explicit cast
      publishedDateTime: dataSnapshot['publishedDateTime'] as int?, // Explicit cast

      //Appearance - Eve specific
      height: dataSnapshot['height'] as String?, // Explicit cast
      bodyType: dataSnapshot['bodyType'] as String?, // Explicit cast
      drinkSelection: dataSnapshot['drinkSelection'] as bool?, // Explicit cast
      smokeSelection: dataSnapshot['smokeSelection'] as bool?, // Explicit cast
      meatSelection: dataSnapshot['meatSelection'] as bool?, // Explicit cast
      greekSelection: dataSnapshot['greekSelection'] as bool?, // Explicit cast
      hostSelection: dataSnapshot['hostSelection'] as bool?, // Explicit cast
      travelSelection: dataSnapshot['travelSelection'] as bool?, // Explicit cast
      profession: dataSnapshot['profession'] as String?, // Explicit cast
      income: dataSnapshot['income'] as String?, // Explicit cast
      professionalVenues: dataSnapshot['professionalVenues'] == null
          ? null
          : List<String>.from(dataSnapshot['professionalVenues']), // MODIFIED LINE
      otherProfessionalVenue: dataSnapshot['otherProfessionalVenue'] as String?, // Explicit cast


      //Background - Eve specific
      ethnicity: dataSnapshot['ethnicity'] as String?, // Explicit cast
      nationality: dataSnapshot['nationality'] as String?, // Explicit cast
      languages: dataSnapshot['languages'] as String?, // Explicit cast (If it's a list, this needs changing)

      //Social Media - Eve specific
      instagram: dataSnapshot['instagram'] as String?, // Explicit cast
      twitter: dataSnapshot['twitter'] as String?, // Explicit cast
    );
  }
}
