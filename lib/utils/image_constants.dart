// lib/utils/image_constants.dart
import 'dart:math';

class ImageConstants {
  // Prevent instantiation
  ImageConstants._();

  // --- Branding / Splash ---
  static const String loginSplash = 'images/loginSplashScreen.jpeg';

  // Dynamically generate the list of splash screen images
  static final List<String> splashBackgrounds = _generateSplashImagePaths();

  static List<String> _generateSplashImagePaths() {
    // Generates a list of paths from 'images/splashScreen/splash_1.webp' to 'images/splashScreen/splash_945.webp'
    return List.generate(945, (i) => 'images/splashScreen/splash_${i + 1}.webp');
  }

  // A helper function to get a random splash image from the generated list
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
  static const String messageDefault = 'images/default_message.webp';
}
