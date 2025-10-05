// lib/widgets/profile_grid_item.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/person.dart';

class ProfileGridItem extends StatelessWidget {
  final Person person;

  const ProfileGridItem({
    super.key,
    required this.person,
  });

  @override
  Widget build(BuildContext context) {
    // Local variable for the user ID to handle nullability safely.
    final String? userId = person.uid;

    return GestureDetector(
      onTap: () {
        // --- START OF FIX 1: Handle Null userID ---
        // Only navigate if we have a valid, non-null user ID.
        if (userId != null) {
          Get.to(() => UserDetailsScreen(userID: userId));
        }
        // --- END OF FIX 1 ---
      },
      child: GridTile(
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- START OF FIX 2: Use `profilePhoto` ---
              // Use the correct field 'profilePhoto' and provide a fallback empty string if null.
              CachedNetworkImage(
                imageUrl: person.profilePhoto ?? '',
                // --- END OF FIX 2 ---
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8.0, 24.0, 8.0, 8.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  // --- START OF FIX 3: Handle Null Name ---
                  // Use the person's name, but provide a fallback if it's null.
                  child: Text(
                    person.name ?? 'Unnamed',
                    // --- END OF FIX 3 ---
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
