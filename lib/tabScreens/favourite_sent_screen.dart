import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavouriteSentScreen extends StatelessWidget {
  const FavouriteSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the already initialized controller.
    final ProfileController profileController = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Favourites', style: TextStyle(color: Colors.yellow[700])),
        backgroundColor: Colors.black87,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Obx(() {
        // Correctly get the list of favorite Person objects from the controller.
        final List<Person> favouriteProfiles = profileController.usersIHaveFavourited;

        if (favouriteProfiles.isEmpty) {
          return const Center(
            child: Text(
              "You haven't favorited anyone yet.",
              style: TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.75,
          ),
          itemCount: favouriteProfiles.length,
          itemBuilder: (context, index) {
            return _FavoriteGridItem(person: favouriteProfiles[index]);
          },
        );
      }),
    );
  }
}

/// A dedicated widget to display a single user in the favorites grid.
class _FavoriteGridItem extends StatelessWidget {
  const _FavoriteGridItem({required this.person});

  final Person person;

  // Static constant for placeholder URL
  static const String _placeholderUrl = 'https://via.placeholder.com/150';

  String get _imageUrl =>
      person.profilePhoto != null && person.profilePhoto!.isNotEmpty
          ? person.profilePhoto!
          : _placeholderUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (person.uid != null) {
          Get.to(() => UserDetailsScreen(userID: person.uid!));
        } else {
          log(
            'Tap failed: UID is null for ${person.name}',
            name: 'FavouriteSentScreen',
          );
          Get.snackbar('Error', 'User ID is missing. Cannot open details.');
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: _imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) {
                  log(
                    'Error loading image $_imageUrl for ${person.name}',
                    name: 'FavouriteSentScreen',
                    error: error,
                  );
                  return const Center(
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                person.age != null ? '${person.name ?? 'N/A'} • ${person.age}' : (person.name ?? 'N/A'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.yellow[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}