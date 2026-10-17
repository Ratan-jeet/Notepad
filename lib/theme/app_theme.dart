import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const List<int> accentChoices = [
    0xFF6750A4, // purple
    0xFF3867D6, // blue
    0xFF00695C, // teal
    0xFF2E7D32, // green
    0xFFEF6C00, // orange
    0xFFD32F2F, // red
    0xFFC2185B, // pink
    0xFF5D4037, // brown
  ];

  static const List<Color> _tagPalette = [
    Color(0xFF3F51B5),
    Color(0xFF00897B),
    Color(0xFFEF6C00),
    Color(0xFFC2185B),
    Color(0xFF7B1FA2),
    Color(0xFF455A64),
    Color(0xFF388E3C),
    Color(0xFFD32F2F),
  ];

  static Color tagColor(String tag) {
    var hash = 0;
    for (final code in tag.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return _tagPalette[hash % _tagPalette.length];
  }

  static ThemeData light(Color accent) =>
      _build(Brightness.light, ColorScheme.fromSeed(seedColor: accent));

  static ThemeData dark(Color accent) => _build(
        Brightness.dark,
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ),
      );

  static ThemeData _build(Brightness brightness, ColorScheme scheme) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF131314) : const Color(0xFFF8F7FB),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF131314) : const Color(0xFFF8F7FB),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1C1B1F),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF1E1E20) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF232326) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : Colors.black12,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : null,
        ),
      ),
    );
  }
}
