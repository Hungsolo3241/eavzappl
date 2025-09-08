import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart'; // Still needed for the gallery images
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/person.dart' as model;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  model.Person? _currentUserData;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _professionController;

  String? _mainProfessionCategory;

  final List<String> _professionalVenueOptions = [
    "The Grand Gentlemen's Club - JHB", "Blu Night Revue Bar - Haarties", "Royal Park Hotel - JHB",
    "XO Lounge - JHB", "Cheeky Tiger Gentlemen's Club - JHB", "The Summit Club  - JHB",
    "Chivalry Gentlemen's Lounge - JHB", "The Diplomat Club -JHB", "Manhattan - Vaal", "White House - JHB",
    "Mavericks Revue Bar - CPT", "Stilettos Gentlemen's Club - CPT", "Lush Capetown - CPT", "The Pynk - DBN", "Wonder Lounge - DBN"
  ];
  Map<String, bool> _selectedProfessionalVenues = {};
  bool _professionalVenueOtherSelected = false;
  late TextEditingController _professionalVenueOtherNameController;

  final List<String> _mainProfessionCategoriesList = ["Student", "Freelancer", "Professional"];

  final Map<String, Map<String, List<String>>> africanLocations = {
    'South Africa': {
      'Gauteng': ['Johannesburg', 'Pretoria', 'Vereeniging'], 'Western Cape': ['Cape Town', 'Stellenbosch', 'Paarl'],
      'KwaZulu-Natal': ['Durban', 'Pietermaritzburg', 'Richards Bay'],
    },
    'Nigeria': {
      'Lagos': ['Ikeja', 'Lekki', 'Badagry'], 'Abuja (FCT)': ['Central Business District', 'Garki', 'Wuse'],
      'Rivers': ['Port Harcourt', 'Bonny', 'Okrika'],
    },
    'Kenya': {
      'Nairobi': ['Nairobi CBD', 'Westlands', 'Karen'], 'Mombasa': ['Mombasa Island', 'Nyali', 'Likoni'],
      'Kisumu': ['Kisumu City', 'Ahero', 'Maseno'],
    },
  };

  // --- START OF ADDING ASIAN LOCATIONS ---
  final Map<String, Map<String, List<String>>> asianLocations = {
    'Vietnam': {
      'Hanoi Capital Region': ['Hanoi', 'Haiphong'],
      'Ho Chi Minh City Region': ['Ho Chi Minh City', 'Can Tho'],
      'Da Nang Province': ['Da Nang', 'Hoi An'],
    },
    'Thailand': {
      'Bangkok Metropolitan Region': ['Bangkok', 'Nonthaburi', 'Samut Prakan'],
      'Chiang Mai Province': ['Chiang Mai City', 'Chiang Rai City'],
      'Phuket Province': ['Phuket Town', 'Patong'],
    },
    'Indonesia': {
      'Jakarta Special Capital Region': ['Jakarta', 'South Tangerang'],
      'Bali Province': ['Denpasar', 'Ubud', 'Kuta'],
      'West Java Province': ['Bandung', 'Bogor'],
    }
  };

  late final Map<String, Map<String, List<String>>> allLocations;
  // --- END OF ADDING ASIAN LOCATIONS ---

  List<String> _countriesList = [];
  List<String> _provincesList = [];
  List<String> _citiesList = [];
  String? _selectedCountry;
  String? _selectedProvince;
  String? _selectedCity;

  // Ethnicity
  final List<String> _ethnicityOptions = [
    "Black", "White", "Asian", "Mixed", "Other", "Prefer not to say"
  ];
  String? _selectedEthnicity;

  final ImagePicker _picker = ImagePicker();
  List<File?> _pickedImages = List.filled(5, null);
  List<String?> _imageUrls = List.filled(5, null);

  File? _pickedMainProfileImageFile;
  String? _currentMainProfileImageUrl;

  final String evePlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Feves_avatar.jpeg?alt=media&token=75b9c3f5-72c1-42db-be5c-471cc0d88c05';
  final String adamPlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Fadam_avatar.jpeg?alt=media&token=997423ec-96a4-42d6-aea8-c8cb80640ca0';
  // UPDATED genericPlaceholderUrl to use your Firebase Storage image:
  final String genericPlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Fplaceholder_avatar.png?alt=media&token=98256561-2bac-4595-8e54-58a5c486a427';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _phoneController = TextEditingController();
    _professionController = TextEditingController();
    _professionalVenueOtherNameController = TextEditingController();

    // --- START OF INITIALIZING ALL LOCATIONS ---
    allLocations = {...africanLocations, ...asianLocations};
    // --- END OF INITIALIZING ALL LOCATIONS ---

    for (var venue in _professionalVenueOptions) {
      _selectedProfessionalVenues[venue] = false;
    }

    _countriesList = allLocations.keys.toList(); // MODIFIED
    _provincesList = [];
    _citiesList = [];

    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _professionController.dispose();
    _professionalVenueOtherNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    setState(() { _isLoading = true; });
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          _currentUserData = model.Person.fromDataSnapshot(userDoc);
          final data = userDoc.data() as Map<String, dynamic>;

          _nameController.text = _currentUserData?.name ?? '';
          _ageController.text = _currentUserData?.age?.toString() ?? '';
          _phoneController.text = _currentUserData?.phoneNumber ?? '';


          _currentMainProfileImageUrl = data['profilePhoto'] as String?;

          _selectedCountry = _currentUserData?.country;
          if (_selectedCountry != null && allLocations.containsKey(_selectedCountry)) { // MODIFIED
            _provincesList = allLocations[_selectedCountry!]!.keys.toList(); // MODIFIED
            _selectedProvince = _currentUserData?.province;
            if (_selectedProvince != null && allLocations[_selectedCountry!]!.containsKey(_selectedProvince)) { // MODIFIED
              _citiesList = allLocations[_selectedCountry!]![_selectedProvince!]!; // MODIFIED
              _selectedCity = _currentUserData?.city;
              if (_selectedCity != null && !_citiesList.contains(_selectedCity)) {
                _selectedCity = null;
              }
            } else {
              _selectedProvince = null; _selectedCity = null; _citiesList = [];
            }
          } else {
            _selectedCountry = null; _selectedProvince = null; _selectedCity = null;
            _provincesList = []; _citiesList = [];
          }

          _selectedEthnicity = _currentUserData?.ethnicity; // Load ethnicity

          String? currentProfession = _currentUserData?.profession;
          if (_currentUserData?.orientation?.toLowerCase() == 'eve') {
            if (currentProfession == "Student" || currentProfession == "Freelancer") {
              _mainProfessionCategory = currentProfession;
              _professionController.clear();
            } else if (currentProfession != null && currentProfession.isNotEmpty) {
              _mainProfessionCategory = "Professional";
              _professionController.text = currentProfession;
            } else {
              _mainProfessionCategory = null;
              _professionController.clear();
            }

            _currentUserData?.professionalVenues?.forEach((venueName) {
              if (_selectedProfessionalVenues.containsKey(venueName)) {
                _selectedProfessionalVenues[venueName] = true;
              }
            });
            if (_currentUserData?.otherProfessionalVenue != null && _currentUserData!.otherProfessionalVenue!.isNotEmpty) {
              _professionalVenueOtherSelected = true;
              _professionalVenueOtherNameController.text = _currentUserData!.otherProfessionalVenue!;
            } else {
              _professionalVenueOtherSelected = false; _professionalVenueOtherNameController.clear();
            }
          } else {
            _professionController.text = currentProfession ?? '';
            _mainProfessionCategory = null;
          }

          for (int i = 0; i < 5; i++) {
            _imageUrls[i] = data['urlImage${i + 1}'] as String?;
          }
        } else {
          Get.snackbar("Error", "Could not load user profile. Document does not exist or has no data.", colorText: Colors.white, backgroundColor: Colors.red);
        }
      } catch (e) {

        Get.snackbar("Error", "Failed to load profile data: ${e.toString()}", colorText: Colors.white, backgroundColor: Colors.red);
      }
    } else {
      Get.snackbar("Error", "No user logged in.", colorText: Colors.white, backgroundColor: Colors.red);
    }
    setState(() { _isLoading = false; });
  }

  String _getPlaceholderUrlForSlot(int index) {
    if (_currentUserData?.orientation?.toLowerCase() == 'eve') return evePlaceholderUrl;
    if (_currentUserData?.orientation?.toLowerCase() == 'adam') return adamPlaceholderUrl;
    return '${genericPlaceholderUrl}&index=${index + 1}';
  }

  Future<void> _pickMainProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile != null) {
        setState(() {
          _pickedMainProfileImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar("Image Error", "Failed to pick main profile image: ${e.toString()}", colorText: Colors.white, backgroundColor: Colors.red);
    }
  }

  Future<void> _pickGalleryImage(int slotIndex, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
          compressQuality: 70, maxWidth: 600, maxHeight: 600,
          uiSettings: [
            AndroidUiSettings(toolbarTitle: 'Crop Image', toolbarColor: Colors.black54,
                toolbarWidgetColor: Colors.blueGrey, initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
            IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true, resetAspectRatioEnabled: false,
                aspectRatioPickerButtonHidden: true, doneButtonTitle: "Crop", cancelButtonTitle: "Cancel"),
          ],);
        if (croppedFile != null) {
          setState(() { _pickedImages[slotIndex] = File(croppedFile.path); });
        }
      }
    } catch (e) {
      Get.snackbar("Image Error", "Failed to pick or crop image: ${e.toString()}", colorText: Colors.white, backgroundColor: Colors.red);
    }
  }

  void _showGalleryImageSourceActionSheet(int slotIndex) {
    showModalBottomSheet(context: context, builder: (BuildContext context) {
      return SafeArea(child: Wrap(children: <Widget>[
        ListTile(leading: const Icon(Icons.photo_library, color: Colors.blueGrey), title: const Text('Photo Library', style: TextStyle(color: Colors.green)),
            onTap: () { _pickGalleryImage(slotIndex, ImageSource.gallery); Navigator.of(context).pop(); }),
        ListTile(leading: const Icon(Icons.photo_camera, color: Colors.blueGrey), title: const Text('Camera', style: TextStyle(color: Colors.green)),
            onTap: () { _pickGalleryImage(slotIndex, ImageSource.camera); Navigator.of(context).pop(); }),
      ],));
    },);
  }



  Widget _buildGalleryImageSlot(int index) {
    Widget imageWidget;

    if (_pickedImages[index] != null) {

      imageWidget = Image.file(_pickedImages[index]!, width: 120, height: 120, fit: BoxFit.cover);
    } else if (_imageUrls[index] != null && _imageUrls[index]!.isNotEmpty) {

      imageWidget = Image.network(
        _imageUrls[index]!,
        width: 120, height: 120, fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
        },
        errorBuilder: (context, error, stackTrace) {
          String placeholderUrl = _getPlaceholderUrlForSlot(index);

          return Image.network(
            placeholderUrl,
            width: 120, height: 120, fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
            },
            errorBuilder: (context, error, stackTrace) {

              return Container(width: 120, height: 120, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400]));
            },
          );
        },
      );
    } else {
      // This is the path for default placeholders if _imageUrls[index] is null or empty
      String placeholderUrl = _getPlaceholderUrlForSlot(index);

      imageWidget = Image.network(
          placeholderUrl,
          width: 120, height: 120, fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
          },
          errorBuilder: (c, e, s) {

            return Container(width: 120, height: 120, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400]));
          });
    }
    return Column(children: [
      Container(width: 120, height: 120, margin: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8.0)),
          clipBehavior: Clip.antiAlias, child: imageWidget),
      ElevatedButton(onPressed: () => _showGalleryImageSourceActionSheet(index), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
          child: const Text("Change", style: TextStyle(color: Colors.white))),
    ],);
  }



  Future<String?> _uploadMainProfileFileToFirebaseStorage(File file, String userId) async {
    try {
      String fileName = 'main_profile_pic_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      Reference ref = FirebaseStorage.instance.ref().child('main_profile_pictures/$userId/$fileName');
      TaskSnapshot task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (e) {
      Get.snackbar("Upload Error", "Failed to upload main profile picture: ${e.toString()}", colorText: Colors.white, backgroundColor: Colors.red);
      return null;
    }
  }


  Future<String?> _uploadGalleryFileToFirebaseStorage(File file, String userId, int slotIndex) async {
    try {
      String fileName = 'gallery_image_${slotIndex}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      Reference ref = FirebaseStorage.instance.ref().child('gallery_images/$userId/$fileName');
      TaskSnapshot task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (e) {
      Get.snackbar("Upload Error", "Failed to upload gallery image $slotIndex: ${e.toString()}", colorText: Colors.white, backgroundColor: Colors.red);
      return null;
    }
  }


  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar("Input Error", "Please correct the errors in the form.", colorText: Colors.white, backgroundColor: Colors.orange);
      return;
    }
    if (_currentUserData == null) {
      Get.snackbar("Error", "User data not loaded.", colorText: Colors.white, backgroundColor: Colors.red); return;
    }
    setState(() { _isLoading = true; });

    String? newMainProfilePicUrl = _currentMainProfileImageUrl;
    if (_pickedMainProfileImageFile != null) {
      newMainProfilePicUrl = await _uploadMainProfileFileToFirebaseStorage(_pickedMainProfileImageFile!, _currentUserData!.uid!);
      if (newMainProfilePicUrl == null) {
        setState(() { _isLoading = false; });
        Get.snackbar("Save Error", "Main profile picture upload failed. Please try again.", colorText: Colors.white, backgroundColor: Colors.red);
        return;
      }
    }

    List<String?> finalImageUrls = List.from(_imageUrls);
    for (int i = 0; i < _pickedImages.length; i++) {
      if (_pickedImages[i] != null) {
        String? url = await _uploadGalleryFileToFirebaseStorage(_pickedImages[i]!, _currentUserData!.uid!, i);
        if (url != null) { finalImageUrls[i] = url; } else {
          setState(() { _isLoading = false; });
          Get.snackbar("Save Error", "Gallery image upload failed. Please try again.", colorText: Colors.white, backgroundColor: Colors.red); return;
        }
      }
    }

    String professionToSave = ""; List<String> updatedProfessionalVenues = []; String? updatedOtherProfessionalVenue;
    if (_currentUserData?.orientation?.toLowerCase() == 'eve') {
      if (_mainProfessionCategory == "Student" || _mainProfessionCategory == "Freelancer") {
        professionToSave = _mainProfessionCategory ?? "";
      } else if (_mainProfessionCategory == "Professional") {
        professionToSave = _professionController.text.trim(); // This line stores the specific profession
      }
      if(_mainProfessionCategory == "Professional") {
        _selectedProfessionalVenues.forEach((venueName, isSelected) { if (isSelected) updatedProfessionalVenues.add(venueName); });
        if (_professionalVenueOtherSelected) {
          updatedOtherProfessionalVenue = _professionalVenueOtherNameController.text.trim();
        } else {
          updatedOtherProfessionalVenue = null;
        }
      }
    } else {
      professionToSave = _professionController.text.trim();
    }

    Map<String, dynamic> dataToUpdate = {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()),
      'phoneNumber': _phoneController.text.trim(),
      'country': _selectedCountry, 'province': _selectedProvince, 'city': _selectedCity,
      'ethnicity': _selectedEthnicity, // Save ethnicity
      'profession': professionToSave,
      'profilePhoto': newMainProfilePicUrl,
      'urlImage1': finalImageUrls[0], 'urlImage2': finalImageUrls[1],
      'urlImage3': finalImageUrls[2], 'urlImage4': finalImageUrls[3],
      'urlImage5': finalImageUrls[4],
    };

    if (_currentUserData?.orientation?.toLowerCase() == 'eve' && _mainProfessionCategory == "Professional") {
      dataToUpdate['professionalVenues'] = updatedProfessionalVenues;
      dataToUpdate['otherProfessionalVenue'] = updatedOtherProfessionalVenue;
    } else if (_currentUserData?.orientation?.toLowerCase() == 'eve') {
      dataToUpdate['professionalVenues'] = [];
      dataToUpdate['otherProfessionalVenue'] = null;
    }

    if (dataToUpdate['age'] == null && _ageController.text.trim().isEmpty) dataToUpdate.remove('age');
    else if (dataToUpdate['age'] == null && _ageController.text.trim().isNotEmpty) dataToUpdate['age'] = null;
    if (professionToSave.isEmpty && (_mainProfessionCategory == "Professional" || _currentUserData?.orientation?.toLowerCase() != 'eve')) {
      dataToUpdate['profession'] = "";
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUserData!.uid).update(dataToUpdate);
      setState(() {
        _currentMainProfileImageUrl = newMainProfilePicUrl;
        _pickedMainProfileImageFile = null;
        _imageUrls = List.from(finalImageUrls);
        _pickedImages = List.filled(5, null);
      });
      Get.snackbar("Success", "Profile updated successfully!", colorText: Colors.white, backgroundColor: Colors.green);
      Get.back(result: true);
    } catch (e) {
      Get.snackbar("Save Error", "Failed to update profile: ${e.toString()}", colorText: Colors.white, backgroundColor: Colors.red);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller, String label = "", IconData? icon,
    TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator, bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller, enabled: enabled,
        decoration: InputDecoration(
          labelText: label, labelStyle: TextStyle(color: Colors.blueGrey),
          prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey, width: 2.0), borderRadius: BorderRadius.circular(8.0)),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8.0)),
          disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.0)),
        ),
        style: TextStyle(color: enabled ? Colors.white70 : Colors.grey),
        keyboardType: keyboardType, inputFormatters: inputFormatters, validator: validator,
      ),);
  }

  Widget _buildDropdownFormField<T>({
    required String label, IconData? icon, T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    String? Function(T?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label, labelStyle: TextStyle(color: Colors.blueGrey),
          prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey, width: 2.0), borderRadius: BorderRadius.circular(8.0)),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8.0)),
          disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.0)),
        ),
        style: TextStyle(color: enabled ? Colors.white70 : Colors.grey),
        dropdownColor: Colors.grey[800],
        value: value, items: items, onChanged: enabled ? onChanged : null, validator: validator, isExpanded: true,
      ),);
  }

  // Current file path: C:/dev/flutter_projects/eavzappl/lib/accountSettingsScreen/edit_profile_screen.dart.
