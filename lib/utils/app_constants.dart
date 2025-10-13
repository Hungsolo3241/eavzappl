// lib/utils/app_constants.dart

class AppConstants {
  // Make the class non-instantiable
  AppConstants._();

  // --- SINGLE SOURCE OF TRUTH FOR USER OPTIONS ---

  static const List<String> relationshipStatuses = [
    'Single',
    'In a Relationship',
    'Married',
    'Divorced',
    'Widowed',
    'Complicated',
  ];

  static const List<String> genders = [
    "Male",
    "Female",
    "Non-binary"
  ];

  static const List<String> heights = [
    'Short',
    'Average',
    'Tall',
  ];

  static const List<String> bodyTypes = [
    'Slim',
    'Athletic',
    'Average',
    'Curvy',
    'A few extra pounds',
    'Large',
  ];

  static const List<String> incomeBrackets = [
    "R150 - R350/hr",
    "R450 - R850/hr",
    "R850 - R1250/ftn",
    "R1250 - R6000/ftn",
    "More than R6000/ftn",
    "Prefer not to say",
  ];

  static const List<String> ethnicities = [
    'Asian',
    'Black',
    'Mixed',
    'Coloured',
    'Indian',
    'White',
  ];

  static const List<String> professions = [
    'Student',
    'Freelancer',
    'Professional',
  ];
}
