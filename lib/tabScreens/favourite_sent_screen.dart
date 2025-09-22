import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../models/person.dart';
import 'user_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavouriteSentScreen extends StatelessWidget {
  FavouriteSentScreen({super.key});

  final ProfileController profileController = Get.find<ProfileController>();

  String _getImageUrl(Person person) {
    if (person.profilePhoto != null && person.profilePhoto!.isNotEmpty) {
      return person.profilePhoto!;
    }
    // Fallback placeholder if imageProfile is null or empty
    return 'https://via.placeholder.com/150';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favourites', style: TextStyle(color: Colors.yellow[700])), // Changed from 'My Favorites'
        backgroundColor: Colors.black87, // Or your app's theme color
        automaticallyImplyLeading: false, // Assuming this is a tab screen and doesn't need a back button
      ),
      body: Obx(() {
        // MODIFIED LINE BELOW
        final List<Person> favouriteProfiles = profileController.usersProfileList.where((person) => person.isFavorite.value).toList();
        if (favouriteProfiles.isEmpty) {
          return const Center(
            child: Text(
              'You haven\'t favourited anyone yet.',
              style: TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Display 2 items per row
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.75, // Adjust for desired item aspect ratio (width / height)
          ),
          itemCount: favouriteProfiles.length,
          itemBuilder: (context, index) {
            final Person person = favouriteProfiles[index];
            final String imageUrl = _getImageUrl(person);

            return InkWell(
              onTap: () {
                if (person.uid != null) {
                  Get.to(() => UserDetailsScreen(userID: person.uid!));
                } else {
                  // This case should ideally not happen if UIDs are always present
                  Get.snackbar('Error', 'User ID is missing. Cannot open details.');
                  print('Error: UserDetails tap, UID is null for ${person.name}');
                }
              },
              child: Card(
                clipBehavior: Clip.antiAlias, // Ensures content respects card's rounded corners
                elevation: 4.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) {
                          print('Error loading image $imageUrl for ${person.name} with CachedNetworkImage: $error');
                          return const Center(
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${person.name ?? 'N/A'} • ${person.age ?? 'N/A'}', // Added age
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.yellow[700], // Added this line
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
