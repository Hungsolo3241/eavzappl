import 'package:flutter/material.dart';

class FavouriteSentFavouriteReceivedScreen extends StatefulWidget {
  const FavouriteSentFavouriteReceivedScreen({super.key});

  @override
  State<FavouriteSentFavouriteReceivedScreen> createState() => _FavouriteSentFavouriteReceivedScreenState();
}

class _FavouriteSentFavouriteReceivedScreenState extends State<FavouriteSentFavouriteReceivedScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
          child: Text(
            "Favourite Sent",
            style: TextStyle(
              color: Colors.green,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
    );
  }
}
