// =========== START OF REFACTORED edit_profile_screen.dart ===========

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/person.dart' as model;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eavzappl/controllers/location_controller.dart';
import 'package:eavzappl/utils/app_constants.dart';
// lib/screens/edit_profile_screen.dart
import 'package:eavzappl/pushNotifications/push_notifications.dart';
import 'package:eavzappl/models/push_notification_payload.dart';
import 'package:eavzappl/utils/app_theme.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  model.Person? _currentUserData;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _professionController;
  late TextEditingController _professionalVenueOtherNameController;

  // --- State Variables ---
  String? _mainProfessionCategory;
  final List<String> _mainProfessionCategoriesList = ["Student", "Freelancer", "Professional"];
  final Map<String, bool> _selectedProfessionalVenues = {};
  bool _professionalVenueOtherSelected = false;

  final LocationController locationController = Get.find<LocationController>();
  String? _selectedEthnicity;

  final List<String> _professionalVenueOptions = [
    "The Grand - JHB", "Blu Night Revue Bar - Haarties", "Royal Park - JHB",
    "The Summit - JHB", "Chivalry Lounge - JHB", "Manhattan - Vaal",
    "Mavericks Revue Bar - CPT", "Lush Capetown - CPT", "The Pynk - DBN", "Wonder Lounge - DBN"
  ];

  // --- Lifestyle State ---
  bool _drinkSelection = false;
  bool _smokeSelection = false;
  bool _meatSelection = false;
  bool _greekSelection = false;
  bool _hostSelection = false;
  bool _travelSelection = false;

  String? _selectedCountry;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedRelationshipStatus; // Added for consistency
  String? _selectedIncome;


  // --- Image State ---
  final ImagePicker _picker = ImagePicker();
  List<File?> _pickedImages = List.filled(5, null);
  List<String?> _imageUrls = List.filled(5, null);
  File? _pickedMainProfileImageFile;
  String? _currentMainProfileImageUrl;

  // --- Placeholders ---
  final String evePlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Feves_avatar.jpeg?alt=media&token=75b9c3f5-72c1-42db-be5c-471cc0d88c05';
  final String adamPlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Fadam_avatar.jpeg?alt=media&token=997423ec-96a4-42d6-aea8-c8cb80640ca0';
  final String genericPlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.firebasestorage.app/o/placeholder%2Fplaceholder_avatar.png?alt=media&token=98256561-2bac-4595-8e54-58a5c486a427';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _phoneController = TextEditingController();
    _professionController = TextEditingController();
    _professionalVenueOtherNameController = TextEditingController();


    for (var venue in _professionalVenueOptions) {
      _selectedProfessionalVenues[venue] = false;
    }

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
          final data = userDoc.data() as Map<String, dynamic>;
          _currentUserData = model.Person.fromJson(data);

          _nameController.text = _currentUserData?.name ?? '';
          _ageController.text = _currentUserData?.age?.toString() ?? '';
          _phoneController.text = _currentUserData?.phoneNumber ?? '';
          _currentMainProfileImageUrl = data['profilePhoto'] as String?;

          // Location
          // --- Load State for Centralized Dropdowns ---
          _selectedCountry = _currentUserData?.country;
          _selectedProvince = _currentUserData?.province;
          _selectedCity = _currentUserData?.city;
          _selectedEthnicity = _currentUserData?.ethnicity;
          _selectedRelationshipStatus = _currentUserData?.relationshipStatus;


          // --- THIS BLOCK CONTAINS THE FIX ---
          // Lifestyle
          _drinkSelection = data['drinkSelection'] ?? false;
          _smokeSelection = data['smokeSelection'] ?? false;
          _meatSelection = data['meatSelection'] ?? false;
          _greekSelection = data['greekSelection'] ?? false;
          _hostSelection = data['hostSelection'] ?? false;
          _travelSelection = data['travelSelection'] ?? false;

          _selectedIncome = data['income'] as String?;

          // Profession
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

            final venuesData = data['professionalVenues'] as List<dynamic>? ?? [];
            for (var venue in _professionalVenueOptions) {
              _selectedProfessionalVenues[venue] = venuesData.contains(venue);
            }
            _professionalVenueOtherNameController.text = data['otherProfessionalVenue'] as String? ?? '';
            _professionalVenueOtherSelected = _professionalVenueOtherNameController.text.isNotEmpty;
          } else {
            _professionController.text = currentProfession ?? '';
            _mainProfessionCategory = null;
          }

          // Images
          for (int i = 0; i < 5; i++) {
            _imageUrls[i] = data['urlImage${i + 1}'] as String?;
          }
        }
      } catch (e) {
        Get.snackbar(
          "Load Error", "Failed to load profile data: ${e.toString()}",
          colorText: Colors.white, backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        );
      }
    }
    setState(() { _isLoading = false; });
  }


  // --- REFACTORED AND CLEANED _saveProfileChanges ---
  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar("Input Error", "Please correct the errors in the form.", colorText: Colors.white, backgroundColor: Colors.orange);
      return;
    }
    if (_currentUserData?.uid == null) {
      Get.snackbar("Error", "User data not loaded.", colorText: Colors.white, backgroundColor: Colors.red);
      return;
    }
    setState(() { _isLoading = true; });

    try {
      // 1. Handle Image Uploads
      String? finalMainProfilePicUrl = _currentMainProfileImageUrl;
      if (_pickedMainProfileImageFile != null) {
        finalMainProfilePicUrl = await _uploadMainProfileFileToFirebaseStorage(_pickedMainProfileImageFile!, _currentUserData!.uid!);
      }

      List<String?> finalImageUrls = List.from(_imageUrls);
      for (int i = 0; i < _pickedImages.length; i++) {
        if (_pickedImages[i] != null) {
          String? url = await _uploadGalleryFileToFirebaseStorage(_pickedImages[i]!, _currentUserData!.uid!, i);
          if (url != null) { finalImageUrls[i] = url; }
        }
      }

      // 2. Prepare Data for Firestore
      String finalProfession;
      final isEve = _currentUserData?.orientation?.toLowerCase() == 'eve';

      if (isEve) {
        if (_mainProfessionCategory == "Professional") {
          finalProfession = _professionController.text.trim();
        } else {
          finalProfession = _mainProfessionCategory ?? ""; // Saves "Student" or "Freelancer"
        }
      } else {
        finalProfession = _professionController.text.trim();
      }


      // 3. Build the Data Map
      Map<String, dynamic> dataToUpdate = {
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'phoneNumber': _phoneController.text.trim(),
        'country': _selectedCountry,
        'province': _selectedProvince,
        'city': _selectedCity,
        'relationshipStatus': _selectedRelationshipStatus,
        'ethnicity': _selectedEthnicity,
        'profession': finalProfession,
        'profilePhoto': finalMainProfilePicUrl,

        // Lifestyle
        'drinkSelection': _drinkSelection,
        'smokeSelection': _smokeSelection,
        'meatSelection': _meatSelection,
        'greekSelection': _greekSelection,
        'hostSelection': _hostSelection,
        'travelSelection': _travelSelection,
        'income': _selectedIncome,

        // Eve-Specific
        'professionalVenues': isEve && _mainProfessionCategory == "Professional"
            ? _selectedProfessionalVenues.entries.where((e) => e.value).map((e) => e.key).toList()
            : [],
        'otherProfessionalVenue': isEve && _mainProfessionCategory == "Professional" && _professionalVenueOtherSelected
            ? _professionalVenueOtherNameController.text.trim()
            : null,

        // Gallery Images
        'urlImage1': finalImageUrls.length > 0 ? finalImageUrls[0] : null,
        'urlImage2': finalImageUrls.length > 1 ? finalImageUrls[1] : null,
        'urlImage3': finalImageUrls.length > 2 ? finalImageUrls[2] : null,
        'urlImage4': finalImageUrls.length > 3 ? finalImageUrls[3] : null,
        'urlImage5': finalImageUrls.length > 4 ? finalImageUrls[4] : null,
      };

      // 4. Update Firestore and State
      await FirebaseFirestore.instance.collection('users').doc(_currentUserData!.uid).update(dataToUpdate);

      setState(() {
        _currentMainProfileImageUrl = finalMainProfilePicUrl;
        _pickedMainProfileImageFile = null;
        _imageUrls = List.from(finalImageUrls);
        _pickedImages = List.filled(5, null);
      });

      Get.snackbar("Success", "Profile updated successfully!", colorText: Colors.white, backgroundColor: Colors.green);
      if (mounted) Get.back(result: true);

    } catch (e) {
      Get.snackbar("Save Error", "Failed to update profile: ${e.toString()}", colorText: Colors.white, backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
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

  Future<void> _pickMainProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile != null) {
        setState(() { _pickedMainProfileImageFile = File(pickedFile.path); });
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
            AndroidUiSettings(toolbarTitle: 'Crop Image', toolbarColor: Colors.black54, toolbarWidgetColor: Colors.blueGrey, initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
            IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true, resetAspectRatioEnabled: false, aspectRatioPickerButtonHidden: true, doneButtonTitle: "Crop", cancelButtonTitle: "Cancel"),
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
        ListTile(leading: const Icon(Icons.photo_library, color: Colors.blueGrey), title: const Text('Photo Library', style: TextStyle(color: Colors.green)), onTap: () { _pickGalleryImage(slotIndex, ImageSource.gallery); Navigator.of(context).pop(); }),
        ListTile(leading: const Icon(Icons.photo_camera, color: Colors.blueGrey), title: const Text('Camera', style: TextStyle(color: Colors.green)), onTap: () { _pickGalleryImage(slotIndex, ImageSource.camera); Navigator.of(context).pop(); }),
      ]));
    });
  }


  Widget _buildGalleryImageSlot(int index) {
    Widget imageWidget;
    // This logic correctly displays either a picked file, a network URL, or a placeholder.
    if (_pickedImages[index] != null) {
      imageWidget = Image.file(_pickedImages[index]!, fit: BoxFit.cover, width: 100, height: 100);
    } else if (_imageUrls.length > index && _imageUrls[index] != null && _imageUrls[index]!.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: _imageUrls[index]!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        placeholder: (context, url) => Container(
          width: 100, height: 100,
          color: Colors.grey.shade800,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.blueGrey)),
        ),
        errorWidget: (context, url, error) => Container(
            width: 100, height: 100,
            color: Colors.grey.shade800,
            child: const Icon(Icons.broken_image, size: 50, color: Colors.redAccent)
        ),
      );
    } else {
      final bool isEve = _currentUserData?.orientation?.toLowerCase() == 'eve';
      final IconData placeholderIcon = isEve ? Icons.female : Icons.male;

      imageWidget = Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.blueGrey, width: 1),
          ),
          child: Icon(placeholderIcon, color: Colors.blueGrey, size: 50)
      );
    }

    return GestureDetector(
      onTap: () => _showGalleryImageSourceActionSheet(index),
      child: ClipRRect(borderRadius: BorderRadius.circular(12.0), child: imageWidget),
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isEveOrientation = _currentUserData?.orientation?.toLowerCase() == 'eve';

    String? safeDropdownValue(String? currentValue, List<String> items) {
      if (currentValue != null && items.contains(currentValue)) {
        return currentValue;
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading2.copyWith(color: AppTheme.textGrey),
        iconTheme: const IconThemeData(color: Colors.blueGrey),
        backgroundColor: Colors.black54,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.primaryYellow),
            onPressed: _isLoading ? null : _saveProfileChanges,
            tooltip: "Save Changes",
          ),
        ],
      ),
      body: _isLoading && _currentUserData == null
          ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
          : _currentUserData == null
          ? Center(child: Text("Could not load user profile.", style: AppTextStyles.body1.copyWith(color: Colors.red)))
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // --- Main Profile Picture and Gallery Sections ---
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
                              ? FileImage(_pickedMainProfileImageFile!) as ImageProvider
                              : (_currentMainProfileImageUrl != null && _currentMainProfileImageUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(_currentMainProfileImageUrl!)
                              : null,
                          child: (_pickedMainProfileImageFile == null && (_currentMainProfileImageUrl == null || _currentMainProfileImageUrl!.isEmpty))
                              ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                              : null,
                        ),
                      ),
                      TextButton(
                        onPressed: _pickMainProfileImage,
                        child: Text("Change Main Photo", style: AppTextStyles.body1.copyWith(color: AppTheme.textGrey)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.blueGrey, thickness: 2),
                const SizedBox(height: 20),
                Text("Profile Gallery Images", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blueGrey)),
                const SizedBox(height: 10),
                Center(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: List.generate(5, (index) => _buildGalleryImageSlot(index)),
                  ),
                ),
                const SizedBox(height: 24),
                Text("Profile Details", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blueGrey)),
                const SizedBox(height: 16),

                // --- Basic Info TextFields (No Change) ---
                _buildTextFormField(controller: _nameController, label: "Name", icon: Icons.person, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null),
                _buildTextFormField(controller: _ageController, label: "Age", icon: Icons.cake, keyboardType: TextInputType.number),
                _buildTextFormField(controller: _phoneController, label: "Phone", icon: Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),

                // --- Centralized Dropdowns ---
                _buildDropdownFormField(
                  label: "Relationship Status",
                  icon: Icons.favorite_border,
                  value: safeDropdownValue(_selectedRelationshipStatus, AppConstants.relationshipStatuses),
                  items: AppConstants.relationshipStatuses.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white70)))).toList(),
                  onChanged: (value) => setState(() => _selectedRelationshipStatus = value),
                ),
                _buildDropdownFormField(
                  label: "Country",
                  icon: Icons.public,
                  value: safeDropdownValue(_selectedCountry, locationController.getCountries()),
                  items: locationController.getCountries().map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white70)))).toList(),
                  onChanged: (newValue) { setState(() { _selectedCountry = newValue; _selectedProvince = null; _selectedCity = null; }); },
                ),
                _buildDropdownFormField(
                  label: "Province/State",
                  icon: Icons.landscape,
                  value: safeDropdownValue(_selectedProvince, locationController.getProvinces(_selectedCountry)),
                  items: locationController.getProvinces(_selectedCountry).map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white70)))).toList(),
                  onChanged: (newValue) { setState(() { _selectedProvince = newValue; _selectedCity = null; }); },
                  enabled: _selectedCountry != null,
                ),
                _buildDropdownFormField(
                  label: "City",
                  icon: Icons.location_city,
                  value: safeDropdownValue(_selectedCity, locationController.getCities(_selectedCountry, _selectedProvince)),
                  items: locationController.getCities(_selectedCountry, _selectedProvince).map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white70)))).toList(),
                  onChanged: (newValue) => setState(() => _selectedCity = newValue),
                  enabled: _selectedProvince != null,
                ),
                _buildDropdownFormField(
                  label: "Ethnicity",
                  icon: Icons.flag,
                  value: safeDropdownValue(_selectedEthnicity, AppConstants.ethnicities),
                  items: AppConstants.ethnicities.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white70)))).toList(),
                  onChanged: (value) => setState(() => _selectedEthnicity = value),
                ),

                // --- PRESERVED PROFESSION LOGIC ---
                if (isEveOrientation) ...[
                  const SizedBox(height: 20),
                  Text("Profession & Financials", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  _buildDropdownFormField<String>(
                    label: "Main Profession Category",
                    icon: Icons.work_outline,
                    value: safeDropdownValue(_mainProfessionCategory, _mainProfessionCategoriesList),
                    items: _mainProfessionCategoriesList.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white70)))).toList(),
                    onChanged: (value) => setState(() => _mainProfessionCategory = value),
                  ),
                  if (_mainProfessionCategory == "Professional") ...[
                    const SizedBox(height: 16),
                    _buildTextFormField(controller: _professionController, label: "Specific Profession (e.g., Doctor)", icon: Icons.business_center),
                    const SizedBox(height: 16),
                    Text("Professional Venues (Optional)", style: AppTextStyles.body1.copyWith(color: AppTheme.textGrey)),
                    ..._professionalVenueOptions.map((venue) => CheckboxListTile(
                      title: Text(venue, style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)),
                      value: _selectedProfessionalVenues[venue],
                      onChanged: (bool? value) => setState(() => _selectedProfessionalVenues[venue] = value!),
                      activeColor: AppTheme.primaryYellow,
                      checkColor: Colors.black,
                    )),
                    CheckboxListTile(
                      title: Text("Other Venue", style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)),
                      value: _professionalVenueOtherSelected,
                      onChanged: (bool? value) => setState(() => _professionalVenueOtherSelected = value!),
                      activeColor: AppTheme.primaryYellow,
                      checkColor: Colors.black,
                    ),
                    if (_professionalVenueOtherSelected) _buildTextFormField(controller: _professionalVenueOtherNameController, label: "Other Venue Name"),
                  ],
                ] else ...[ // Adam's profession
                  const SizedBox(height: 16),
                  _buildTextFormField(controller: _professionController, label: "Profession", icon: Icons.work),
                ],

                // --- REFACTORED INCOME LOGIC ---
                if (isEveOrientation) ...[
                  const SizedBox(height: 16),
                  _buildDropdownFormField<String>(
                    label: "Income Bracket",
                    icon: Icons.attach_money,
                    value: safeDropdownValue(_selectedIncome, AppConstants.incomeBrackets),
                    items: AppConstants.incomeBrackets.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white70)))).toList(),
                    onChanged: (value) => setState(() => _selectedIncome = value),
                  ),
                ],

                // --- Other Eve-Specific & Lifestyle Switches ---
                if (isEveOrientation) ...[
                  const SizedBox(height: 16),
                  _buildDropdownFormField(
                      label: "Height",
                      icon: Icons.height,
                      value: safeDropdownValue(_currentUserData?.height, AppConstants.heights),
                      items: AppConstants.heights.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white70)))).toList(),
                      onChanged: (value) => setState(() => _currentUserData = _currentUserData?.copyWith(height: value))
                  ),
                  _buildDropdownFormField(
                      label: "Body Type",
                      icon: Icons.accessibility_new,
                      value: safeDropdownValue(_currentUserData?.bodyType, AppConstants.bodyTypes),
                      items: AppConstants.bodyTypes.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white70)))).toList(),
                      onChanged: (value) => setState(() => _currentUserData = _currentUserData?.copyWith(bodyType: value))
                  ),
                ],

                const SizedBox(height: 24),

                Text("Lifestyle Preferences", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blueGrey)),
                SwitchListTile(title: Text('Do you drink?', style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)), value: _drinkSelection, onChanged: (val) => setState(() => _drinkSelection = val), activeColor: AppTheme.primaryYellow),
                SwitchListTile(title: Text('Do you smoke?', style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)), value: _smokeSelection, onChanged: (val) => setState(() => _smokeSelection = val), activeColor: AppTheme.primaryYellow),
                SwitchListTile(title: Text('Do you eat meat?', style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)), value: _meatSelection, onChanged: (val) => setState(() => _meatSelection = val), activeColor: AppTheme.primaryYellow),
                SwitchListTile(title: Text('Are you open to Greek?', style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)), value: _greekSelection, onChanged: (val) => setState(() => _greekSelection = val), activeColor: AppTheme.primaryYellow),
                SwitchListTile(title: Text('Are you able to host?', style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)), value: _hostSelection, onChanged: (val) => setState(() => _hostSelection = val), activeColor: AppTheme.primaryYellow),
                SwitchListTile(title: Text('Are you able to travel?', style: AppTextStyles.body1.copyWith(color: AppTheme.textLight)), value: _travelSelection, onChanged: (val) => setState(() => _travelSelection = val), activeColor: AppTheme.primaryYellow),

                const SizedBox(height: 24),

                // --- START: TEMPORARY NOTIFICATION TEST PANEL ---
