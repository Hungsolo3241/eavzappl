// Added for FileImage
import 'package:eavzappl/homeScreen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Added for Obx
import 'package:eavzappl/widgets/custom_text_field_widget.dart';
import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:intl_phone_field/intl_phone_field.dart'; // Added for IntlPhoneField
import 'package:eavzappl/controllers/location_controller.dart';
import 'package:eavzappl/utils/app_constants.dart';
import 'package:eavzappl/utils/app_theme.dart';

import '../controllers/authentication_controller.dart';


class RegistrationScreen extends StatefulWidget
{

  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
{
  //Personal info
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  // TextEditingController phoneNumberController = TextEditingController(); // REMOVED
  String? completePhoneNumber; // To store the full international number like +27821234567
  String? normalizedPhoneNumber; // To store the number like 27821234567 for wa.me

  String? selectedGender;
  String? selectedOrientation;
  bool _isOrientationFinalized = false; // Added to track if orientation is set
  List<String> orientationOptions = ["Adam", "Eve"];

  TextEditingController usernameController = TextEditingController();
  String? selectedCountry;
  String? selectedProvince;
  String? selectedCity;
  String? selectedEthnicity;
  String? selectedRelationshipStatus;
  String? selectedIncome;

  final LocationController locationController = Get.put(LocationController());

  bool lookingForBreakfast = false;
  bool lookingForLunch = false;
  bool lookingForDinner = false;
  bool lookingForLongTerm = false;
  String? selectedProfession;
  List<String> professionOptions = ["Student", "Freelancer", "Professional"];

  // Professional Venues
  final List<String> _professionalVenueOptions = [
    "The Grand - JHB", "Blu Night Revue Bar - Haarties", "Royal Park - JHB",
    "The Summit - JHB", "Chivalry Lounge - JHB", "Manhattan - Vaal",
    "Mavericks Revue Bar - CPT", "Lush Capetown - CPT", "The Pynk - DBN", "Wonder Lounge - DBN"
  ];
  final Map<String, bool> _selectedProfessionalVenues = {};
  bool _professionalVenueOtherSelected = false;
  final TextEditingController _professionalVenueOtherNameController = TextEditingController();

  //Appearance
  String? selectedHeight;
  String? selectedBodyType;

  //Lifestyle
  bool drinkSelection = false;
  bool smokeSelection = false;
  bool meatSelection = false;
  bool greekSelection = false;
  bool hostSelection = false;
  bool travelSelection = false;

  // Background
  TextEditingController nationalityController = TextEditingController();
  TextEditingController languagesController = TextEditingController();

  // Social Media
  TextEditingController instagramController = TextEditingController();
  TextEditingController twitterController = TextEditingController();

  bool showProgressBar = false;

  var authenticationController = AuthenticationController.instance;

  @override
  void initState() {
    super.initState();
    authenticationController.resetProfilePhoto(); // Reset profile photo on init

    for (var venue in _professionalVenueOptions) {
      _selectedProfessionalVenues[venue] = false;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    ageController.dispose();
    // phoneNumberController.dispose(); // REMOVED
    usernameController.dispose();
    nationalityController.dispose();
    languagesController.dispose();
    instagramController.dispose();
    twitterController.dispose();
    _professionalVenueOtherNameController.dispose();
    super.dispose();
  }

  Widget _buildVenueSwitch(String title, IconData iconData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: Row(
        children: [
          Icon(iconData, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16))),
          Switch(
            value: _selectedProfessionalVenues[title] ?? false,
            onChanged: (bool value) {
              setState(() {
                _selectedProfessionalVenues[title] = value;
              });
            },
            activeThumbColor: Colors.blueAccent,
            inactiveThumbColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack( // Added Stack for background image
          children: <Widget>[
            // Background Image
            Image.asset(
              selectedOrientation == 'Eve' ? 'images/eves_background.webp' : 'images/adams_background.webp', // Dynamically set image
              fit: BoxFit.cover, // Use cover to fit the image, maintaining aspect ratio, cropping if necessary
              width: double.infinity,
              height: double.infinity,
            ),
            // --- START OF THE ONLY MODIFICATION ---
            SafeArea(
              // Original content (now wrapped by SafeArea)
              child: SingleChildScrollView(
                child: Column(
                  children: [

                    const SizedBox(height: 100,),

                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 30,
                        color: AppTheme.textGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5,),

                    // choose image circle avatar
                    GestureDetector(
                      onTap: ()
                      {
                        // Default action, can be overridden by specific icon buttons below
                        // Or remove this if only icons should trigger actions
                      },
                      child: Obx(() => CircleAvatar( // Wrapped with Obx
                        radius: 100,
                        backgroundImage: authenticationController.profilePhoto != null
                            ? FileImage(authenticationController.profilePhoto!)
                            : (selectedOrientation == 'Eve'
                                ? const AssetImage("images/eves_avatar.jpeg")
                                : const AssetImage("images/adam_avatar.jpeg")) as ImageProvider,
                        backgroundColor: Colors.black,
                      )),
                    ),

                    // Icons for gallery and camera
                    Padding( // Added padding for the icons row
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_library, color: AppTheme.textGrey, size: 25),
                            onPressed: () {
                              authenticationController.pickImageFromGallery();
                            },
                            tooltip: 'Pick from Gallery',
                          ),
                          const SizedBox(width: 40), // Increased spacing
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: AppTheme.textGrey, size: 25),
                            onPressed: () {
                              authenticationController.captureImageFromPhoneCamera();
                            },
                            tooltip: 'Capture from Camera',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20,), // Adjusted spacing after icons

                    // Personal Info Title
                    const SizedBox(height: 30),
                    const Text("Personal Info", style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
                    const SizedBox(height: 10),

                    //Orientation Dropdown
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.swap_horiz_outlined, color: _isOrientationFinalized ? Colors.grey[700] : Colors.grey),
                          hintText: "Orientation",
                          hintStyle: TextStyle(color: _isOrientationFinalized ? Colors.grey[700] : Colors.grey, fontSize: 16),
                          helperText: _isOrientationFinalized ? "Orientation selected and locked." : "Select carefully, this will be locked and cannot be changed later.",
                          helperStyle: TextStyle(color: _isOrientationFinalized ? Colors.green : AppTheme.textGrey, fontSize: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(
                              color: _isOrientationFinalized ? Colors.grey[700]! : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(
                              color: _isOrientationFinalized ? Colors.grey[700]! : Colors.grey,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder( // Added for disabled state
                            borderRadius: const BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(
                              color: Colors.grey[700]!,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        ),
                        initialValue: selectedOrientation,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: _isOrientationFinalized ? Colors.grey[700] : Colors.grey),
                        dropdownColor: Colors.black,
                        style: TextStyle(color: _isOrientationFinalized ? Colors.grey[700] : Colors.white, fontSize: 16),
                        items: orientationOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: _isOrientationFinalized
                            ? null
                            : (String? newValue) {
                          setState(() {
                            selectedOrientation = newValue;
                            if (newValue != null) { // usernameController is always non-null
                              String prefix = "$newValue ○ ";
                              String currentUsername = usernameController.text;
                              if (currentUsername.startsWith("Adam ○") || currentUsername.startsWith("Eve ○")) {
                                currentUsername = currentUsername.substring(currentUsername.indexOf("○") + 1);
                              }
                              usernameController.text = prefix + currentUsername;
                            }
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // email
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      height: 45,
                      child: CustomTextFieldWidget(
                        editingController: emailController,
                        iconData: Icons.email_outlined,
                        labelText: "Email",
                        isObscure: false,
                        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    //password
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      height: 45,
                      child: CustomTextFieldWidget(
                        editingController: passwordController,
                        iconData: Icons.lock_outline,
                        labelText: "Password",
                        isObscure: true,
                        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    //phoneNumber (using IntlPhoneField)
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      // Height might adjust automatically or you can wrap IntlPhoneField if needed
                      child: IntlPhoneField(
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(color: Colors.grey, fontSize: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), // Adjust padding if needed
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        dropdownTextStyle: const TextStyle(color: Colors.white, fontSize: 16), // For dropdown text
                        dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        initialCountryCode: 'ZA', // Set an initial default country if desired
                        onChanged: (phone) {
                          setState(() {
                            if (phone.completeNumber.isNotEmpty) {
                              completePhoneNumber = phone.completeNumber; // e.g., +27821234567
                              normalizedPhoneNumber = phone.countryCode + phone.number; // e.g., 27821234567
                            } else {
                              completePhoneNumber = null;
                              normalizedPhoneNumber = null;
                            }
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    //name
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      height: 45,
                      child: CustomTextFieldWidget(
                        editingController: nameController,
                        iconData: Icons.person_outline,
                        labelText: "Name",
                        isObscure: false,
                        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    //age
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      height: 45,
                      child: CustomTextFieldWidget(
                        editingController: ageController,
                        iconData: Icons.cake_outlined,
                        labelText: "Age",
                        isObscure: false,
                        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        keyboardType: TextInputType.number,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    //gender Dropdown
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.wc_outlined, color: Colors.grey),
                          hintText: "Gender",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        ),
                        initialValue: selectedGender,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: AppConstants.genders
                            .where((gender) => gender != "Any") // <-- Removes "Any" from the list
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedGender = newValue;
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.favorite_border, color: Colors.grey),
                          hintText: "Relationship Status",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        ),
                        initialValue: selectedRelationshipStatus,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: AppConstants.relationshipStatuses.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(color: Colors.white)), // Added style for visibility
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedRelationshipStatus = newValue;
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    //username
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      height: 45,
                      child: CustomTextFieldWidget(
                        editingController: usernameController,
                        iconData: Icons.account_circle_outlined,
                        labelText: "Username",
                        isObscure: false,
                        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // --- START: UNIFIED, STYLED, AND CONTROLLER-DRIVEN LOCATION DROPDOWNS ---
                    const SizedBox(height: 30),
                    const Text("Location", style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
                    const SizedBox(height: 10),

                    // Country Dropdown
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.public, color: Colors.grey),
                          hintText: "Country",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        ),
                        initialValue: selectedCountry,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: locationController.getCountries().map((String item) {
                          return DropdownMenuItem<String>(value: item, child: Text(item));
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedCountry = newValue;
                            selectedProvince = null; // Reset dependent fields
                            selectedCity = null;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Province/State Dropdown
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.map_outlined, color: Colors.grey),
                          hintText: "Province / State",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          disabledBorder: OutlineInputBorder( // Style for when it's disabled
                            borderRadius: const BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        ),
                        initialValue: selectedProvince,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: selectedCountry != null ? Colors.grey : Colors.grey.withOpacity(0.5)),
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: locationController.getProvinces(selectedCountry).map((String item) {
                          return DropdownMenuItem<String>(value: item, child: Text(item));
                        }).toList(),
                        onChanged: selectedCountry == null ? null : (newValue) { // Disable if no country
                          setState(() {
                            selectedProvince = newValue;
                            selectedCity = null; // Reset city
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // City Dropdown
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.grey),
                          hintText: "City",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          disabledBorder: OutlineInputBorder( // Style for when it's disabled
                            borderRadius: const BorderRadius.all(Radius.circular(22.0)),
                            borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        ),
                        initialValue: selectedCity,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: selectedProvince != null ? Colors.grey : Colors.grey.withOpacity(0.5)),
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: locationController.getCities(selectedCountry, selectedProvince).map((String item) {
                          return DropdownMenuItem<String>(value: item, child: Text(item));
                        }).toList(),
                        onChanged: selectedProvince == null ? null : (newValue) { // Disable if no province
                          setState(() {
                            selectedCity = newValue;
                          });
                        },
                      ),
                    ),
                    // --- END OF LOCATION DROPDOWNS ---


                    const SizedBox(
                      height: 20,
                    ),

                    // Looking For - Switches
                    // Looking For - Heading
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 10.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                            selectedOrientation == 'Eve'
                                ? "Available For:"
                                : "Looking For:", // <<< MODIFIED LINE
                            style: const TextStyle(fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textGrey)
                        ),
                      ),
                    ),Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          const Icon(Icons.free_breakfast_outlined, color: Colors.grey),
                          const SizedBox(width: 10),
                          const Expanded(child: Text("Breakfast", style: TextStyle(color: Colors.white, fontSize: 16))),
                          Switch(
                            value: lookingForBreakfast,
                            onChanged: (bool value) {
                              setState(() {
                                lookingForBreakfast = value;
                              });
                            },
                            activeThumbColor: Colors.blueAccent,
                            inactiveThumbColor: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          const Icon(Icons.lunch_dining_outlined, color: Colors.grey),
                          const SizedBox(width: 10),
                          const Expanded(child: Text("Lunch", style: TextStyle(color: Colors.white, fontSize: 16))),
                          Switch(
                            value: lookingForLunch,
                            onChanged: (bool value) {
                              setState(() {
                                lookingForLunch = value;
                              });
                            },
                            activeThumbColor: Colors.blueAccent,
                            inactiveThumbColor: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          const Icon(Icons.dinner_dining_outlined, color: Colors.grey),
                          const SizedBox(width: 10),
                          const Expanded(child: Text("Dinner", style: TextStyle(color: Colors.white, fontSize: 16))),
                          Switch(
                            value: lookingForDinner,
                            onChanged: (bool value) {
                              setState(() {
                                lookingForDinner = value;
                              });
                            },
                            activeThumbColor: Colors.blueAccent,
                            inactiveThumbColor: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_border, color: Colors.grey),
                          const SizedBox(width: 10),
                          const Expanded(child: Text("Long-Term", style: TextStyle(color: Colors.white, fontSize: 16))),
                          Switch(
                            value: lookingForLongTerm,
                            onChanged: (bool value) {
                              setState(() {
                                lookingForLongTerm = value;
                              });
                            },
                            activeThumbColor: Colors.blueAccent,
                            inactiveThumbColor: Colors.grey,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    if (selectedOrientation == 'Eve') ...[
                      // Appearance Title
                      const SizedBox(height: 30),
                      const Text("Appearance", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
                      const SizedBox(height: 10),

                      const SizedBox(
                        height: 20,
                      ),

                      //height Dropdown
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.height, color: Colors.grey),
                            hintText: "Height",
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22.0)),
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22.0)),
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          ),
                          initialValue: selectedHeight,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          items: AppConstants.heights.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(color: Colors.white)), // Added style for visibility
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedHeight = newValue;
                            });
                          },
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      //body type Dropdown
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.accessibility_new_outlined, color: Colors.grey),
                            hintText: "Body Type",
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22.0)),
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22.0)),
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          ),
                          initialValue: selectedBodyType,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          items: AppConstants.bodyTypes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedBodyType = newValue;
                            });
                          },
                        ),
                      ),

                      // Lifestyle Title
                      const SizedBox(height: 30),
                      const Text("Lifestyle", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
                      const SizedBox(height: 10),

                      const SizedBox(
                        height: 20,
                      ),

                      //drink Switch
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            const Icon(Icons.local_bar_outlined, color: Colors.grey),
                            const SizedBox(width: 10),
                            const Expanded(child: Text("Drink", style: TextStyle(color: Colors.white, fontSize: 16))),
                            Switch(
                              value: drinkSelection,
                              onChanged: (bool value) {
                                setState(() {
                                  drinkSelection = value;
                                });
                              },
                              activeThumbColor: Colors.blueAccent,
                              inactiveThumbColor: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      //smoke Switch
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            const Icon(Icons.smoking_rooms_outlined, color: Colors.grey),
                            const SizedBox(width: 10),
                            const Expanded(child: Text("Smoke", style: TextStyle(color: Colors.white, fontSize: 16))),
                            Switch(
                              value: smokeSelection,
                              onChanged: (bool value) {
                                setState(() {
                                  smokeSelection = value;
                                });
                              },
                              activeThumbColor: Colors.blueAccent,
                              inactiveThumbColor: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      //meat Switch
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            const Icon(Icons.outdoor_grill, color: Colors.grey),
                            const SizedBox(width: 10),
                            const Expanded(child: Text("Meat", style: TextStyle(color: Colors.white, fontSize: 16))),
                            Switch(
                              value: meatSelection,
                              onChanged: (bool value) {
                                setState(() {
                                  meatSelection = value;
                                });
                              },
                              activeThumbColor: Colors.blueAccent,
                              inactiveThumbColor: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      //greek Switch
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            const Icon(Icons.sports_kabaddi_outlined, color: Colors.grey),
                            const SizedBox(width: 10),
                            const Expanded(child: Text("Greek", style: TextStyle(color: Colors.white, fontSize: 16))),
                            Switch(
                              value: greekSelection,
                              onChanged: (bool value) {
                                setState(() {
                                  greekSelection = value;
                                });
                              },
                              activeThumbColor: Colors.blueAccent,
                              inactiveThumbColor: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      //host Switch
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            const Icon(Icons.meeting_room_outlined, color: Colors.grey),
                            const SizedBox(width: 10),
                            const Expanded(child: Text("Hosting", style: TextStyle(color: Colors.white, fontSize: 16))),
                            Switch(
                              value: hostSelection,
                              onChanged: (bool value) {
                                setState(() {
                                  hostSelection = value;
                                });
                              },
                              activeThumbColor: Colors.blueAccent,
                              inactiveThumbColor: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      //travel Switch
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            const Icon(Icons.flight_takeoff_outlined, color: Colors.grey),
                            const SizedBox(width: 10),
                            const Expanded(child: Text("Travel", style: TextStyle(color: Colors.white, fontSize: 16))),
                            Switch(
                              value: travelSelection,
                              onChanged: (bool value) {
                                setState(() {
                                  travelSelection = value;
                                });
                              },
                              activeThumbColor: Colors.blueAccent,
                              inactiveThumbColor: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      //profession Dropdown
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.work_outline, color: Colors.grey),
                            hintText: "Profession",
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22.0)),
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22.0)),
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          ),
                          initialValue: selectedProfession,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          items: professionOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedProfession = newValue;
                            });
                          },
                        ),
                      ),

                      if (selectedProfession == 'Professional') ...[
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text("Venues:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                        const SizedBox(height: 10),
                        ..._professionalVenueOptions.map((venue) => _buildVenueSwitch(venue, Icons.nightlife)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                          child: Row(
                            children: [
                              const Icon(Icons.add_business_outlined, color: Colors.grey),
                              const SizedBox(width: 10),
                              const Expanded(child: Text("Other/Private Venue", style: TextStyle(color: Colors.white, fontSize: 16))),
                              Switch(
                                value: _professionalVenueOtherSelected,
                                onChanged: (bool value) {
                                  setState(() {
                                    _professionalVenueOtherSelected = value;
                                  });
                                },
                                activeThumbColor: Colors.blueAccent,
                                inactiveThumbColor: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                        if (_professionalVenueOtherSelected) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 40,
                            height: 45,
                            child: CustomTextFieldWidget(
                              editingController: _professionalVenueOtherNameController,
                              iconData: Icons.domain_verification_outlined,
                              labelText: "Other Venue Name",
                              isObscure: false,
                              textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(
                        height: 20,
                      ),



                      //income
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.attach_money_outlined, color: Colors.grey),
                            hintText: "Income Bracket",
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22.0)),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22.0)),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          ),
                          initialValue: selectedIncome, // USES THE CORRECT STATE VARIABLE
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          items: AppConstants.incomeBrackets.map((String value) { // USES AppConstants
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedIncome = newValue; // UPDATES THE CORRECT STATE VARIABLE
                            });
                          },
                        ),
                      ),


                      // Background Title
                      const SizedBox(height: 30),
                      const Text("Background", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
                      const SizedBox(height: 10),

                      const SizedBox(
                        height: 20,
                      ),

                      //nationality
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        height: 45,
                        child: CustomTextFieldWidget(
                          editingController: nationalityController,
                          iconData: Icons.flag_outlined,
                          labelText: "Nationality",
                          isObscure: false,
                          textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      //languages
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        height: 45,
                        child: CustomTextFieldWidget(
                          editingController: languagesController,
                          iconData: Icons.translate_outlined,
                          labelText: "Languages Spoken",
                          isObscure: false,
                          textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      //ethnicity Dropdown
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.group_outlined, color: Colors.grey),
                            hintText: "Ethnicity",
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22.0)),
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(22.0)),
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          ),
                          initialValue: selectedEthnicity,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          items: AppConstants.ethnicities.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedEthnicity = newValue;
                            });
                          },
                        ),
                      ),

                      // Social Media Title
                      const SizedBox(height: 30),
                      const Text("Social Media", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
                      const SizedBox(height: 10),

                      // Instagram
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        height: 45,
                        child: CustomTextFieldWidget(
                          editingController: instagramController,
                          iconData: Icons.camera_alt_outlined,
                          labelText: "Instagram",
                          isObscure: false,
                          textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // Twitter
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        height: 45,
                        child: CustomTextFieldWidget(
                          editingController: twitterController,
                          iconData: Icons.alternate_email_outlined,
                          labelText: "Twitter/X",
                          isObscure: false,
                          textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                    ], // This closing bracket corresponds to `if (selectedOrientation == 'Eve') ...[`

                    const SizedBox(height: 30),

                    // Create Account Button
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      height: 35,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _isOrientationFinalized = true;
                          });

                          // 1. Validation
                          if (authenticationController.profilePhoto == null) {
                            Get.snackbar("Missing Field", "Please select a profile photo.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (emailController.text.trim().isEmpty) {
                            Get.snackbar("Missing Field", "Please enter your email.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (passwordController.text.trim().isEmpty) {
                            Get.snackbar("Missing Field", "Please enter your password.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (nameController.text.trim().isEmpty) {
                            Get.snackbar("Missing Field", "Please enter your name.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (ageController.text.trim().isEmpty) {
                            Get.snackbar("Missing Field", "Please enter your age.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          int? age = int.tryParse(ageController.text.trim());
                          if (age == null) {
                            Get.snackbar(
                                "Validation Error",
                                "Please enter a valid number for age.",
                                backgroundColor: AppTheme.textGrey,
                                colorText: Colors.white);
                            setState(() {
                              showProgressBar = false;
                            });
                            return;
                          }
                          if (age < 18) {
                            Get.snackbar(
                                "Validation Error",
                                "You must be at least 18 years old to register.",
                                backgroundColor: Colors.redAccent,
                                colorText: Colors.white);
                            setState(() {
                              showProgressBar = false;
                            });
                            return;
                          }
                          if (selectedGender == null) {
                            Get.snackbar("Missing Field", "Please select your gender.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (selectedRelationshipStatus == null) {
                            Get.snackbar("Missing Field", "Please select your relationship status.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (selectedOrientation == null) {
                            Get.snackbar("Missing Field", "Please select your orientation.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (usernameController.text.trim().isEmpty) {
                            Get.snackbar("Missing Field", "Please enter your username.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          // UPDATED phone number validation
                          if (normalizedPhoneNumber == null || normalizedPhoneNumber!.isEmpty) {
                            Get.snackbar("Missing Field", "Please enter your phone number.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (selectedCountry == null) {
                            Get.snackbar("Missing Field", "Please select your country.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (selectedProvince == null) {
                            Get.snackbar("Missing Field", "Please select your province/state.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (selectedCity == null) {
                            Get.snackbar("Missing Field", "Please select your city/town.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }

                          // Eve-specific field validation
                          if (selectedOrientation == 'Eve') {
                            if (selectedHeight == null) {
                              Get.snackbar("Missing Field (Eve Profile)", "Please select your height.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                              setState(() { showProgressBar = false; });
                              return;
                            }
                            if (selectedBodyType == null) {
                              Get.snackbar("Missing Field (Eve Profile)", "Please select your body type.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                              setState(() { showProgressBar = false; });
                              return;
                            }
                            if (selectedProfession == null) {
                              Get.snackbar("Missing Field (Eve Profile)", "Please select your profession.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                              setState(() { showProgressBar = false; });
                              return;
                            }
                            if (selectedIncome == null) {
                              Get.snackbar("Missing Field (Eve Profile)", "Please select your income bracket.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                              setState(() { showProgressBar = false; });
                              return;
                            }
                            if (nationalityController.text.trim().isEmpty) {
                              Get.snackbar("Missing Field (Eve Profile)", "Please enter your nationality.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                              setState(() { showProgressBar = false; });
                              return;
                            }
                            if (languagesController.text.trim().isEmpty) {
                              Get.snackbar("Missing Field (Eve Profile)", "Please enter languages spoken.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                              setState(() { showProgressBar = false; });
                              return;
                            }
                            if (selectedEthnicity == null) {
                              Get.snackbar("Missing Field (Eve Profile)", "Please select your ethnicity.", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                              setState(() { showProgressBar = false; });
                              return;
                            }
                          }

                          setState(() {
                            showProgressBar = true;
                          });

                          try {
                            Map<String, dynamic> userData = {
                              'name': nameController.text.trim(),
                              'age': age,
                              'phoneNumber': normalizedPhoneNumber, // Use the normalized number
                              'gender': selectedGender,
                              'relationshipStatus': selectedRelationshipStatus,
                              'orientation': selectedOrientation,
                              'username': usernameController.text.trim(),
                              'city': selectedCity,
                              'country': selectedCountry,
                              'province': selectedProvince,
                              'lookingForBreakfast': lookingForBreakfast,
                              'lookingForLunch': lookingForLunch,
                              'lookingForDinner': lookingForDinner,
                              'lookingForLongTerm': lookingForLongTerm,
                              'publishedDateTime': DateTime.now().millisecondsSinceEpoch,
                            };

                            if (selectedOrientation == 'Eve') {
                              userData.addAll({
                                'height': selectedHeight,
                                'bodyType': selectedBodyType,
                                'drinkSelection': drinkSelection,
                                'smokeSelection': smokeSelection,
                                'meatSelection': meatSelection,
                                'greekSelection': greekSelection,
                                'hostSelection': hostSelection,
                                'travelSelection': travelSelection,
                                'profession': selectedProfession,'income': selectedIncome,
                                'nationality': nationalityController.text.trim(),
                                'languages': languagesController.text.trim(),
                                'ethnicity': selectedEthnicity,
                                'instagram': instagramController.text.trim(),
                                'twitter': twitterController.text.trim(),
                              });

                              if (selectedProfession == 'Professional') {
                                List<String> venues = [];
                                _selectedProfessionalVenues.forEach((key, value) {
                                  if (value == true) {
                                    venues.add(key);
                                  }
                                });
                                if (_professionalVenueOtherSelected &&
                                    _professionalVenueOtherNameController.text.trim().isNotEmpty) {
                                  venues.add("Other: ${_professionalVenueOtherNameController.text.trim()}");
                                }
                                userData['professionalVenues'] = venues;
                              }
                            }

                            // Call createAccountAndSaveData and check its boolean result
                            bool registrationSuccessful = await authenticationController.createAccountAndSaveData(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                              authenticationController.profilePhoto,
                              userData,
                            );

                            if (registrationSuccessful) {
                              authenticationController.resetProfilePhoto(); // Reset profile photo on successful registration
                              // Navigate to HomeScreen only if registration was successful
                              Get.offAll(() => const HomeScreen());
                              // No need to set showProgressBar to false here if navigating away
                            } else {
                              // If registration was not successful, the snackbar was already shown by the controller.
                              // We just need to ensure the progress bar is hidden.
                              if (mounted) {
                                setState(() {
                                  showProgressBar = false;
                                });
                              }
                            }

                          } catch (error) {
                            // This catch block is for unexpected errors not caught by the controller,
                            // or if createAccountAndSaveData itself threw something despite its own catches.
                            Get.snackbar("Registration Failed", "An unexpected error occurred: ${error.toString()}", backgroundColor: AppTheme.textGrey, colorText: Colors.white);
                            if (mounted) { // Check if the widget is still in the tree
                              setState(() {
                                showProgressBar = false;
                              });
                            }
                          }
                          // The finally block is removed as its logic is now handled by the if/else after the await
                          // and within the catch block for hiding the progress bar.
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22.0),
                          ),
                        ),
                        child: const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // const SizedBox(height: 30),

                    showProgressBar == true
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white12),
                    )
                        : Container(),

                    const SizedBox(height: 30),

                  ],
                ),
              ),
            ),
            // --- END OF THE ONLY MODIFICATION ---
          ],
        )
    );
  }
}
