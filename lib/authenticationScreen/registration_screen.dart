import 'package:flutter/material.dart';
import 'package:eavzappl/widgets/custom_text_field_widget.dart';
import 'package:eavzappl/authenticationScreen/login_screen.dart';

class RegistrationScreen extends StatefulWidget
{

  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
{
  //Personal info
  TextEditingController? emailController = TextEditingController();
  TextEditingController? passwordController = TextEditingController();
  TextEditingController? nameController = TextEditingController();
  TextEditingController? ageController = TextEditingController();
  TextEditingController? phoneNumberController = TextEditingController(); 
  String? selectedGender;
  String? selectedOrientation; // Renamed from selectedSpecies
  List<String> genderOptions = ["Male", "Female"];
  List<String> orientationOptions = ["Adam", "Eve"]; // Renamed from speciesOptions

  TextEditingController? usernameController = TextEditingController();
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
  TextEditingController? professionalAtController = TextEditingController(); // Added

  //Appearance
  String? selectedHeight;
  List<String> heightOptions = ["Short", "Average", "Tall"];
  String? selectedBodyType;
  List<String> bodyTypeOptions = ["Slim", "Athletic", "Curvy", "BBW"];

  //Lifestyle
  bool drinkSelection = false;
  bool smokeSelection = false;
  bool meatSelection = false; // Added for the meat switch
  bool greekSelection = false;
  bool hostSelection = false;
  bool travelSelection = false;
  TextEditingController? incomeController = TextEditingController();

  // Background
  TextEditingController? nationalityController = TextEditingController();
  TextEditingController? languagesController = TextEditingController();
  String? selectedEthnicity;
  List<String> ethnicityOptions = ["Black", "White", "Mixed"];

  // Social Media
  TextEditingController? instagramController = TextEditingController();
  TextEditingController? twitterController = TextEditingController();

  bool showProgressBar = false;

  @override
  void initState() {
    super.initState();
    countriesList = africanLocations.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( // Added Stack for background image
        children: <Widget>[
          // Background Image
          Center( // Center the image
            child: Image.asset(
              'images/reg_background.png', // User provided path
              fit: BoxFit.contain, // Use contain to fit the image without cropping, maintaining aspect ratio
              // Removed width and height to allow natural sizing or scaling down
            ),
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

                    },
                    child: const CircleAvatar(
                      radius: 100,
                      backgroundImage: AssetImage("images/adam_avatar.jpeg"),
                      backgroundColor: Colors.black,
                    )
                  ),

                  const SizedBox(height: 50,),

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

                  //phoneNumber
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 40,
                    height: 45,
                    child: CustomTextFieldWidget(
                      editingController: phoneNumberController,
                      iconData: Icons.phone_outlined,
                      labelText: "Phone",
                      isObscure: false,
                      textStyle: const TextStyle(color: Colors.white, fontSize: 16),
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
                        prefixIcon: Icon(Icons.swap_horiz_outlined, color: Colors.grey),
                        hintText: "Orientation", 
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
                      value: selectedOrientation,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: orientationOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedOrientation = newValue;
                          if (newValue != null && usernameController != null) {
                            String prefix = "${newValue.toLowerCase()}.";
                            String currentUsername = usernameController!.text;
                            String suffix = "";
                            if (currentUsername.startsWith("adam.")) {
                              suffix = currentUsername.substring(5);
                            } else if (currentUsername.startsWith("eve.")) {
                              suffix = currentUsername.substring(4);
                            } else {
                              suffix = currentUsername;
                            }
                            usernameController!.text = prefix + suffix;
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
                      labelText: "Alias",
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
                            value: meatSelection, // Changed to meatSelection
                            onChanged: (bool value) {
                              setState(() {
                                meatSelection = value; // Changed to meatSelection
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
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        height: 45,
                        child: CustomTextFieldWidget(
                          editingController: professionalAtController,
                          iconData: Icons.domain_outlined,
                          labelText: "Professional at:",
                          isObscure: false,
                          textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
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
                        iconData: Icons.camera_alt_outlined, // Placeholder for Instagram icon
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
                        iconData: Icons.alternate_email_outlined, // Placeholder for Twitter icon
                        labelText: "Twitter/X",
                        isObscure: false,
                        textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    // Add a final SizedBox at the bottom for some padding when scrolled to the end
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
                      onPressed: () {
                        // TODO: Implement account creation logic
                        print("Create Account button pressed");
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

                  // Login option
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

                  const SizedBox(height: 30), // Extra padding at the very bottom

                ],
              ),
          ),
        ],
      )
    );
  }
}
