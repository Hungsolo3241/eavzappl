import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eavzappl/models/person.dart';
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
  Person? _currentUserData;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _professionController;

  String? _mainProfessionCategory;

  final List<String> _professionalVenueOptions = [
    "The Grand - JHB", "Blu Night Revue Bar - Haarties", "Royal Park - JHB",
    "The Summit - JHB", "Chivalry Lounge - JHB", "Manhattan - Vaal",
    "Mavericks Revue Bar - CPT", "Lush Capetown - CPT", "The Pynk - DBN", "Wonder Lounge - DBN"
  ];
  final Map<String, bool> _selectedProfessionalVenues = {};
  bool _professionalVenueOtherSelected = false;
  late TextEditingController _professionalVenueOtherNameController;

  final List<String> _mainProfessionCategoriesList = ["Student", "Freelancer", "Professional"];

  bool _drinkSelection = false;
  bool _smokeSelection = false;
  bool _meatSelection = false;
  bool _greekSelection = false;
  bool _hostSelection = false;
  bool _travelSelection = false;
  late TextEditingController _incomeController;

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

  List<String> _countriesList = [];
  List<String> _provincesList = [];
  List<String> _citiesList = [];
  String? _selectedCountry;
  String? _selectedProvince;
  String? _selectedCity;

  final List<String> _ethnicityOptions = [
    "Black", "White", "Asian", "Mixed", "Other", "Prefer not to say"
  ];
  String? _selectedEthnicity;

  final ImagePicker _picker = ImagePicker();
  List<File?> _pickedImages = List.filled(5, null);
  List<String?> _imageUrls = List.filled(5, null);

  File? _pickedMainProfileImageFile;
  String? _currentMainProfileImageUrl;

  final String evePlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.appspot.com/o/placeholder%2Feves_avatar.jpeg?alt=media&token=75b9c3f5-72c1-42db-be5c-471cc0d88c05';
  final String adamPlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.appspot.com/o/placeholder%2Fadam_avatar.jpeg?alt=media&token=997423ec-96a4-42d6-aea8-c8cb80640ca0';
  final String genericPlaceholderUrl = 'https://firebasestorage.googleapis.com/v0/b/eavzappl-32891.appspot.com/o/placeholder%2Fplaceholder_avatar.png?alt=media&token=98256561-2bac-4595-8e54-58a5c486a427';

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

    for (var venue in _professionalVenueOptions) {
      _selectedProfessionalVenues[venue] = false;
    }

    _countriesList = allLocations.keys.toList();
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
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    setState(() { _isLoading = true; });
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          _currentUserData = Person.fromJson(data);

          _nameController.text = _currentUserData?.name ?? '';
          _ageController.text = _currentUserData?.age?.toString() ?? '';
          _phoneController.text = _currentUserData?.phoneNumber ?? '';

          _currentMainProfileImageUrl = data['profilePhoto'] as String?;

          _selectedCountry = _currentUserData?.country;
          if (_selectedCountry != null && allLocations.containsKey(_selectedCountry)) {
            _provincesList = allLocations[_selectedCountry!]!.keys.toList();
            _selectedProvince = _currentUserData?.province;
            if (_selectedProvince != null && allLocations[_selectedCountry!]!.containsKey(_selectedProvince)) {
              _citiesList = allLocations[_selectedCountry!]![_selectedProvince!]!;
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

          _selectedEthnicity = _currentUserData?.ethnicity;

          _drinkSelection = data['drinkSelection'] ?? false;
          _smokeSelection = data['smokeSelection'] ?? false;
          _meatSelection = data['meatSelection'] ?? false;
          _greekSelection = data['greekSelection'] ?? false;
          _hostSelection = data['hostSelection'] ?? false;
          _travelSelection = data['travelSelection'] ?? false;
          _incomeController.text = data['income']?.toString() ?? '';

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
    ]);
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
    if (_currentUserData == null || _currentUserData!.uid == null) {
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
          Get.snackbar("Save Error", "Gallery image upload failed at slot ${i+1}. Please try again.", colorText: Colors.white, backgroundColor: Colors.red);
          return;
        }
      }
    }

    String finalProfession;
    List<String> finalSelectedVenues = [];
    String? otherVenue;

    if (_currentUserData?.orientation?.toLowerCase() == 'eve') {
      if (_mainProfessionCategory == "Professional") {
        finalProfession = _professionController.text.trim();
      } else {
        finalProfession = _mainProfessionCategory ?? '';
      }
      finalSelectedVenues = _selectedProfessionalVenues.entries.where((e) => e.value).map((e) => e.key).toList();
      if (_professionalVenueOtherSelected) {
        otherVenue = _professionalVenueOtherNameController.text.trim();
      }
    } else {
      finalProfession = _professionController.text.trim();
    }
    
    Map<String, dynamic> dataToUpdate = {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()),
      'phoneNumber': _phoneController.text.trim(),
      'country': _selectedCountry,
      'province': _selectedProvince,
      'city': _selectedCity,
      'ethnicity': _selectedEthnicity,
      'profession': finalProfession,
      'drinkSelection': _drinkSelection,
      'smokeSelection': _smokeSelection,
      'meatSelection': _meatSelection,
      'greekSelection': _greekSelection,
      'hostSelection': _hostSelection,
      'travelSelection': _travelSelection,
      'income': _incomeController.text.trim(),
      'profilePhoto': newMainProfilePicUrl,
      'professionalVenues': finalSelectedVenues,
      'otherProfessionalVenue': otherVenue,
      'urlImage1': finalImageUrls.length > 0 ? finalImageUrls[0] : null,
      'urlImage2': finalImageUrls.length > 1 ? finalImageUrls[1] : null,
      'urlImage3': finalImageUrls.length > 2 ? finalImageUrls[2] : null,
      'urlImage4': finalImageUrls.length > 3 ? finalImageUrls[3] : null,
      'urlImage5': finalImageUrls.length > 4 ? finalImageUrls[4] : null,
    };

    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUserData!.uid).update(dataToUpdate);
      Get.snackbar("Success", "Profile updated successfully!", colorText: Colors.white, backgroundColor: Colors.green);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      Get.snackbar("Save Error", "Failed to save profile: ${e.toString()}", colorText: Colors.white, backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget placeholder;
    final String? orientation = _currentUserData?.orientation?.toLowerCase();
    String placeholderUrl;

    if (orientation == 'eve') {
      placeholderUrl = evePlaceholderUrl;
    } else if (orientation == 'adam') {
      placeholderUrl = adamPlaceholderUrl;
    } else {
      placeholderUrl = genericPlaceholderUrl;
    }

    placeholder = Image.network(
      placeholderUrl,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Icon(Icons.person, size: 75, color: Colors.grey[600]), // Final fallback
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfileChanges,
            tooltip: 'Save Changes',
          )
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              children: [
                // --- MAIN PROFILE IMAGE ---
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: _pickedMainProfileImageFile != null
                            ? Image.file(_pickedMainProfileImageFile!, fit: BoxFit.cover)
                            : (_currentMainProfileImageUrl != null && _currentMainProfileImageUrl!.isNotEmpty)
                                ? Image.network(
                                    _currentMainProfileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => placeholder,
                                  )
                                : placeholder,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickMainProfileImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Change Main Photo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // --- BASIC INFO ---
                Text('Basic Information', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your age';
                    if (int.tryParse(value) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number (e.g. 27721234567)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your phone number' : null,
                ),
                const SizedBox(height: 24),

                // --- LOCATION ---
                Text('Location', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  items: _countriesList.map((country) => DropdownMenuItem(value: country, child: Text(country))).toList(),
                  onChanged: (value) {
                    if (value == null || value == _selectedCountry) return;
                    setState(() {
                      _selectedCountry = value;
                      _provincesList = allLocations[value]!.keys.toList();
                      _selectedProvince = null;
                      _citiesList = [];
                      _selectedCity = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                  validator: (value) => value == null ? 'Please select a country' : null,
                ),
                if (_selectedCountry != null) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    items: _provincesList.map((province) => DropdownMenuItem(value: province, child: Text(province))).toList(),
                    onChanged: (value) {
                      if (value == null || value == _selectedProvince) return;
                      setState(() {
                        _selectedProvince = value;
                        _citiesList = allLocations[_selectedCountry!]![value]!;
                        _selectedCity = null;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Province/State', border: OutlineInputBorder()),
                    validator: (value) => value == null ? 'Please select a province/state' : null,
                  ),
                ],
                if (_selectedProvince != null) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    items: _citiesList.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                    onChanged: (value) => setState(() => _selectedCity = value),
                    decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                    validator: (value) => value == null ? 'Please select a city' : null,
                  ),
                ],
                const SizedBox(height: 24),

                // --- ETHNICITY ---
                Text('Ethnicity', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedEthnicity,
                  items: _ethnicityOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (value) => setState(() => _selectedEthnicity = value),
                  decoration: const InputDecoration(labelText: 'Ethnicity', border: OutlineInputBorder()),
                  validator: (value) => value == null ? 'Please select an ethnicity' : null,
                ),
                const SizedBox(height: 24),

                // --- PROFESSION (Conditional) ---
                Text('Profession', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                if (_currentUserData?.orientation?.toLowerCase() == 'eve') ...[
                  DropdownButtonFormField<String>(
                    value: _mainProfessionCategory,
                    items: _mainProfessionCategoriesList.map((String category) {
                      return DropdownMenuItem<String>(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _mainProfessionCategory = newValue;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Main Profession Category', border: OutlineInputBorder()),
                  ),
                  if (_mainProfessionCategory == 'Professional') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _professionController,
                      decoration: const InputDecoration(labelText: 'Describe Your Profession', border: OutlineInputBorder()),
                      validator: (value) {
                        if (_mainProfessionCategory == 'Professional' && (value == null || value.isEmpty)) {
                          return 'Please describe your profession';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text('Venues (for Eve)', style: Theme.of(context).textTheme.titleMedium),
                  ..._professionalVenueOptions.map((venue) {
                    return CheckboxListTile(
                      title: Text(venue),
                      value: _selectedProfessionalVenues[venue],
                      onChanged: (bool? value) {
                        setState(() {
                          _selectedProfessionalVenues[venue] = value!;
                        });
                      },
                    );
                  }).toList(),
                  CheckboxListTile(
                    title: const Text("Other"),
                    value: _professionalVenueOtherSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        _professionalVenueOtherSelected = value!;
                        if (!value) _professionalVenueOtherNameController.clear();
                      });
                    },
                  ),
                  if (_professionalVenueOtherSelected)
                    TextFormField(
                      controller: _professionalVenueOtherNameController,
                      decoration: const InputDecoration(labelText: 'Other Venue Name', border: OutlineInputBorder()),
                      validator: (value) => _professionalVenueOtherSelected && (value == null || value.isEmpty) ? 'Please specify other venue' : null,
                    ),
                ] else ...[
                  TextFormField(
                    controller: _professionController,
                    decoration: const InputDecoration(labelText: 'Profession', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter your profession' : null,
                  ),
                ],
                const SizedBox(height: 24),
                
                // --- LIFESTYLE ---
                Text('Lifestyle Choices', style: Theme.of(context).textTheme.headlineSmall),
                CheckboxListTile(title: const Text('Do you drink?'), value: _drinkSelection, onChanged: (v) => setState(() => _drinkSelection = v!)),
                CheckboxListTile(title: const Text('Do you smoke?'), value: _smokeSelection, onChanged: (v) => setState(() => _smokeSelection = v!)),
                CheckboxListTile(title: const Text('Do you eat meat?'), value: _meatSelection, onChanged: (v) => setState(() => _meatSelection = v!)),
                CheckboxListTile(title: const Text('Are you involved in Greek Life?'), value: _greekSelection, onChanged: (v) => setState(() => _greekSelection = v!)),
                CheckboxListTile(title: const Text('Do you enjoy hosting?'), value: _hostSelection, onChanged: (v) => setState(() => _hostSelection = v!)),
                CheckboxListTile(title: const Text('Do you enjoy traveling?'), value: _travelSelection, onChanged: (v) => setState(() => _travelSelection = v!)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _incomeController,
                  decoration: const InputDecoration(labelText: 'Income Range (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),

                // --- GALLERY IMAGES ---
                Text('Gallery Images', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: List.generate(5, (index) => _buildGalleryImageSlot(index)),
                ),
              ],
            ),
          ),
    );
  }
}
