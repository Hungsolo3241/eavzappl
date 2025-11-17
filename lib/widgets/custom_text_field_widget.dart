import 'package:flutter/material.dart';
import 'package:eavzappl/utils/app_theme.dart';

/// A custom text field widget with consistent styling.
class CustomTextFieldWidget extends StatelessWidget {
  final TextEditingController? editingController;
  final IconData? iconData;
  final String? assetRef;
  final String? labelText;
  final bool isObscure;
  final TextStyle? textStyle;
  final TextInputType? keyboardType;

  /// Creates a customizable text field.
  ///
  /// Requires one of [iconData] or [assetRef] for the prefix icon.
  const CustomTextFieldWidget({
    super.key,
    this.editingController,
    this.iconData,
    this.assetRef,
    this.labelText,
    this.isObscure = false, // Default to false directly in the constructor
    this.textStyle,
    this.keyboardType,
  }) : assert(iconData != null || assetRef != null, 'Either iconData or assetRef must be provided.');

  @override
  Widget build(BuildContext context) {
    // Define the border style once and reuse it.
    const OutlineInputBorder borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(22.0)),
      borderSide: BorderSide(
        color: AppTheme.textGrey,
        width: 1,
      ),
    );

    return TextField(
      controller: editingController,
      style: textStyle,
      keyboardType: keyboardType,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: labelText,
        // Use a more readable conditional for the prefix icon.
        prefixIcon: iconData != null
            ? Icon(iconData, color: AppTheme.textGrey)
            : Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(assetRef!), // Now safe due to the assert
              ),
        labelStyle: const TextStyle(
          fontSize: 16,
          color: AppTheme.textGrey,
        ),
        enabledBorder: borderStyle,
        focusedBorder: borderStyle,
      ),
    );
  }
}
