
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryYellow = Color(0xFFFBC02D); // yellow[700]
  static const Color backgroundDark = Colors.black87;
  static const Color textLight = Colors.white70;
  static const Color textGrey = Colors.blueGrey;
  
  static ThemeData get darkTheme => ThemeData.dark().copyWith(
    primaryColor: primaryYellow,
    scaffoldBackgroundColor: backgroundDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDark,
      titleTextStyle: TextStyle(color: primaryYellow, fontSize: 20),
    ),
    // ... define all theme elements
  );
}

class AppTextStyles {
  static const heading1 = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const heading2 = TextStyle(fontSize: 22, fontWeight: FontWeight.bold);
  static const body1 = TextStyle(fontSize: 16, fontWeight: FontWeight.normal);
  static const caption = TextStyle(fontSize: 12, color: Colors.grey);
}
