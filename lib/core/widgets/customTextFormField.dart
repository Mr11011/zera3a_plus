import 'package:flutter/material.dart';
import 'package:zera3a/core/utils/colors.dart';

class CustomTextFormField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final Color? focusedCustomColor;
  final Color? borderColor;

  const CustomTextFormField(
      {super.key,
      this.labelText,
      this.hintText,
      this.controller,
      this.keyboardType = TextInputType.text,
      this.obscureText = false,
      this.validator,
      this.prefixIcon,
      this.suffixIcon,
      this.onSuffixIconPressed,
      this.focusedCustomColor,
      this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: labelText,
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide:
                  BorderSide(color: focusedCustomColor ?? AppColor.medBrown)),
          hintText: hintText,
          hintTextDirection: TextDirection.rtl,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: suffixIcon != null
              ? IconButton(
                  onPressed: onSuffixIconPressed,
                  icon: Icon(suffixIcon),
                )
              : null,
        ),
      ),
    );
  }
}
