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
import 'package:eavzappl/services/image_compression_service.dart';


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

  // ✅ Upload progress tracking
  final Map<int, double> _uploadProgress = {};
  bool _isUploadingImages = false;
  int _uploadedCount = 0;
  int _totalToUpload = 0;

  // ✅ Compression service and progress tracking
  final ImageCompressionService _compressionService = ImageCompressionService();
  final Map<int, double> _compressionProgress = {};
  bool _isCompressing = false;

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
    // Clean up temporary compressed files
    _compressionService.cleanupTempFiles();
    
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


  // ============================================================================
  // ✅ IMPROVED: Save with Progress Tracking
  // ============================================================================
  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar("Input Error", "Please correct the errors in the form.", 
        colorText: Colors.white, backgroundColor: Colors.orange);
      return;
    }
    if (_currentUserData?.uid == null) {
      Get.snackbar("Error", "User data not loaded.", 
        colorText: Colors.white, backgroundColor: Colors.red);
      return;
    }

    setState(() { 
      _isLoading = true;
      _isUploadingImages = true;
      _uploadedCount = 0;
      _uploadProgress.clear();
    });

    try {
      // 1. Upload main profile photo (if changed)
      String? finalMainProfilePicUrl = _currentMainProfileImageUrl;
      if (_pickedMainProfileImageFile != null) {
        finalMainProfilePicUrl = await _uploadMainProfileFileToFirebaseStorage(
          _pickedMainProfileImageFile!, 
          _currentUserData!.uid!
        );
      }

      // 2. Count how many gallery images need uploading
      _totalToUpload = _pickedImages.where((img) => img != null).length;
      
      // 3. Upload gallery images with progress tracking
      List<String?> finalImageUrls = await _uploadGalleryImagesWithProgress(
        _currentUserData!.uid!
      );

      // 4. Build update data
      String finalProfession = _buildProfessionString();
      Map<String, dynamic> dataToUpdate = _buildUpdateData(
        finalMainProfilePicUrl, 
        finalImageUrls, 
        finalProfession
      );

      // 5. Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserData!.uid)
          .update(dataToUpdate);

      // 6. Update local state
      setState(() {
        _currentMainProfileImageUrl = finalMainProfilePicUrl;
        _pickedMainProfileImageFile = null;
        _imageUrls = List.from(finalImageUrls);
        _pickedImages = List.filled(5, null);
        _uploadProgress.clear();
      });

      Get.snackbar("Success", "Profile updated successfully!", 
        colorText: Colors.white, backgroundColor: Colors.green);
      
      if (mounted) Get.back(result: true);

    } catch (e) {
      Get.snackbar("Save Error", "Failed to update profile: ${e.toString()}", 
        colorText: Colors.white, backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() { 
          _isLoading = false;
          _isUploadingImages = false;
          _uploadProgress.clear();
        });
      }
    }
  }

  // ============================================================================
  // ✅ IMPROVED: Main Profile Upload with Compression
  // ============================================================================
  Future<String?> _uploadMainProfileFileToFirebaseStorage(
    File file, 
    String userId
  ) async {
    try {
      // ✅ Compress before upload
      final compressedFile = await _compressionService.compressImage(
        file,
        ImageType.profilePhoto,
      );
      
      String fileName = 'main_profile_pic_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('main_profile_pictures/$userId/$fileName');
      
      TaskSnapshot task = await ref.putFile(compressedFile);
      return await task.ref.getDownloadURL();
    } catch (e) {
      Get.snackbar(
        "Upload Error", 
        "Failed to upload main profile picture: ${e.toString()}", 
        colorText: Colors.white, 
        backgroundColor: Colors.red
      );
      return null;
    }
  }

  // ============================================================================
  // ✅ NEW: Upload Gallery Images with Progress Tracking
  // ============================================================================
  Future<List<String?>> _uploadGalleryImagesWithProgress(String userId) async {
    List<String?> finalImageUrls = List.from(_imageUrls);
    
    // Create list of upload futures
    List<Future<void>> uploadFutures = [];
    
    for (int i = 0; i < _pickedImages.length; i++) {
      if (_pickedImages[i] != null) {
        // Create individual upload task with progress tracking
        uploadFutures.add(
          _uploadSingleGalleryImage(i, userId, finalImageUrls)
        );
      }
    }
    
    // ✅ PARALLEL UPLOADS: Wait for all uploads to complete
    // This is MUCH faster than sequential uploads
    await Future.wait(uploadFutures, eagerError: false);
    
    return finalImageUrls;
  }

  // ============================================================================
  // ✅ IMPROVED: Upload Single Image with Retry Logic and Auto-Save
  // Note: Images are already compressed in _pickGalleryImage()
  // ============================================================================
  Future<void> _uploadSingleGalleryImage(
    int slotIndex, 
    String userId, 
    List<String?> finalImageUrls, {
    int retries = 3,
  }) async {
    int attempt = 0;
    
    while (attempt < retries) {
      try {
        // Clear previous progress on retry
        if (attempt > 0 && mounted) {
          setState(() {
            _uploadProgress[slotIndex] = 0.0;
          });
        }
        
        // ✅ VERIFY FILE EXISTS before attempting upload
        final fileToUpload = _pickedImages[slotIndex];
        if (fileToUpload == null) {
          throw Exception('Image file not found. Please select the image again.');
        }
        
        // ✅ Ensure we have an absolute path and file exists
        final absolutePath = fileToUpload.absolute.path;
        final file = File(absolutePath);
        
        if (!file.existsSync()) {
          throw Exception('Image file was deleted. Please select the image again.');
        }
        
        // ✅ Verify file is readable and has content
        if (file.lengthSync() == 0) {
          throw Exception('Image file is empty. Please select the image again.');
        }
        
        String fileName = 'gallery_image_${slotIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('gallery_images/$userId/$fileName');
        
        // ✅ CREATE UPLOAD TASK with progress monitoring (use absolute path file)
        UploadTask uploadTask = ref.putFile(file);
        
        // ✅ MONITOR UPLOAD PROGRESS
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          if (mounted) {
            setState(() {
              _uploadProgress[slotIndex] = progress;
            });
          }
        });
        
        // ✅ WAIT FOR COMPLETION
        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        
        // ✅ UPDATE URL immediately (don't wait for all to finish)
        finalImageUrls[slotIndex] = downloadUrl;
        
        // ✅ AUTO-SAVE: Save to Firestore immediately after successful upload
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'urlImage${slotIndex + 1}': downloadUrl});
        } catch (firestoreError) {
          // Log Firestore error but don't fail the upload
          print('Warning: Failed to save image URL to Firestore: $firestoreError');
        }
        
        // ✅ INCREMENT COUNTER
        if (mounted) {
          setState(() {
            _uploadedCount++;
          });
        }
        
        // ✅ SUCCESS - Exit retry loop
        return;
        
      } catch (e) {
        attempt++;
        
        // ✅ Check if error is due to missing file - don't retry in this case
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('file') && 
            (errorMessage.contains('not found') || 
             errorMessage.contains('does not exist') ||
             errorMessage.contains('existsSync'))) {
          // File doesn't exist - don't retry, just fail immediately
          if (mounted) {
            setState(() {
              _uploadProgress.remove(slotIndex);
            });
          }
          
          Get.snackbar(
            "Upload Failed", 
            "Image ${slotIndex + 1} file was deleted. Please select the image again.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          
          print('Error: Image file $slotIndex does not exist: $e');
          return;
        }
        
        if (attempt >= retries) {
          // ✅ Final failure after all retries
          if (mounted) {
            setState(() {
              _uploadProgress.remove(slotIndex);
            });
          }
          
          Get.snackbar(
            "Upload Failed", 
            "Image ${slotIndex + 1} failed after $retries attempts: ${e.toString()}",
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          
          // Don't rethrow - let other uploads continue
          print('Error uploading image $slotIndex after $retries attempts: $e');
          return;
        }
        
        // ✅ Wait before retry (exponential backoff)
        print('Retrying upload for image $slotIndex (attempt $attempt/$retries)...');
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  // ============================================================================
  // ✅ DEPRECATED: Old method - keeping for reference
  // ============================================================================
  Future<String?> _uploadGalleryFileToFirebaseStorage(File file, String userId, int slotIndex) async {
    // This method is now replaced by _uploadSingleGalleryImage
    // Keeping it here in case you need to revert
    try {
      String fileName = 'gallery_image_${slotIndex}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('gallery_images/$userId/$fileName');
      
      TaskSnapshot task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (e) {
      Get.snackbar(
        "Upload Error", 
        "Failed to upload gallery image $slotIndex: ${e.toString()}", 
        colorText: Colors.white, 
        backgroundColor: Colors.red
      );
      return null;
    }
  }

  // ============================================================================
  // ✅ NEW: Build profession string (extracted for clarity)
  // ============================================================================
  String _buildProfessionString() {
    final isEve = _currentUserData?.orientation?.toLowerCase() == 'eve';
    
    if (isEve) {
      if (_mainProfessionCategory == "Professional") {
        return _professionController.text.trim();
      } else {
        return _mainProfessionCategory ?? "";
      }
    } else {
      return _professionController.text.trim();
    }
  }

  // ============================================================================
  // ✅ NEW: Build update data map (extracted for clarity)
  // ============================================================================
  Map<String, dynamic> _buildUpdateData(
    String? mainProfileUrl,
    List<String?> imageUrls,
    String profession,
  ) {
    final isEve = _currentUserData?.orientation?.toLowerCase() == 'eve';
    
    return {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()),
      'phoneNumber': _phoneController.text.trim(),
      'country': _selectedCountry,
      'province': _selectedProvince,
      'city': _selectedCity,
      'relationshipStatus': _selectedRelationshipStatus,
      'ethnicity': _selectedEthnicity,
      'profession': profession,
      'profilePhoto': mainProfileUrl,
      'drinkSelection': _drinkSelection,
      'smokeSelection': _smokeSelection,
      'meatSelection': _meatSelection,
      'greekSelection': _greekSelection,
      'hostSelection': _hostSelection,
      'travelSelection': _travelSelection,
      'income': _selectedIncome,
      'professionalVenues': isEve && _mainProfessionCategory == "Professional"
          ? _selectedProfessionalVenues.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList()
          : [],
      'otherProfessionalVenue': isEve && 
          _mainProfessionCategory == "Professional" && 
          _professionalVenueOtherSelected
          ? _professionalVenueOtherNameController.text.trim()
          : null,
      'urlImage1': imageUrls.length > 0 ? imageUrls[0] : null,
      'urlImage2': imageUrls.length > 1 ? imageUrls[1] : null,
      'urlImage3': imageUrls.length > 2 ? imageUrls[2] : null,
      'urlImage4': imageUrls.length > 3 ? imageUrls[3] : null,
      'urlImage5': imageUrls.length > 4 ? imageUrls[4] : null,
    };
  }

  // ============================================================================
  // ✅ IMPROVED: Pick Main Profile Image (compression happens on upload)
  // ============================================================================
  Future<void> _pickMainProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 100, // ✅ Pick at full quality, compress on upload
      );
      if (pickedFile != null) {
        setState(() { _pickedMainProfileImageFile = File(pickedFile.path); });
      }
    } catch (e) {
      Get.snackbar("Image Error", "Failed to pick main profile image: ${e.toString()}", colorText: Colors.white, backgroundColor: Colors.red);
    }
  }

  // ============================================================================
  // ✅ IMPROVED: Pick Gallery Image with Compression Service
  // ============================================================================
  Future<void> _pickGalleryImage(int slotIndex, ImageSource source) async {
    try {
      // 1. Pick image at full quality (compression happens later)
      final XFile? pickedFile = await _picker.pickImage(
        source: source, 
        imageQuality: 100, // ✅ Pick at full quality, compress later
      );
      
      if (pickedFile == null) return;
      
      // 2. Crop the image first (at full quality)
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        compressQuality: 100, // ✅ Don't compress during crop
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image', 
            toolbarColor: Colors.black54, 
            toolbarWidgetColor: AppTheme.textGrey, 
            initAspectRatio: CropAspectRatioPreset.square, 
            lockAspectRatio: true
          ),
          IOSUiSettings(
            title: 'Crop Image', 
            aspectRatioLockEnabled: true, 
            resetAspectRatioEnabled: false, 
            aspectRatioPickerButtonHidden: true, 
            doneButtonTitle: "Crop", 
            cancelButtonTitle: "Cancel"
          ),
        ],
      );
      
      if (croppedFile == null) return;
      
      // 3. Show compression in progress
      setState(() {
        _isCompressing = true;
        _compressionProgress[slotIndex] = 0.0;
      });
      
      // 4. Compress the cropped image using compression service
      final File compressedFile = await _compressionService.compressImage(
        File(croppedFile.path),
        ImageType.galleryImage,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _compressionProgress[slotIndex] = progress;
            });
          }
        },
      );
      
      // ✅ Verify compressed file exists and is valid
      if (!compressedFile.existsSync() || compressedFile.lengthSync() == 0) {
        throw Exception('Compressed image file is invalid or was deleted.');
      }
      
      // 5. Update state with compressed image (ensure absolute path)
      setState(() {
        _pickedImages[slotIndex] = File(compressedFile.absolute.path);
        _isCompressing = false;
        _compressionProgress.remove(slotIndex);
      });
      
      // 6. Show success message
      Get.snackbar(
        "Image Ready",
        "Image ${slotIndex + 1} optimized and ready to upload",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      Get.snackbar(
        "Image Error", 
        "Failed to process image: ${e.toString()}", 
        colorText: Colors.white, 
        backgroundColor: Colors.red
      );
      
      setState(() {
        _isCompressing = false;
        _compressionProgress.remove(slotIndex);
      });
    }
  }

  void _showGalleryImageSourceActionSheet(int slotIndex) {
    showModalBottomSheet(context: context, builder: (BuildContext context) {
      return SafeArea(child: Wrap(children: <Widget>[
        ListTile(leading: const Icon(Icons.photo_library, color: AppTheme.textGrey), title: const Text('Photo Library', style: TextStyle(color: Colors.green)), onTap: () { _pickGalleryImage(slotIndex, ImageSource.gallery); Navigator.of(context).pop(); }),
        ListTile(leading: const Icon(Icons.photo_camera, color: AppTheme.textGrey), title: const Text('Camera', style: TextStyle(color: Colors.green)), onTap: () { _pickGalleryImage(slotIndex, ImageSource.camera); Navigator.of(context).pop(); }),
      ]));
    });
  }


  // ============================================================================
  // ✅ IMPROVED: Gallery Image Slot with Compression and Upload Progress
  // ============================================================================
  Widget _buildGalleryImageSlot(int index) {
    final bool hasPickedImage = _pickedImages[index] != null;
    final bool hasExistingUrl = _imageUrls.length > index && 
                                 _imageUrls[index] != null && 
                                 _imageUrls[index]!.isNotEmpty;
    final bool isCompressing = _compressionProgress.containsKey(index);
    final bool isUploading = _uploadProgress.containsKey(index);
    final double compressionProgress = _compressionProgress[index] ?? 0.0;
    final double uploadProgress = _uploadProgress[index] ?? 0.0;

    Widget imageWidget;

    if (hasPickedImage) {
      // Show picked image from file
      imageWidget = Image.file(
        _pickedImages[index]!, 
        fit: BoxFit.cover, 
        width: 100, 
        height: 100
      );
    } else if (hasExistingUrl) {
      // Show existing network image
      imageWidget = CachedNetworkImage(
        imageUrl: _imageUrls[index]!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        placeholder: (context, url) => Container(
          width: 100,
          height: 100,
          color: Colors.transparent,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.0, 
              color: AppTheme.textGrey
            )
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 100,
          height: 100,
          color: Colors.transparent,
          child: const Icon(Icons.broken_image, size: 50, color: Colors.redAccent),
        ),
      );
    } else {
      // Show placeholder
      final bool isEve = _currentUserData?.orientation?.toLowerCase() == 'eve';
      final String placeholderUrl = isEve 
          ? evePlaceholderUrl
          : adamPlaceholderUrl;

      imageWidget = CachedNetworkImage(
        imageUrl: placeholderUrl,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        placeholder: (context, url) => Container(
          width: 100,
          height: 100,
          color: Colors.transparent,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.0, 
              color: AppTheme.textGrey
            )
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 100,
          height: 100,
          color: Colors.transparent,
          child: const Icon(Icons.broken_image, size: 50, color: Colors.redAccent),
        ),
      );
    }

    return GestureDetector(
      onTap: (_isCompressing || _isUploadingImages) 
          ? null 
          : () => _showGalleryImageSourceActionSheet(index),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: imageWidget,
          ),
          
          // ✅ SHOW COMPRESSION PROGRESS OVERLAY
          if (isCompressing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.compress,
                          color: AppTheme.primaryYellow,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: compressionProgress,
                            strokeWidth: 2.5,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryYellow),
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Optimizing\n${(compressionProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // ✅ SHOW UPLOAD PROGRESS OVERLAY
          if (isUploading && !isCompressing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          color: AppTheme.primaryYellow,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: uploadProgress,
                            strokeWidth: 2.5,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryYellow),
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uploading\n${(uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // ✅ SHOW SUCCESS CHECKMARK
          if (_uploadedCount > 0 && !isUploading && !isCompressing && hasPickedImage)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
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
        titleTextStyle: AppTextStyles.heading2.copyWith(color: AppTheme.primaryYellow),
        iconTheme: const IconThemeData(color: AppTheme.primaryYellow),
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
          ? const Center(child: CircularProgressIndicator(color: AppTheme.textGrey))
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
                      Text("Main Profile Picture", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textGrey)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickMainProfileImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.transparent,
                          backgroundImage: _pickedMainProfileImageFile != null
                              ? FileImage(_pickedMainProfileImageFile!) as ImageProvider
                              : (_currentMainProfileImageUrl != null && _currentMainProfileImageUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(_currentMainProfileImageUrl!)
                              : CachedNetworkImageProvider(isEveOrientation ? evePlaceholderUrl : adamPlaceholderUrl),
                          child: (_pickedMainProfileImageFile == null && (_currentMainProfileImageUrl == null || _currentMainProfileImageUrl!.isEmpty))
                              ? null
                              : null,
                        ),
                      ),
                      TextButton(
                        onPressed: _pickMainProfileImage,
                        child: Text("Change Main Photo", style: AppTextStyles.body1.copyWith(color: AppTheme.primaryYellow)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppTheme.textGrey, thickness: 2),
                const SizedBox(height: 20),
                Center(
                  child: Text("Profile Gallery Images", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textGrey)),
                ),
                const SizedBox(height: 20),
                
                Center(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: List.generate(5, (index) => _buildGalleryImageSlot(index)),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Note: Upload only genuine photos of yourself. To maintain a trustworthy community, accounts found catfishing will be permanently banned.",
                    style: AppTextStyles.caption.copyWith(color: AppTheme.textLight),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Text("Profile Details", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textGrey)),
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
                  Text("Profession & Financials", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textGrey)),
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

                Text("Lifestyle Preferences", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textGrey)),
                SwitchListTile(title: Text('Do you drink?', style: AppTextStyles.body1.copyWith(color: AppTheme.textGrey)), value: _drinkSelection, onChanged: (val) => setState(() => _drinkSelection = val), activeColor: AppTheme.primaryYellow),
                SwitchListTile(title: Text('Do you smoke?', style: AppTextStyles.body1.copyWith(color: AppTheme.textGrey)), value: _smokeSelection, onChanged: (val) => setState(() => _smokeSelection = val), activeColor: AppTheme.primaryYellow),
                SwitchListTile(title: Text('Do you eat meat?', style: AppTextStyles.body1.copyWith(color: AppTheme.textGrey)), value: _meatSelection, onChanged: (val) => setState(() => _meatSelection = val), activeColor: AppTheme.primaryYellow),
                SwitchListTile(title: Text('Are you open to Greek?', style: AppTextStyles.body1.copyWith(color: AppTheme.textGrey)), value: _greekSelection, onChanged: (val) => setState(() => _greekSelection = val), activeColor: AppTheme.primaryYellow),
                SwitchListTile(title: Text('Are you able to host?', style: AppTextStyles.body1.copyWith(color: AppTheme.textGrey)), value: _hostSelection, onChanged: (val) => setState(() => _hostSelection = val), activeColor: AppTheme.primaryYellow),
                SwitchListTile(title: Text('Are you able to travel?', style: AppTextStyles.body1.copyWith(color: AppTheme.textGrey)), value: _travelSelection, onChanged: (val) => setState(() => _travelSelection = val), activeColor: AppTheme.primaryYellow),

                const SizedBox(height: 24),

                // Add a Save Changes button here
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfileChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.0),
                      ),
                    ),
                    child: Text(
                      "Save Changes",
                      style: AppTextStyles.heading2.copyWith(color: AppTheme.backgroundDark),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- START: TEMPORARY NOTIFICATION TEST PANEL ---
// This panel simulates the three key notification types.
// It should be removed before production.

                const Divider(height: 40, thickness: 1, color: AppTheme.textGrey),
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
                const Divider(height: 40, thickness: 1, color: AppTheme.textGrey),
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
          prefixIcon: icon != null ? Icon(icon, color: AppTheme.textGrey) : null,
          labelStyle: AppTextStyles.body1.copyWith(color: AppTheme.textGrey),
          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.textGrey), borderRadius: BorderRadius.circular(22.0)),
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primaryYellow), borderRadius: BorderRadius.circular(22.0)),
          errorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(22.0)),
          focusedErrorBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red, width: 2), borderRadius: BorderRadius.circular(22.0)),
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
          prefixIcon: Icon(icon, color: enabled ? AppTheme.textGrey : Colors.grey),
          labelStyle: AppTextStyles.body1.copyWith(color: enabled ? AppTheme.textGrey : Colors.grey),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: enabled ? AppTheme.textGrey : Colors.grey), borderRadius: BorderRadius.circular(22.0)),
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primaryYellow), borderRadius: BorderRadius.circular(22.0)),
          disabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(22.0)),
        ),
      ),
    );
  }
}
