import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Keeps the Scaffold itself transparent
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Container( // New Container to provide a background for BoxFit.contain
        color: Colors.black, // Background color for empty areas
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(
                'images/loginSplashScreen.jpeg',
                fit: BoxFit.contain, // Changed from BoxFit.cover
              ),
            ),
            // Align widget for the CircularProgressIndicator at the bottom
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 50.0), // Adjust as needed
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
