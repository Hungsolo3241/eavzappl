import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AuthenticationController extends GetxController
{
  static AuthenticationController authController = Get.find();

  late Rx<File?> _pickedFile = Rx<File?>(null); // Initialize with null
  File? get profilePhoto => _pickedFile.value;

  // Method to be called to initialize _pickedFile, perhaps in an onInit or constructor if needed immediately
  // For now, it's initialized above.

  pickImageFromGallery() async
  {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if(imageFile != null)
    {
      Get.snackbar("Profile Picture", "You have successfully selected your profile picture!");
      _pickedFile.value = File(imageFile.path); // Assign to .value
      _pickedFile.refresh(); // Tell GetX to update listeners
    }
    else
    {
      Get.snackbar("Profile Picture", "Image selection cancelled.");
    }
  }

  captureImageFromPhoneCamera() async
  {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.camera);

    if(imageFile != null)
    {
      Get.snackbar("Profile Picture", "You have successfully captured your profile picture!");
      _pickedFile.value = File(imageFile.path); // Assign to .value
      _pickedFile.refresh(); // Tell GetX to update listeners
    }
    else
    {
      Get.snackbar("Profile Picture", "Image capture cancelled.");
    }
  }
} // Added missing closing brace
