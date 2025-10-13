// lib/controllers/location_controller.dart

import 'package:get/get.dart';

class LocationController extends GetxController {
  // --- PRIVATE DATA ---
  // The location data is now held privately within this controller.
  final Map<String, Map<String, List<String>>> _africanLocations = {
    'South Africa': {
      'Gauteng': ['Johannesburg', 'Pretoria', 'Vereeniging'],
      'Western Cape': ['Cape Town', 'Stellenbosch', 'Paarl'],
      'KwaZulu-Natal': ['Durban', 'Pietermaritzburg', 'Richards Bay'],
    },
    'Nigeria': {
      'Lagos': ['Ikeja', 'Lekki', 'Badagry'],
      'Abuja (FCT)': ['Abuja CBD', 'Garki', 'Wuse'],
      'Rivers': ['Port Harcourt', 'Bonny', 'Okrika'],
    },
    'Kenya': {
      'Nairobi': ['Nairobi CBD', 'Westlands', 'Karen'],
      'Mombasa': ['Mombasa Island', 'Nyali', 'Likoni'],
      'Kisumu': ['Kisumu City', 'Ahero', 'Maseno'],
    },
  };

  final Map<String, Map<String, List<String>>> _asianLocations = {
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

  // --- PUBLIC STATE ---
  // This map will be initialized once with all locations.
  late final Map<String, Map<String, List<String>>> allLocations;

  @override
  void onInit() {
    super.onInit();
    // Combine the location maps when the controller is first initialized.
    allLocations = {..._africanLocations, ..._asianLocations};
  }

  // --- PUBLIC METHODS (API for your UI) ---

  /// Returns a sorted list of all available countries.
  List<String> getCountries() {
    // .toList()..sort() creates a sorted copy.
    return allLocations.keys.toList()..sort();
  }

  /// Returns a sorted list of provinces for a given country.
  /// Returns an empty list if the country is null or not found.
  List<String> getProvinces(String? country) {
    if (country == null || !allLocations.containsKey(country)) {
      return []; // Return empty list to prevent crashes
    }
    return allLocations[country]!.keys.toList()..sort();
  }

  /// Returns a sorted list of cities for a given province in a specific country.
  /// Returns an empty list if country/province is null or not found.
  List<String> getCities(String? country, String? province) {
    if (country == null ||
        province == null ||
        !allLocations.containsKey(country) ||
        !allLocations[country]!.containsKey(province)) {
      return []; // Return empty list to prevent crashes
    }
    return allLocations[country]![province]!..sort();
  }
}