// ... other code from your file ...

  @override
  Widget build(BuildContext context) {
    print("Building EditProfileScreen. _currentMainProfileImageUrl: $_currentMainProfileImageUrl");
    final bool isEveOrientation = _currentUserData?.orientation?.toLowerCase() == 'eve';

    return Scaffold(
        appBar: AppBar(
            title: const Text("Edit Profile"), centerTitle: true,
            titleTextStyle: const TextStyle(color: Colors.blueGrey, fontSize: 20, fontWeight: FontWeight.bold),
            iconTheme: const IconThemeData(color: Colors.blueGrey), backgroundColor: Colors.black54,
            actions: [IconButton(icon: Icon(Icons.save, color: Colors.yellow[700]), onPressed: _isLoading ? null : _saveProfileChanges, tooltip: "Save Changes")]),
        body: _isLoading && _currentUserData == null
            ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
            : _currentUserData == null
            ? const Center(child: Text("Could not load user profile.", style: TextStyle(color: Colors.red, fontSize: 16)))
            : SafeArea( // <----------------------------------------- ONLY THIS LINE ADDED
          child: SingleChildScrollView( // Existing SingleChildScrollView
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Column(
                      children: [
                        Text("Main Profile Picture", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blueGrey)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _pickMainProfileImage,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade700,
                            backgroundImage: _pickedMainProfileImageFile != null
                                ? FileImage(_pickedMainProfileImageFile!)
                                : (_currentMainProfileImageUrl != null && _currentMainProfileImageUrl!.isNotEmpty)
                                ? NetworkImage(_currentMainProfileImageUrl!)
                                : null,
                            child: (_pickedMainProfileImageFile == null && (_currentMainProfileImageUrl == null || _currentMainProfileImageUrl!.isEmpty))
                                ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                                : null,
                          ),
                        ),
                        TextButton(
                          onPressed: _pickMainProfileImage,
                          child: const Text("Change Main Photo", style: TextStyle(color: Colors.blueGrey)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.blueGrey, thickness: 2),
                  const SizedBox(height: 20),

                  Text("Profile Gallery Images", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  Text("Keep it Real: Please only upload genuine photos of yourself. To maintain a trustworthy community, accounts found catfishing will be permanently banned.", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.yellow[700], fontStyle: FontStyle.italic)),
                  const SizedBox(height: 10),
                  Center( // Wrap the Wrap widget with a Center widget
                    child: Wrap(spacing: 8.0, runSpacing: 8.0, alignment: WrapAlignment.center, children: List.generate(5, (index) => _buildGalleryImageSlot(index))),
                  ),
                  const SizedBox(height: 24),
                  Text("Profile Details", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blueGrey)),
                  const SizedBox(height: 16),

                  _buildTextFormField(controller: _nameController, label: "Name", icon: Icons.person, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null),
                  _buildTextFormField(controller: _ageController, label: "Age", icon: Icons.cake, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; final age = int.tryParse(v.trim()); if (age == null) return 'Invalid age'; if (age < 18) return 'Must be 18 or older'; if (age > 120) return 'Invalid age'; return null; }),
                  _buildTextFormField(controller: _phoneController, label: "Phone Number", icon: Icons.phone, keyboardType: TextInputType.phone, validator: (v) { if (v == null || v.trim().isEmpty) return null; if (v.replaceAll(RegExp(r'\\D'), '').length < 7) return 'Enter a valid phone number'; return null; }),

                  _buildDropdownFormField<String>(
                    label: "Country", icon: Icons.public, value: _selectedCountry,
                    items: _countriesList.map((country) => DropdownMenuItem(value: country, child: Text(country, style: TextStyle(color: Colors.white70)))).toList(),
                    onChanged: (newValue) { setState(() {
                      _selectedCountry = newValue; _selectedProvince = null; _selectedCity = null;
                      _provincesList = newValue != null && allLocations.containsKey(newValue) ? allLocations[newValue]!.keys.toList() : []; // MODIFIED
                      _citiesList = []; }); },
                    validator: (value) => value == null ? 'Please select a country' : null,
                  ),
                  _buildDropdownFormField<String>(
                    label: "Province/State", icon: Icons.landscape, value: _selectedProvince, enabled: _selectedCountry != null,
                    items: _provincesList.map((province) => DropdownMenuItem(value: province, child: Text(province, style: TextStyle(color: Colors.white70)))).toList(),
                    onChanged: (newValue) { setState(() {
                      _selectedProvince = newValue; _selectedCity = null;
                      _citiesList = (newValue != null && _selectedCountry != null && allLocations.containsKey(_selectedCountry!) && allLocations[_selectedCountry!]!.containsKey(newValue)) ? allLocations[_selectedCountry!]![newValue]! : []; // MODIFIED
                    }); },
                    validator: (value) => _selectedCountry != null && value == null ? 'Please select a province/state' : null,
                  ),
                  _buildDropdownFormField<String>(
                    label: "City", icon: Icons.location_city, value: _selectedCity, enabled: _selectedProvince != null,
                    items: _citiesList.map((city) => DropdownMenuItem(value: city, child: Text(city, style: TextStyle(color: Colors.white70)))).toList(),
                    onChanged: (newValue) { setState(() { _selectedCity = newValue; }); },
                    validator: (value) => _selectedProvince != null && value == null ? 'Please select a city' : null,
                  ),

                  _buildDropdownFormField<String>( // Ethnicity Dropdown
                    label: "Ethnicity", icon: Icons.diversity_3, value: _selectedEthnicity,
                    items: _ethnicityOptions.map((ethnicity) => DropdownMenuItem(value: ethnicity, child: Text(ethnicity, style: TextStyle(color: Colors.white70)))).toList(),
                    onChanged: (newValue) { setState(() { _selectedEthnicity = newValue; }); },
                    validator: (value) => null, // Optional: make it required if needed
                  ),

                  if (isEveOrientation) ...[
                    _buildDropdownFormField<String>(
                      label: "I am a...", icon: Icons.work_outline, value: _mainProfessionCategory,
                      items: _mainProfessionCategoriesList.map((type) => DropdownMenuItem(value: type, child: Text(type, style: TextStyle(color: Colors.white70)))).toList(),
                      onChanged: (newValue) { setState(() {
                        _mainProfessionCategory = newValue;
                        if (newValue != "Professional") {
                          _professionController.clear();
                        }
                      }); },
                      validator: (value) => value == null ? 'Please select a category' : null,
                    ),
                    if (_mainProfessionCategory == "Professional")
                      _buildTextFormField(controller: _professionController, label: "Specific Profession", icon: Icons.business_center,
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Please specify your profession' : null,),
                  ] else ...[
                    _buildTextFormField(controller: _professionController, label: "Profession", icon: Icons.work, validator: (v) => null),
                  ],

                  if (isEveOrientation && _mainProfessionCategory == "Professional") ...[
                    const SizedBox(height: 24),
                    Text("Preferred Professional Venues", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._professionalVenueOptions.map((venueName) {
                      return SwitchListTile(
                          title: Text(venueName, style: TextStyle(color: Colors.white70)),
                          value: _selectedProfessionalVenues[venueName] ?? false,
                          onChanged: (bool value) { setState(() { _selectedProfessionalVenues[venueName] = value; }); },
                          activeColor: Colors.blueAccent, inactiveThumbColor: Colors.grey, inactiveTrackColor: Colors.grey.shade700);
                    }).toList(),
                    SwitchListTile(
                        title: const Text("Other Venue", style: TextStyle(color: Colors.white70)),
                        value: _professionalVenueOtherSelected,
                        onChanged: (bool value) { setState(() { _professionalVenueOtherSelected = value; if (!value) _professionalVenueOtherNameController.clear(); }); },
                        activeColor: Colors.blueAccent, inactiveThumbColor: Colors.grey, inactiveTrackColor: Colors.grey.shade700),
                    if (_professionalVenueOtherSelected)
                      _buildTextFormField(controller: _professionalVenueOtherNameController, label: "Specify Other Venue", icon: Icons.storefront,
                          validator: (value) => (_professionalVenueOtherSelected && (value == null || value.trim().isEmpty)) ? 'Please specify the venue name' : null),
                  ],

                  const SizedBox(height: 20),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [
                    Text("Orientation: ", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                    Text(_currentUserData?.orientation ?? "Not set", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueGrey)),
                  ],),),
                  const SizedBox(height: 30),
                  Center(child: _isLoading ? const CircularProgressIndicator(color: Colors.blueGrey)
                      : ElevatedButton(onPressed: _saveProfileChanges, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
                    child: const Text("Save Changes", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),),
                ],
              ),
            ),
          ), // <------------------------------------------ AND ITS CORRESPONDING BRACKET
        )
    );
  }
}
