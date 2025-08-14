import 'package:flutter/material.dart';

class CustomTextFieldWidget extends StatelessWidget {
  final TextEditingController? editingController;
  final IconData? iconData;
  final String? assetRef;
  final String? labelText;
  final bool? isObscure;
  final TextStyle? textStyle;
  final TextInputType? keyboardType; // Added keyboardType field

  const CustomTextFieldWidget({
    super.key,
    this.editingController,
    this.iconData,
    this.assetRef,
    this.labelText,
    this.isObscure,
    this.textStyle,
    this.keyboardType, // Added keyboardType to constructor
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: editingController,
      style: textStyle,
      keyboardType: keyboardType, // Applied keyboardType to the TextField
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: iconData != null
            ? Icon(iconData)
            : Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(assetRef.toString()),
              ),
        labelStyle: const TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(22.0)),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(22.0)),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
      ),
      obscureText: isObscure ?? false, // Use ?? false for a default value
    );
  }
}
