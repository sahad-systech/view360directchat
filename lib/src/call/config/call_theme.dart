import 'package:flutter/material.dart';

/// Styling and theme configuration for View360 Call UI screens and components.
class View360CallTheme {
  /// Primary theme color used for accents, buttons, and call badges.
  final Color primaryColor;

  /// Background color used in light mode.
  final Color lightBackground;

  /// Background color used in dark mode.
  final Color darkBackground;

  /// Creates a [View360CallTheme] with custom or default colors.
  const View360CallTheme({
    this.primaryColor = const Color(0xFF5D59E1),
    this.lightBackground = Colors.white,
    this.darkBackground = const Color(0xFF263238), // blueGrey.shade900
  });
}

