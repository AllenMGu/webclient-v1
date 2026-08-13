import 'package:flutter/material.dart';

/// Web Client V1 theme refreshed from the visual language used by the
/// RustDesk 1.4.x Flutter client. This file intentionally contains UI-only
/// choices; the V1 transport and session implementation remain unchanged.
class WebClientTheme {
  WebClientTheme._();

  static const accent = Color(0xFF0071FF);
  static const background = Color(0xFFF5F6F8);
  static const surface = Colors.white;
  static const text = Color(0xFF202124);
  static const muted = Color(0xFF6F737A);
  static const border = Color(0xFFE3E6EA);
  static const remoteToolbar = Color(0xFF24252B);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accent,
        surface: surface,
        background: background,
        onPrimary: Colors.white,
        onSurface: text,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: muted),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: muted),
        labelStyle: const TextStyle(color: muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          backgroundColor: surface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 600),
      ),
      textTheme: base.textTheme.copyWith(
        headline5: const TextStyle(
          color: text,
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w600,
        ),
        subtitle1: const TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyText2: const TextStyle(color: text, fontSize: 14, height: 1.35),
        caption: const TextStyle(color: muted, fontSize: 12, height: 1.35),
      ),
    );
  }
}