// This panel simulates the three key notification types.
// It should be removed before production.

                const Divider(height: 40, thickness: 1, color: Colors.blueGrey),
                Text(
                  'Developer: Notification Test Panel',
                  style: AppTextStyles.body1.copyWith(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),

                // --- Test "Profile View" ---
                ElevatedButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('Simulate "Profile View" Notification'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () {
                    final testPayload = PushNotificationPayload(
                      senderId: 'viewer_user_id_123',
                      senderName: 'Alex',
                      senderPhotoUrl: 'https://randomuser.me/api/portraits/men/75.jpg',
                      senderAge: '30',
                      senderCity: 'Toronto',
                      senderProfession: 'Architect',
                      type: 'profile_view',
                      relatedItemId: _currentUserData?.uid, // The user who was viewed (you)
                    );
                    // Directly call the static method from your PushNotifications class
                    PushNotifications.showTestForegroundNotification(context, testPayload);
                  },
                ),
                const SizedBox(height: 8),

                // --- Test "New Like" ---
                ElevatedButton.icon(
                  icon: const Icon(Icons.favorite),
                  label: const Text('Simulate "New Like" Notification'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                  onPressed: () {
                    final testPayload = PushNotificationPayload(
                      senderId: 'liker_user_id_456',
                      senderName: 'Jessica',
                      senderPhotoUrl: 'https://randomuser.me/api/portraits/women/75.jpg',
                      senderAge: '28',
                      senderCity: 'New York',
                      senderProfession: 'Graphic Designer',
                      type: 'new_like',
                      relatedItemId: _currentUserData?.uid, // The user who was liked (you)
                    );
                    PushNotifications.showTestForegroundNotification(context, testPayload);
                  },
                ),
                const SizedBox(height: 8),

                // --- Test "Mutual Match" ---
                ElevatedButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Simulate "Mutual Match" Notification'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                  onPressed: () {
                    final testPayload = PushNotificationPayload(
                      senderId: 'matcher_user_id_789',
                      senderName: 'Sarah',
                      senderPhotoUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
                      senderAge: '29',
                      senderCity: 'Chicago',
                      senderProfession: 'Doctor',
                      type: 'mutual_match',
                      relatedItemId: _currentUserData?.uid, // The user who was matched (you)
                    );
                    PushNotifications.showTestForegroundNotification(context, testPayload);
                  },
                ),
                const Divider(height: 40, thickness: 1, color: Colors.blueGrey),
// --- END: TEMPORARY NOTIFICATION TEST PANEL ---

              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for TextFormFields
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.body1.copyWith(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey) : null,
          labelStyle: AppTextStyles.body1.copyWith(color: AppTheme.textGrey),
          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueGrey), borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primaryYellow), borderRadius: BorderRadius.circular(12)),
          errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(12)),
          focusedErrorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red, width: 2), borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  // Helper widget for DropdownFormFields
  Widget _buildDropdownFormField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<T>(
        value: value,
        items: enabled ? items : null,
        onChanged: enabled ? onChanged : null,
        dropdownColor: Colors.grey[900],
        style: AppTextStyles.body1.copyWith(color: enabled ? Colors.white : Colors.grey),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: enabled ? Colors.blueGrey : Colors.grey),
          labelStyle: AppTextStyles.body1.copyWith(color: enabled ? AppTheme.textGrey : Colors.grey),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: enabled ? Colors.blueGrey : Colors.grey), borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primaryYellow), borderRadius: BorderRadius.circular(12)),
          disabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
