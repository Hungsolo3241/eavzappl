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
  late TextEditingController _incomeController;

  // --- State Variables ---
  String? _mainProfessionCategory;
  final List<String> _mainProfessionCategoriesList = ["Student", "Freelancer", "Professional"];
  final Map<String, bool> _selectedProfessionalVenues = {};
  bool _professionalVenueOtherSelected = false;

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

  // --- Location State ---
  late final Map<String, Map<String, List<String>>> allLocations;
  List<String> _countriesList = [];
  List<String> _provincesList = [];
  List<String> _citiesList = [];
  String? _selectedCountry;
  String? _selectedProvince;
  String? _selectedCity;

  final Map<String, Map<String, List<String>>> africanLocations = {
    'South Africa': { 'Gauteng': ['Johannesburg', 'Pretoria', 'Vereeniging'], 'Western Cape': ['Cape Town', 'Stellenbosch', 'Paarl'], 'KwaZulu-Natal': ['Durban', 'Pietermaritzburg', 'Richards Bay'], },
    'Nigeria': { 'Lagos': ['Ikeja', 'Lekki', 'Badagry'], 'Abuja (FCT)': ['Central Business District', 'Garki', 'Wuse'], 'Rivers': ['Port Harcourt', 'Bonny', 'Okrika'], },
    'Kenya': { 'Nairobi': ['Nairobi CBD', 'Westlands', 'Karen'], 'Mombasa': ['Mombasa Island', 'Nyali', 'Likoni'], 'Kisumu': ['Kisumu City', 'Ahero', 'Maseno'], },
  };
  final Map<String, Map<String, List<String>>> asianLocations = {
    'Vietnam': { 'Hanoi Capital Region': ['Hanoi', 'Haiphong'], 'Ho Chi Minh City Region': ['Ho Chi Minh City', 'Can Tho'], 'Da Nang Province': ['Da Nang', 'Hoi An'], },
    'Thailand': { 'Bangkok Metropolitan Region': ['Bangkok', 'Nonthaburi', 'Samut Prakan'], 'Chiang Mai Province': ['Chiang Mai City', 'Chiang Rai City'], 'Phuket Province': ['Phuket Town', 'Patong'], },
    'Indonesia': { 'Jakarta Special Capital Region': ['Jakarta', 'South Tangerang'], 'Bali Province': ['Denpasar', 'Ubud', 'Kuta'], 'West Java Province': ['Bandung', 'Bogor'], }
  };

  // --- Ethnicity State ---
  final List<String> _ethnicityOptions = ["Black", "White", "Asian", "Mixed", "Other", "Prefer not to say"];
  String? _selectedEthnicity;

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
    _incomeController = TextEditingController();

    allLocations = {...africanLocations, ...asianLocations};
    _countriesList = allLocations.keys.toList();

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
    _incomeController.dispose();
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
          _selectedCountry = _currentUserData?.country;
          if (_selectedCountry != null && allLocations.containsKey(_selectedCountry)) {
            _provincesList = allLocations[_selectedCountry!]!.keys.toList();
            _selectedProvince = _currentUserData?.province;
            if (_selectedProvince != null && allLocations[_selectedCountry!]!.containsKey(_selectedProvince)) {
              _citiesList = allLocations[_selectedCountry!]![_selectedProvince!]!;
              _selectedCity = _currentUserData?.city;
            } else {
              _selectedProvince = null; _selectedCity = null; _citiesList = [];
            }
          } else {
            _selectedCountry = null; _selectedProvince = null; _selectedCity = null;
            _provincesList = []; _citiesList = [];
          }

          _selectedEthnicity = _currentUserData?.ethnicity;

          // --- THIS BLOCK CONTAINS THE FIX ---
          // Lifestyle
          _drinkSelection = data['drinkSelection'] ?? false;
          _smokeSelection = data['smokeSelection'] ?? false;
          _meatSelection = data['meatSelection'] ?? false;
          _greekSelection = data['greekSelection'] ?? false;
          _hostSelection = data['hostSelection'] ?? false;
          _travelSelection = data['travelSelection'] ?? false;

          // Robustly handle 'income' which might be a String or a num from Firestore.
          final incomeFromDb = data['income'];
          if (incomeFromDb is num) {
            _incomeController.text = incomeFromDb.toString();
          } else if (incomeFromDb is String) {
            _incomeController.text = incomeFromDb;
          } else {
            _incomeController.text = '';
          }
          // --- END OF FIX ---

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

      final incomeText = _incomeController.text.trim();
      final num? finalIncome = incomeText.isNotEmpty ? num.tryParse(incomeText) : null;

      // 3. Build the Data Map
      Map<String, dynamic> dataToUpdate = {
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'phoneNumber': _phoneController.text.trim(),
        'country': _selectedCountry,
        'province': _selectedProvince,
        'city': _selectedCity,
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
        'income': finalIncome, // Correctly saves a number or null

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


  // --- IMAGE HELPERS (Unchanged) ---
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

  // --- UI BUILDERS (Unchanged) ---
  Widget _buildGalleryImageSlot(int index) {
    Widget imageWidget;
    if (_pickedImages[index] != null) {
      imageWidget = Image.file(_pickedImages[index]!, width: 120, height: 120, fit: BoxFit.cover);
    } else if (_imageUrls[index] != null && _imageUrls[index]!.isNotEmpty) {
      imageWidget = Image.network(_imageUrls[index]!, width: 120, height: 120, fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null)),
        errorBuilder: (context, error, stackTrace) => Image.network(_getPlaceholderUrlForSlot(index), width: 120, height: 120, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 120, height: 120, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400]))),
      );
    } else {
      imageWidget = Image.network(_getPlaceholderUrlForSlot(index), width: 120, height: 120, fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null)),
          errorBuilder: (c, e, s) => Container(width: 120, height: 120, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400]))
      );
    }
    return Column(children: [
      Container(width: 120, height: 120, margin: const EdgeInsets.all(4.0), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8.0)), clipBehavior: Clip.antiAlias, child: imageWidget),
      ElevatedButton(onPressed: () => _showGalleryImageSourceActionSheet(index), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey), child: const Text("Change", style: TextStyle(color: Colors.white))),
    ]);
  }

  String _getPlaceholderUrlForSlot(int index) {
    if (_currentUserData?.orientation?.toLowerCase() == 'eve') return evePlaceholderUrl;
    if (_currentUserData?.orientation?.toLowerCase() == 'adam') return adamPlaceholderUrl;
    return '${genericPlaceholderUrl}&index=${index + 1}';
  }

  Widget _buildTextFormField({ required TextEditingController controller, String label = "", IconData? icon, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator, bool enabled = true }) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: TextFormField(controller: controller, enabled: enabled, decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.blueGrey), prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey, width: 2.0), borderRadius: BorderRadius.circular(8.0)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8.0)), disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.0))), style: TextStyle(color: enabled ? Colors.white70 : Colors.grey), keyboardType: keyboardType, inputFormatters: inputFormatters, validator: validator));
  }

  Widget _buildDropdownFormField<T>({ required String label, IconData? icon, T? value, required List<DropdownMenuItem<T>> items, required void Function(T?)? onChanged, String? Function(T?)? validator, bool enabled = true }) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: DropdownButtonFormField<T>(decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.blueGrey), prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueGrey, width: 2.0), borderRadius: BorderRadius.circular(8.0)), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8.0)), disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.0))), style: TextStyle(color: enabled ? Colors.white70 : Colors.grey), dropdownColor: Colors.grey[800], value: value, items: items, onChanged: enabled ? onChanged : null, validator: validator, isExpanded: true));
  }

  Widget _buildLifestyleSwitch({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(title: Text(title, style: TextStyle(color: Colors.white70)), value: value, onChanged: onChanged, activeColor: Colors.blueAccent, inactiveThumbColor: Colors.grey, inactiveTrackColor: Colors.grey.shade700);
  }

  @override
  Widget build(BuildContext context) {
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
            : SafeArea(
          child: SingleChildScrollView(
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
                  Text("Please only upload genuine photos of yourself. To maintain a trustworthy community, accounts found catfishing will be permanently banned.", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.yellow[700], fontStyle: FontStyle.italic)),
                  const SizedBox(height: 10),
                  Center(
                    child: Wrap(spacing: 8.0, runSpacing: 8.0, alignment: WrapAlignment.center, children: List.generate(5, (index) => _buildGalleryImageSlot(index))),
                  ),
                  const SizedBox(height: 24),
                  Text("Profile Details", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blueGrey)),
                  const SizedBox(height: 16),

                  _buildTextFormField(controller: _nameController, label: "Name", icon: Icons.person, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null),
                  _buildTextFormField(controller: _ageController, label: "Age", icon: Icons.cake, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; final age = int.tryParse(v.trim()); if (age == null) return 'Invalid age'; if (age < 18) return 'Must be 18 or older'; if (age > 120) return 'Invalid age'; return null; }),
                  _buildTextFormField(controller: _phoneController, label: "Phone Number", icon: Icons.phone, keyboardType: TextInputType.phone, validator: (v) { if (v == null || v.trim().isEmpty) return null; if (v.replaceAll(RegExp(r'\\D'), '').length < 7) return 'Enter a valid phone number'; return null; }),

                  // --- ROBUST DROPDOWNS ---
                  _buildDropdownFormField<String>(
                    label: "Country", icon: Icons.public,
                    value: _countriesList.contains(_selectedCountry) ? _selectedCountry : null,
                    items: _countriesList.map((country) => DropdownMenuItem(value: country, child: Text(country, style: TextStyle(color: Colors.white70)))).toList(),
                    onChanged: (newValue) { setState(() {
                      _selectedCountry = newValue; _selectedProvince = null; _selectedCity = null;
                      _provincesList = newValue != null && allLocations.containsKey(newValue) ? allLocations[newValue]!.keys.toList() : [];
                      _citiesList = []; }); },
                    validator: (value) => value == null ? 'Please select a country' : null,
                  ),
                  _buildDropdownFormField<String>(
                    label: "Province/State", icon: Icons.landscape,
                    value: _provincesList.contains(_selectedProvince) ? _selectedProvince : null,
                    enabled: _selectedCountry != null,
                    items: _provincesList.map((province) => DropdownMenuItem(value: province, child: Text(province, style: TextStyle(color: Colors.white70)))).toList(),
                    onChanged: (newValue) { setState(() {
                      _selectedProvince = newValue; _selectedCity = null;
                      _citiesList = (newValue != null && _selectedCountry != null && allLocations.containsKey(_selectedCountry!) && allLocations[_selectedCountry!]!.containsKey(newValue)) ? allLocations[_selectedCountry!]![newValue]! : [];
                    }); },
                    validator: (value) => _selectedCountry != null && value == null ? 'Please select a province/state' : null,
                  ),
                  _buildDropdownFormField<String>(
                    label: "City", icon: Icons.location_city,
                    value: _citiesList.contains(_selectedCity) ? _selectedCity : null,
                    enabled: _selectedProvince != null,
                    items: _citiesList.map((city) => DropdownMenuItem(value: city, child: Text(city, style: TextStyle(color: Colors.white70)))).toList(),
                    onChanged: (newValue) { setState(() { _selectedCity = newValue; }); },
                    validator: (value) => _selectedProvince != null && value == null ? 'Please select a city' : null,
                  ),

                  _buildDropdownFormField<String>(
                    label: "Ethnicity", icon: Icons.diversity_3,
                    value: _ethnicityOptions.contains(_selectedEthnicity) ? _selectedEthnicity : null,
                    items: _ethnicityOptions.map((ethnicity) => DropdownMenuItem(value: ethnicity, child: Text(ethnicity, style: TextStyle(color: Colors.white70)))).toList(),
                    onChanged: (newValue) { setState(() { _selectedEthnicity = newValue; }); },
                    validator: (value) => null, // It's an optional field
                  ),

                  if (isEveOrientation) ...[
                    _buildDropdownFormField<String>(
                      label: "I am a...",
                      icon: Icons.work_outline,
                      value: _mainProfessionCategoriesList.contains(_mainProfessionCategory) ? _mainProfessionCategory : null,
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
                  // --- END OF ROBUST DROPDOWNS ---

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

                  const SizedBox(height: 24),
                  Text("Lifestyle Choices", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  _buildLifestyleSwitch(title: "Do you drink?", value: _drinkSelection, onChanged: (val) => setState(() => _drinkSelection = val)),
                  _buildLifestyleSwitch(title: "Do you smoke?", value: _smokeSelection, onChanged: (val) => setState(() => _smokeSelection = val)),
                  _buildLifestyleSwitch(title: "Do you eat meat?", value: _meatSelection, onChanged: (val) => setState(() => _meatSelection = val)),
                  _buildLifestyleSwitch(title: "Do you eat Greek?", value: _greekSelection, onChanged: (val) => setState(() => _greekSelection = val)),
                  _buildLifestyleSwitch(title: "Do you enjoy hosting?", value: _hostSelection, onChanged: (val) => setState(() => _hostSelection = val)),
                  _buildLifestyleSwitch(title: "Do you enjoy traveling?", value: _travelSelection, onChanged: (val) => setState(() => _travelSelection = val)),
                  const SizedBox(height: 8),
                  _buildTextFormField(
                      controller: _incomeController,
                      label: "Hourly Income (Optional, e.g., 50000)",
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final income = int.tryParse(v.trim());
                        if (income == null) return 'Invalid income amount';
                        if (income < 0) return 'Income cannot be negative';
                        return null;
                      }
                  ),

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
          ),
        )
    );
  }
  }
