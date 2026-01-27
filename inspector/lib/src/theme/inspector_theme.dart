import 'package:flutter/material.dart';

/// Theme constants for the ECS Inspector.
class InspectorTheme {
  InspectorTheme._();

  // Node colors
  static const Color componentColor = Color(0xFF4CAF50);
  static const Color eventColor = Color(0xFFFF9800);
  static const Color systemColor = Color(0xFF2196F3);
  static const Color lifecycleColor = Color(0xFF9C27B0);
  static const Color selectedColor = Color(0xFFFFEB3B);

  // Edge colors
  static const Color reactsToColor = Color(0xFF4CAF50);
  static const Color interactsWithColor = Color(0xFF2196F3);
  static const Color highlightedEdgeColor = Color(0xFFFFEB3B);
  static const Color defaultEdgeColor = Color(0xFF757575);

  // Log level colors
  static const Color verboseColor = Color(0xFF9E9E9E);
  static const Color debugColor = Color(0xFF2196F3);
  static const Color infoColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color fatalColor = Color(0xFF9C27B0);

  // Status colors
  static const Color connectedColor = Color(0xFF4CAF50);
  static const Color connectingColor = Color(0xFFFF9800);
  static const Color disconnectedColor = Color(0xFF9E9E9E);
  static const Color errorStatusColor = Color(0xFFF44336);

  // Background colors
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color surfaceBackground = Color(0xFF121212);
  static const Color elevatedBackground = Color(0xFF2D2D2D);

  // Text colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB0B0B0);
  static const Color mutedText = Color(0xFF757575);

  /// Get color for a log level.
  static Color getLogLevelColor(String level) {
    return switch (level.toLowerCase()) {
      'verbose' => verboseColor,
      'debug' => debugColor,
      'info' => infoColor,
      'warning' => warningColor,
      'error' => errorColor,
      'fatal' => fatalColor,
      _ => secondaryText,
    };
  }

  /// Get dark theme data for the inspector.
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: surfaceBackground,
      cardColor: cardBackground,
      colorScheme: const ColorScheme.dark(
        primary: systemColor,
        secondary: componentColor,
        surface: cardBackground,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBackground,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevatedBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: elevatedBackground,
        selectedColor: systemColor.withValues(alpha: 0.3),
        labelStyle: const TextStyle(color: primaryText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: elevatedBackground,
        thickness: 1,
      ),
    );
  }
}
