import 'package:flutter/material.dart';

/// Global helper for creating consistent rounded form field decorations
/// 
/// This helper provides a centralized way to style all form fields across the app
/// with rounded borders. Change the border radius in one place to update all forms.
class FormDecorationHelper {
  // Centralized border radius for all form fields
  // Change this value to update all form fields across the app
  static const double formBorderRadius = 12.0;

  // Default border color
  static const Color defaultBorderColor = Color(0xFFD5D7DA);

  // Default border width
  static const double defaultBorderWidth = 1.0;

  /// Creates an InputDecoration with rounded borders that follows the app's theme
  /// 
  /// Parameters:
  /// - [context]: BuildContext to access theme
  /// - [labelText]: Required label text for the field
  /// - [hintText]: Optional hint text
  /// - [prefixIcon]: Optional icon to show before the input
  /// - [helperText]: Optional helper text below the field
  /// 
  /// Returns an InputDecoration with:
  /// - Rounded borders (using formBorderRadius)
  /// - Primary color on focus
  /// - Red borders on error states
  static InputDecoration roundedInputDecoration({
    required BuildContext context,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    String? helperText,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final OutlineInputBorder roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(formBorderRadius),
      borderSide: BorderSide(
        color: defaultBorderColor,
        width: defaultBorderWidth,
      ),
    );
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: roundedBorder,
      enabledBorder: roundedBorder,
      focusedBorder: roundedBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.primary, width: defaultBorderWidth),
      ),
      errorBorder: roundedBorder.copyWith(
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: roundedBorder.copyWith(
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
