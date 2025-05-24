import 'package:flutter/material.dart';
import '../core/theme.dart';
Widget buildTextField(
    String label, {
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    bool isPassword = false,
  }) {
    return Focus(
      focusNode: focusNode,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: isFocused ? null : label,
          hintText: null,
          labelStyle: const TextStyle(color: Colors.brown),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(33),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(33),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(33),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 5,
            ),
          ),
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 0.8),
          contentPadding: EdgeInsets.symmetric(
            vertical: isFocused ? 15.0 : 10.0,
            horizontal: 15.0,
          ),
        ),
        style: const TextStyle(color: Colors.black),
      ),
    );
  }