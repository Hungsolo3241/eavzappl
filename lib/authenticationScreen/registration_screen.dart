import 'dart:io'; // Added for FileImage
import 'package:eavzappl/homeScreen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Added for Obx
import 'package:eavzappl/widgets/custom_text_field_widget.dart';
import 'package:eavzappl/authenticationScreen/login_screen.dart';
import 'package:intl_phone_field/intl_phone_field.dart'; // Added for IntlPhoneField

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
  List<String> genderOptions = ["Male", "Female"];
  List<String> orientationOptions = ["Adam", "Eve"];

  TextEditingController usernameController = TextEditingController();
  String? selectedCountry;
  String? selectedProvince;
  String? selectedCity;
  List<String> countriesList = [];
  List<String> provincesList = [];
  List<String> citiesList = [];

  final Map<String, Map<String, List<String>>> africanLocations = {
    'South Africa': {
      'Gauteng': ['Johannesburg', 'Pretoria', 'Vereeniging'],
      'Western Cape': ['Cape Town', 'Stellenbosch', 'Paarl'],
      'KwaZulu-Natal': ['Durban', 'Pietermaritzburg', 'Richards Bay'],
    },
    'Nigeria': {
      'Lagos': ['Ikeja', 'Lekki', 'Badagry'],
      'Abuja (FCT)': ['Central Business District', 'Garki', 'Wuse'],
      'Rivers': ['Port Harcourt', 'Bonny', 'Okrika'],
    },
    'Kenya': {
      'Nairobi': ['Nairobi CBD', 'Westlands', 'Karen'],
      'Mombasa': ['Mombasa Island', 'Nyali', 'Likoni'],
      'Kisumu': ['Kisumu City', 'Ahero', 'Maseno'],
    },
  };

  bool lookingForBreakfast = false;
  bool lookingForLunch = false;
  bool lookingForDinner = false;
  bool lookingForLongTerm = false;
  String? selectedProfession;
  List<String> professionOptions = ["Student", "Freelancer", "Professional"];

  // Professional Venues
  final List<String> _professionalVenueOptions = [
    "The Grand - Sandton", "Blu Night - Haarties", "Royal Park - JHB",
    "XO Lounge - JHB", "Cheeky Tiger - JHB", "The Summit  - JHB",
    "Chivalry - JHB", "Diplomat -JHB", "Manhattan - Vaal", "White House - JHB",
    "Mavericks - CPT", "Stilettos - CPT", "Lush - CPT", "The Pynk - DBN", "Wonder Lounge - DBN"
  ];
  final Map<String, bool> _selectedProfessionalVenues = {};
  bool _professionalVenueOtherSelected = false;
  final TextEditingController _professionalVenueOtherNameController = TextEditingController();

  //Appearance
  String? selectedHeight;
  List<String> heightOptions = ["Short", "Average", "Tall"];
  String? selectedBodyType;
  List<String> bodyTypeOptions = ["Slim", "Athletic", "Curvy", "BBW"];

  //Lifestyle
  bool drinkSelection = false;
  bool smokeSelection = false;
  bool meatSelection = false;
  bool greekSelection = false;
  bool hostSelection = false;
  bool travelSelection = false;
  TextEditingController incomeController = TextEditingController();

  // Background
  TextEditingController nationalityController = TextEditingController();
  TextEditingController languagesController = TextEditingController();
  String? selectedEthnicity;
  List<String> ethnicityOptions = ["Black", "White", "Mixed"];

  // Social Media
  TextEditingController instagramController = TextEditingController();
  TextEditingController twitterController = TextEditingController();

  bool showProgressBar = false;

  var authenticationController = AuthenticationController.authController;



  @override
  void initState() {
    super.initState();
    countriesList = africanLocations.keys.toList();
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
    incomeController.dispose();
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
            activeColor: Colors.blueAccent,
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
            selectedOrientation == 'Eve' ? 'images/eves_background.jpeg' : 'images/adams_background.jpeg', // Dynamically set image
            fit: BoxFit.cover, // Use cover to fit the image, maintaining aspect ratio, cropping if necessary
            width: double.infinity,
            height: double.infinity,
          ),
          // Original content
          SingleChildScrollView(
            child: Column(
                children: [

                  const SizedBox(height: 100,),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.grey,
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
                          icon: const Icon(Icons.photo_library, color: Colors.grey, size: 25),
                          onPressed: () {
                            authenticationController.pickImageFromGallery();
                          },
                          tooltip: 'Pick from Gallery',
                        ),
                        const SizedBox(width: 40), // Increased spacing
                        IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.grey, size: 25),
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
                  const Text("Personal Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),

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
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), // Adjust padding if needed
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      dropdownTextStyle: const TextStyle(color: Colors.white, fontSize: 16), // For dropdown text
                      dropdownIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
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
                    height: 20,
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
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.wc_outlined, color: Colors.grey),
                        hintText: "Gender",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                      value: selectedGender,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: genderOptions.map((String value) {
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

                  //Orientation Dropdown
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 40,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.swap_horiz_outlined, color: _isOrientationFinalized ? Colors.grey[700] : Colors.grey),
                        hintText: "Orientation",
                        hintStyle: TextStyle(color: _isOrientationFinalized ? Colors.grey[700] : Colors.grey, fontSize: 16),
                        helperText: _isOrientationFinalized ? "Orientation selected and locked." : "Select carefully, this will be locked and cannot be changed later.",
                        helperStyle: TextStyle(color: _isOrientationFinalized ? Colors.green : Colors.blueGrey, fontSize: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: BorderSide(
                            color: _isOrientationFinalized ? Colors.grey[700]! : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: BorderSide(
                            color: _isOrientationFinalized ? Colors.grey[700]! : Colors.grey,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder( // Added for disabled state
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: BorderSide(
                            color: Colors.grey[700]!,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                      value: selectedOrientation,
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
                                  String prefix = "${newValue.toLowerCase()}_";
                                  String currentUsername = usernameController.text;
                                  if (currentUsername.startsWith("adam_") || currentUsername.startsWith("eve_")) {
                                      currentUsername = currentUsername.substring(currentUsername.indexOf("_") + 1);
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

                  // Country Dropdown
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 40,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.public_outlined, color: Colors.grey),
                        hintText: "Country",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                      value: selectedCountry,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: countriesList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCountry = newValue;
                          provincesList = newValue != null && africanLocations.containsKey(newValue)
                                          ? africanLocations[newValue]!.keys.toList()
                                          : [];
                          selectedProvince = null;
                          citiesList = [];
                          selectedCity = null;
                        });
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // Province/State Dropdown
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 40,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.map_outlined, color: Colors.grey),
                        hintText: "Province/State",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                      value: selectedProvince,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: provincesList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedProvince = newValue;
                          if (selectedCountry != null && newValue != null &&
                              africanLocations.containsKey(selectedCountry!) &&
                              africanLocations[selectedCountry!]!.containsKey(newValue)) {
                            citiesList = africanLocations[selectedCountry!]![newValue]!;
                          } else {
                            citiesList = [];
                          }
                          selectedCity = null;
                        });
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // City/Town Dropdown
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 40,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.location_city_outlined, color: Colors.grey),
                        hintText: "City/Town",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22.0)),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                      value: selectedCity,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: citiesList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCity = newValue;
                        });
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // Looking For - Heading
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 10.0),
                    child: Align(
                      alignment: Alignment.center, // Changed to center
                      child: Text("Looking For:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ),

                  // Looking For - Switches
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Icon(Icons.free_breakfast_outlined, color: Colors.grey),
                        SizedBox(width: 10),
                        Expanded(child: Text("Breakfast", style: const TextStyle(color: Colors.white, fontSize: 16))),
                        Switch(
                          value: lookingForBreakfast,
                          onChanged: (bool value) {
                            setState(() {
                              lookingForBreakfast = value;
                            });
                          },
                          activeColor: Colors.blueAccent,
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
                        Icon(Icons.lunch_dining_outlined, color: Colors.grey),
                        SizedBox(width: 10),
                        Expanded(child: Text("Lunch", style: const TextStyle(color: Colors.white, fontSize: 16))),
                        Switch(
                          value: lookingForLunch,
                          onChanged: (bool value) {
                            setState(() {
                              lookingForLunch = value;
                            });
                          },
                          activeColor: Colors.blueAccent,
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
                        Icon(Icons.dinner_dining_outlined, color: Colors.grey),
                        SizedBox(width: 10),
                        Expanded(child: Text("Dinner", style: const TextStyle(color: Colors.white, fontSize: 16))),
                        Switch(
                          value: lookingForDinner,
                          onChanged: (bool value) {
                            setState(() {
                              lookingForDinner = value;
                            });
                          },
                          activeColor: Colors.blueAccent,
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
                        Icon(Icons.favorite_border, color: Colors.grey),
                        SizedBox(width: 10),
                        Expanded(child: Text("Long-Term", style: const TextStyle(color: Colors.white, fontSize: 16))),
                        Switch(
                          value: lookingForLongTerm,
                          onChanged: (bool value) {
                            setState(() {
                              lookingForLongTerm = value;
                            });
                          },
                          activeColor: Colors.blueAccent,
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
                    const Text("Appearance", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),

                    const SizedBox(
                      height: 20,
                    ),

                    //height Dropdown
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.height, color: Colors.grey),
                          hintText: "Height",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        ),
                        value: selectedHeight,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: heightOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
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
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.accessibility_new_outlined, color: Colors.grey),
                          hintText: "Body Type",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        ),
                        value: selectedBodyType,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: bodyTypeOptions.map((String value) {
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
                    const Text("Lifestyle", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),

                    const SizedBox(
                      height: 20,
                    ),

                    //drink Switch
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Icon(Icons.local_bar_outlined, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(child: Text("Drink", style: const TextStyle(color: Colors.white, fontSize: 16))),
                          Switch(
                            value: drinkSelection,
                            onChanged: (bool value) {
                              setState(() {
                                drinkSelection = value;
                              });
                            },
                            activeColor: Colors.blueAccent,
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
                          Icon(Icons.smoking_rooms_outlined, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(child: Text("Smoke", style: const TextStyle(color: Colors.white, fontSize: 16))),
                          Switch(
                            value: smokeSelection,
                            onChanged: (bool value) {
                              setState(() {
                                smokeSelection = value;
                              });
                            },
                            activeColor: Colors.blueAccent,
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
                          Icon(Icons.outdoor_grill, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(child: Text("Meat", style: const TextStyle(color: Colors.white, fontSize: 16))),
                          Switch(
                            value: meatSelection, 
                            onChanged: (bool value) {
                              setState(() {
                                meatSelection = value; 
                              });
                            },
                            activeColor: Colors.blueAccent,
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
                          Icon(Icons.sports_kabaddi_outlined, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(child: Text("Greek", style: const TextStyle(color: Colors.white, fontSize: 16))),
                          Switch(
                            value: greekSelection,
                            onChanged: (bool value) {
                              setState(() {
                                greekSelection = value;
                              });
                            },
                            activeColor: Colors.blueAccent,
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
                          Icon(Icons.meeting_room_outlined, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(child: Text("Hosting", style: const TextStyle(color: Colors.white, fontSize: 16))),
                          Switch(
                            value: hostSelection,
                            onChanged: (bool value) {
                              setState(() {
                                hostSelection = value;
                              });
                            },
                            activeColor: Colors.blueAccent,
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
                          Icon(Icons.flight_takeoff_outlined, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(child: Text("Travel", style: const TextStyle(color: Colors.white, fontSize: 16))),
                          Switch(
                            value: travelSelection,
                            onChanged: (bool value) {
                              setState(() {
                                travelSelection = value;
                              });
                            },
                            activeColor: Colors.blueAccent,
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
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.work_outline, color: Colors.grey),
                          hintText: "Profession",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        ),
                        value: selectedProfession,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
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
                            Icon(Icons.add_business_outlined, color: Colors.grey),
                            const SizedBox(width: 10),
                            const Expanded(child: Text("Other/Private Venue", style: TextStyle(color: Colors.white, fontSize: 16))),
                            Switch(
                              value: _professionalVenueOtherSelected,
                              onChanged: (bool value) {
                                setState(() {
                                  _professionalVenueOtherSelected = value;
                                });
                              },
                              activeColor: Colors.blueAccent,
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
                      height: 45,
                      child: CustomTextFieldWidget(
                        editingController: incomeController,
                        iconData: Icons.attach_money_outlined,
                        labelText: "Income Range",
                        isObscure: false,
                        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    // Background Title
                    const SizedBox(height: 30),
                    const Text("Background", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.group_outlined, color: Colors.grey),
                          hintText: "Ethnicity",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(22.0)),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        ),
                        value: selectedEthnicity,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: ethnicityOptions.map((String value) {
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
                    const Text("Social Media", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                  ],

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
                          Get.snackbar("Missing Field", "Please select a profile photo.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                          setState(() { showProgressBar = false; }); 
                          return;
                        }
                        if (emailController.text.trim().isEmpty) {
                          Get.snackbar("Missing Field", "Please enter your email.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                           setState(() { showProgressBar = false; });
                          return;
                        }
                        if (passwordController.text.trim().isEmpty) {
                          Get.snackbar("Missing Field", "Please enter your password.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                           setState(() { showProgressBar = false; });
                          return;
                        }
                        if (nameController.text.trim().isEmpty) {
                          Get.snackbar("Missing Field", "Please enter your name.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                           setState(() { showProgressBar = false; });
                          return;
                        }
                        if (ageController.text.trim().isEmpty) {
                            Get.snackbar("Missing Field", "Please enter your age.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                        }
                        int? age = int.tryParse(ageController.text.trim());
                        if (age == null) {
                            Get.snackbar(
                                "Validation Error",
                                "Please enter a valid number for age.",
                                backgroundColor: Colors.blueGrey,
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
                          Get.snackbar("Missing Field", "Please select your gender.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                           setState(() { showProgressBar = false; });
                          return;
                        }
                        if (selectedOrientation == null) {
                          Get.snackbar("Missing Field", "Please select your orientation.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                           setState(() { showProgressBar = false; });
                          return;
                        }
                         if (usernameController.text.trim().isEmpty) {
                          Get.snackbar("Missing Field", "Please enter your username.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                           setState(() { showProgressBar = false; });
                          return;
                        }
                        // UPDATED phone number validation
                        if (normalizedPhoneNumber == null || normalizedPhoneNumber!.isEmpty) {
                          Get.snackbar("Missing Field", "Please enter your phone number.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                           setState(() { showProgressBar = false; });
                          return;
                        }
                        if (selectedCountry == null) {
                          Get.snackbar("Missing Field", "Please select your country.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                           setState(() { showProgressBar = false; });
                          return;
                        }
                        if (selectedProvince == null) {
                          Get.snackbar("Missing Field", "Please select your province/state.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                           setState(() { showProgressBar = false; });
                          return;
                        }
                        if (selectedCity == null) {
                          Get.snackbar("Missing Field", "Please select your city/town.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                           setState(() { showProgressBar = false; });
                          return;
                        }

                        // Eve-specific field validation
                        if (selectedOrientation == 'Eve') {
                          if (selectedHeight == null) {
                            Get.snackbar("Missing Field (Eve Profile)", "Please select your height.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (selectedBodyType == null) {
                            Get.snackbar("Missing Field (Eve Profile)", "Please select your body type.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (selectedProfession == null) {
                            Get.snackbar("Missing Field (Eve Profile)", "Please select your profession.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (incomeController.text.trim().isEmpty) {
                            Get.snackbar("Missing Field (Eve Profile)", "Please enter your income range.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (nationalityController.text.trim().isEmpty) {
                            Get.snackbar("Missing Field (Eve Profile)", "Please enter your nationality.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (languagesController.text.trim().isEmpty) {
                            Get.snackbar("Missing Field (Eve Profile)", "Please enter languages spoken.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
                            setState(() { showProgressBar = false; });
                            return;
                          }
                          if (selectedEthnicity == null) {
                            Get.snackbar("Missing Field (Eve Profile)", "Please select your ethnicity.", backgroundColor: Colors.blueGrey, colorText: Colors.white);
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
                              'profession': selectedProfession,
                              'income': incomeController.text.trim(),
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
                          
                          await authenticationController.createAccountAndSaveData(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                            authenticationController.profilePhoto,
                            userData,
                          );
                        } catch (error) {
                          Get.snackbar("Registration Failed", error.toString(), backgroundColor: Colors.blueGrey, colorText: Colors.white);
                        } finally {
                          setState(() {
                            showProgressBar = false;
                          });
                        }
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  showProgressBar == true
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white12),
                  )
                      : Container(),

                  const SizedBox(height: 30), 

                ],
              ),
          ),
        ],
      )
    );
  }
}
