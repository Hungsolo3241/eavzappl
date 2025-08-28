import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart'; // Import GetX for Rx types

// Define LikeStatus enum
enum LikeStatus {
  none,                     // No like interaction
  currentUserLiked,         // Current user liked target, target has not responded
  targetUserLikedCurrentUser, // Target user liked current, current user has not responded
  mutualLike,               // Both users have liked each other
}

class Person {
  //Personal Info
  String? uid;
  String? profilePhoto;
  String? email;
  String? password; // Consider if password should be stored in the Person model
  String? name;
  int? age; // Made nullable to handle potential null from Firestore
  String? phoneNumber;
  String? gender;
  String? orientation;
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

  // Favorite, like and message
  RxBool isFavorite; // Changed to RxBool
  bool isLiked = false; // We might deprecate or repurpose this later
  bool hasMessage = false;
  Rx<LikeStatus> likeStatus; // New field for detailed like status

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

    // Favorite, like and message
    bool? isFavorite, // Changed to nullable bool for constructor input
    this.isLiked = false, // Keep for now
    this.hasMessage = false,
    LikeStatus initialLikeStatus = LikeStatus.none, // Allow optional initial status
  }) : this.isFavorite = (isFavorite ?? false).obs, // Initialize RxBool
       likeStatus = initialLikeStatus.obs; // Initialize Rx field for likeStatus

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

    // Favorite, like and message
    'isFavorite': isFavorite.value, // Serialize .value of RxBool
    'isLiked': isLiked,
    'hasMessage': hasMessage,
  };

  static Person fromDataSnapshot(DocumentSnapshot snapshot) {
    var dataSnapshot = snapshot.data() as Map<String, dynamic>;

    return Person(
      //Personal Info
      uid: dataSnapshot['uid'] as String?,
      profilePhoto: dataSnapshot['profilePhoto'] as String?,
      email: dataSnapshot['email'] as String?,
      password: dataSnapshot['password'] as String?,
      name: dataSnapshot['name'] as String?,
      age: dataSnapshot['age'] as int?,
      phoneNumber: dataSnapshot['phoneNumber'] as String?,
      gender: dataSnapshot['gender'] as String?,
      orientation: dataSnapshot['orientation'] as String?,
      username: dataSnapshot['username'] as String?,
      country: dataSnapshot['country'] as String?,
      province: dataSnapshot['province'] as String?,
      city: dataSnapshot['city'] as String?,
      lookingForBreakfast: dataSnapshot['lookingForBreakfast'] as bool?,
      lookingForLunch: dataSnapshot['lookingForLunch'] as bool?,
      lookingForDinner: dataSnapshot['lookingForDinner'] as bool?,
      lookingForLongTerm: dataSnapshot['lookingForLongTerm'] as bool?,
      publishedDateTime: dataSnapshot['publishedDateTime'] as int?,

      //Appearance - Eve specific
      height: dataSnapshot['height'] as String?,
      bodyType: dataSnapshot['bodyType'] as String?,
      drinkSelection: dataSnapshot['drinkSelection'] as bool?,
      smokeSelection: dataSnapshot['smokeSelection'] as bool?,
      meatSelection: dataSnapshot['meatSelection'] as bool?,
      greekSelection: dataSnapshot['greekSelection'] as bool?,
      hostSelection: dataSnapshot['hostSelection'] as bool?,
      travelSelection: dataSnapshot['travelSelection'] as bool?,
      profession: dataSnapshot['profession'] as String?,
      income: dataSnapshot['income'] as String?,
      professionalVenues: dataSnapshot['professionalVenues'] == null
          ? null
          : List<String>.from(dataSnapshot['professionalVenues']),
      otherProfessionalVenue:
      dataSnapshot['otherProfessionalVenue'] as String?,

      //Background - Eve specific
      ethnicity: dataSnapshot['ethnicity'] as String?,
      nationality: dataSnapshot['nationality'] as String?,
      languages: dataSnapshot['languages'] as String?,

      //Social Media - Eve specific
      instagram: dataSnapshot['instagram'] as String?,
      twitter: dataSnapshot['twitter'] as String?,

      // Favorite, like and message
      // Initialize RxBool from Firestore, defaulting to false if null
      isFavorite: (dataSnapshot['isFavorite'] as bool? ?? false),
      isLiked: dataSnapshot['isLiked'] as bool? ?? false,
      hasMessage: dataSnapshot['hasMessage'] as bool? ?? false,
      // likeStatus will be initialized to LikeStatus.none by default in the constructor
      // and then updated by ProfileController based on specific like data for the current user.
    );
  }
}
