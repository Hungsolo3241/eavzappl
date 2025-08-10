import 'package:flutter/material.dart';

class CustomTextFieldWidget extends StatelessWidget
{
  final TextEditingController? editingController; // Made nullable
  final IconData? iconData;
  final String? assetRef;
  final String? labelText;
  final bool? isObscure; // Made nullable


  const CustomTextFieldWidget({
    super.key,
    this.editingController,
    this.iconData,
    this.assetRef,
    this.labelText,
    this.isObscure,

  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: editingController,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: iconData != null
            ? Icon(iconData)
            : Padding(
                padding: const EdgeInsets.all(8), // Added const
          child: Image.asset(assetRef.toString()),
        ),
      labelStyle: const TextStyle(
        fontSize: 18,
      ),
        enabledBorder: const OutlineInputBorder( // Added const
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
        focusedBorder: const OutlineInputBorder( // Added const
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),

    ),
      obscureText: isObscure!, // Now correct with nullable isObscure

    );
  }
}
