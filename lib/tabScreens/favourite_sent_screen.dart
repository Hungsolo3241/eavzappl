import 'package:flutter/material.dart';

class FavouriteSentScreen extends StatefulWidget {
  const FavouriteSentScreen({super.key});

  @override
  State<FavouriteSentScreen> createState() => _FavouriteSentScreenState();
}

class _FavouriteSentScreenState extends State<FavouriteSentScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
          child: Text(
            "Favourite Sent",
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
    );
  }
}
