// lib/utils/image_constants.dart
import 'dart:math';

class ImageConstants {
  // Prevent instantiation
  ImageConstants._();

  // --- Branding / Splash ---
  static const String loginSplash = 'images/loginSplashScreen.jpeg';

  // --- NEW: A list of all possible splash backgrounds ---
  static const List<String> splashBackgrounds = [
    'images/splash_1.jpeg',
    'images/splash_2.jpeg',
    'images/splash_3.jpeg',
    'images/splash_4.jpeg',
    // Add as many image paths as you want here
  ];

  // --- NEW: A helper function to get a random splash image ---
  static String getRandomSplashImage() {
    final random = Random();
    return splashBackgrounds[random.nextInt(splashBackgrounds.length)];
  }

  // --- Avatars ---
  static const String adamAvatar = 'images/adam_avatar.jpeg';
  static const String eveAvatar = 'images/eves_avatar.jpeg';

  // --- Favourites ---
  static const String faveFull = 'images/full_fave.png';
  static const String faveDefault = 'images/default_fave.png';

  // --- Likes ---
  static const String likeFull = 'images/full_like.png';
  static const String likeHalf = 'images/half_like.png';
  static const String likeDefault = 'images/default_like.png';

  // --- Messaging ---
  static const String messageDefault = 'images/default_message.png';
}
