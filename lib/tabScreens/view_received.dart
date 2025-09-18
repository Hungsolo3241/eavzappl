import 'package:eavzappl/controllers/profile_controller.dart';
import 'package:eavzappl/models/person.dart';
import 'package:eavzappl/tabScreens/user_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ViewReceivedScreen extends StatelessWidget {
  ViewReceivedScreen({super.key});

  final ProfileController profileController = Get.find<ProfileController>();

  String _getImageUrl(Person person) {
    if (person.profilePhoto != null && person.profilePhoto!.isNotEmpty) {
      return person.profilePhoto!;
    }
    // Fallback placeholder
    return 'https://via.placeholder.com/150';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Viewed Your Profile', style: TextStyle(color: Colors.yellow[700])),
        backgroundColor: Colors.black87,
        automaticallyImplyLeading: false, // Assuming this is a main tab
      ),
      body: Obx(() {
        if (profileController.usersWhoViewedMeList.isEmpty) {
          return const Center(
            child: Text(
              'No one has viewed your profile in the last 36hrs.',
              style: TextStyle(fontSize: 18, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Display 2 items per row
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.75, // Adjust for desired item aspect ratio
          ),
          itemCount: profileController.usersWhoViewedMeList.length,
          itemBuilder: (context, index) {
            // Display viewers in reverse chronological order (newest first)
            final Person person = profileController.usersWhoViewedMeList.reversed.toList()[index];
            final String imageUrl = _getImageUrl(person);

            return InkWell(
              onTap: () {
                if (person.uid != null) {
                  Get.to(() => UserDetailsScreen(userID: person.uid!));
                } else {
                  Get.snackbar('Error', 'User ID is missing.');
                }
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 4.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${person.name ?? 'N/A'} • ${person.age ?? 'N/A'}',
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
          },
        );
      }),
    );
  }
}
