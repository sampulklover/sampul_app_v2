import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Standardized Sampul icon utility class
/// Provides consistent SVG icon paths and rendering across the app
class SampulIcons {
  // Base paths
  static const String _purplePath = 'assets/sampul-icons/sampul-icons-purple-brand500';
  static const String _grayPath = 'assets/sampul-icons/sampul-icons-gray600';

  // Navigation icons
  static const String home = '$_purplePath/home-01.svg';
  static const String learn = '$_purplePath/book-open-01.svg';
  static const String wasiat = '$_purplePath/file-01.svg';
  static const String settings = '$_purplePath/settings-01.svg';

  // Action icons
  static const String notifications = '$_purplePath/bell-01.svg';
  static const String gift = '$_purplePath/gift-01.svg';
  static const String add = '$_purplePath/plus.svg';
  static const String edit = '$_purplePath/edit-01.svg';
  static const String delete = '$_purplePath/trash-01.svg';
  static const String check = '$_purplePath/check.svg';
  static const String checkCircle = '$_purplePath/check-circle.svg';
  static const String close = '$_purplePath/x-01.svg';
  static const String arrowRight = '$_purplePath/arrow-right.svg';
  static const String arrowLeft = '$_purplePath/arrow-left.svg';
  static const String arrowDown = '$_purplePath/arrow-down.svg';
  static const String chevronDown = '$_purplePath/chevron-down.svg';
  static const String camera = '$_purplePath/camera-01.svg';
  static const String image = '$_purplePath/image-01.svg';
  static const String photo = '$_purplePath/camera-01.svg';
  static const String help = '$_purplePath/help-circle.svg';
  static const String info = '$_purplePath/info-circle.svg';

  // Feature icons
  static const String assets = '$_purplePath/wallet-01.svg';
  static const String family = '$_purplePath/users-01.svg';
  static const String checklist = '$_purplePath/clipboard-check.svg';
  static const String execution = '$_purplePath/check-done-01.svg';
  static const String aftercare = '$_purplePath/medical-cross.svg';
  static const String trust = '$_purplePath/scales-01.svg';
  static const String property = '$_purplePath/home-01.svg';
  static const String others = '$_purplePath/dots-horizontal.svg';

  // Status icons
  static const String heart = '$_purplePath/heart.svg';
  static const String favorite = '$_purplePath/heart.svg';
  static const String person = '$_purplePath/user-01.svg';
  static const String group = '$_purplePath/users-02.svg';

  // Asset category icons
  static const String apps = '$_purplePath/layout-grid-01.svg';
  static const String land = '$_purplePath/map-01.svg';
  static const String farm = '$_purplePath/feather.svg'; // Using feather as plant alternative
  static const String car = '$_purplePath/car-01.svg';
  static const String diamond = '$_purplePath/diamond-01.svg';
  static const String furniture = '$_purplePath/box.svg';
  static const String category = '$_purplePath/layout-grid-01.svg';
  static const String payment = '$_purplePath/credit-card-01.svg';
  static const String note = '$_purplePath/file-01.svg';
  static const String lightbulb = '$_purplePath/lightbulb-01.svg';
  static const String search = '$_purplePath/search-md.svg';
  static const String link = '$_purplePath/link-01.svg';
  static const String label = '$_purplePath/tag-01.svg';
  static const String assignment = '$_purplePath/file-02.svg';

  /// Builds an SVG icon widget with standardized error handling
  static Widget buildIcon(
    String assetPath, {
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
        // Fallback to a simple icon if SVG fails to load
        return Icon(
          Icons.help_outline,
          size: width ?? height ?? 24,
          color: color ?? const Color.fromRGBO(83, 61, 233, 1),
        );
      },
    );
  }

  /// Builds an icon for use in IconButton or similar widgets
  static Widget buildIconButtonIcon(
    String assetPath, {
    double size = 24,
    Color? color,
  }) {
    return buildIcon(assetPath, width: size, height: size, color: color);
  }

  /// Builds an icon for bottom navigation bar
  static Widget buildBottomNavIcon(
    String assetPath, {
    required bool isSelected,
    double size = 24,
  }) {
    final color = isSelected
        ? const Color.fromRGBO(83, 61, 233, 1)
        : Colors.grey.withOpacity(0.6);
    return buildIcon(assetPath, width: size, height: size, color: color);
  }
}
