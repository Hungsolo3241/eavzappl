import 'package:eavzappl/utils/image_constants.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Select a random image directly in the build method.
    final selectedSplashImage = ImageConstants.getRandomSplashImage();

    return Scaffold(
      // The background color will show as letterboxing if the screen aspect ratio is not exactly 9:16
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            selectedSplashImage,
            // --- CHANGE IS HERE ---
            // BoxFit.fitHeight ensures the entire image is visible vertically, preventing cropping.
            fit: BoxFit.fitHeight,
            errorBuilder: (context, error, stackTrace) {
              // Also apply the fix to the fallback image.
              return Image.asset(ImageConstants.loginSplash, fit: BoxFit.fitHeight);
            },
          ),
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 50.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
