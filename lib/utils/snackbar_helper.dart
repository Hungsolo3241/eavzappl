import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eavzappl/utils/app_theme.dart';

class SnackbarHelper {
  static void show({
    required String message,
    bool isError = false,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3), // Changed default duration
    Color? backgroundColor,
    SnackBarBehavior? behavior,
    ShapeBorder? shape,
    EdgeInsets? margin,
  }) {
    if (Get.context != null) {
      final snackBar = SnackBar(
        content: Text(message, style: const TextStyle(color: AppTheme.textLight)),
        backgroundColor: backgroundColor ?? (isError ? AppTheme.textGrey.withOpacity(0.8) : AppTheme.backgroundDark.withOpacity(0.8)), // Changed default non-error background
        behavior: behavior ?? SnackBarBehavior.floating,
        shape: shape ?? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: margin ?? EdgeInsets.only(
          bottom: MediaQuery.of(Get.context!).size.height - 150,
          right: 20,
          left: 20,
        ),
        action: action,
        duration: duration,
      );
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);
    }
  }
}
