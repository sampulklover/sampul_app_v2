import 'package:flutter/material.dart';

/// Global helper for creating consistent card decorations
/// 
/// This helper provides a centralized way to style all cards across the app
/// with consistent borders, padding, and elevation. Change the values in one
/// place to update all cards.
class CardDecorationHelper {
  // Centralized border radius for all cards
  // Change this value to update all cards across the app
  static const double cardBorderRadius = 16.0;

  // Default padding for card content
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);

  // Default elevation for cards
  static const double defaultElevation = 0.5;

  // Default border color
  static const Color defaultBorderColor = Color(0xFFE9EAEB);

  // Default border width (stroke width)
  static const double defaultBorderWidth = 1.0;

  // Default spacing between title and content
  static const double defaultTitleSpacing = 16.0;

  /// Creates a Card widget with consistent styling that follows the app's theme
  /// 
  /// Parameters:
  /// - [context]: BuildContext to access theme
  /// - [child]: Required widget to display inside the card
  /// - [padding]: Optional padding (defaults to defaultPadding)
  /// - [elevation]: Optional elevation (defaults to defaultElevation)
  /// - [margin]: Optional margin around the card
  /// 
  /// Returns a Card with:
  /// - Rounded borders (using cardBorderRadius)
  /// - Consistent padding
  /// - Theme-aware styling
  static Card styledCard({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? elevation,
    EdgeInsetsGeometry? margin,
  }) {
    return Card(
      elevation: elevation ?? defaultElevation,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
        side: BorderSide(
          color: defaultBorderColor,
          width: defaultBorderWidth,
        ),
      ),
      child: Padding(
        padding: padding ?? defaultPadding,
        child: child,
      ),
    );
  }

  /// Creates a card section with a title and content
  /// 
  /// Parameters:
  /// - [context]: BuildContext to access theme
  /// - [title]: Required title text for the section
  /// - [content]: Required widget to display as content
  /// - [titleStyle]: Optional custom style for the title
  /// - [titleSpacing]: Optional spacing between title and content
  /// - [padding]: Optional padding (defaults to defaultPadding)
  /// - [elevation]: Optional elevation (defaults to defaultElevation)
  /// - [margin]: Optional margin around the card
  /// 
  /// Returns a Card with:
  /// - Title section with consistent styling
  /// - Content section below the title
  /// - Consistent spacing and padding
  static Card styledCardWithTitle({
    required BuildContext context,
    required String title,
    required Widget content,
    TextStyle? titleStyle,
    double? titleSpacing,
    EdgeInsetsGeometry? padding,
    double? elevation,
    EdgeInsetsGeometry? margin,
  }) {
    final theme = Theme.of(context);
    return styledCard(
      context: context,
      padding: padding,
      elevation: elevation,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: titleStyle ?? theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: titleSpacing ?? defaultTitleSpacing),
          content,
        ],
      ),
    );
  }
}
