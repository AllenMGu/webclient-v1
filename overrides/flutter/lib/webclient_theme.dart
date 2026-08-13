import 'package:flutter/material.dart';

/// Web Client V1 theme refreshed from the visual language used by the
/// RustDesk 1.4.x Flutter client. This file intentionally contains UI-only
/// choices; the V1 transport and session implementation remain unchanged.
class WebClientTheme {
  WebClientTheme._();

  static const accent = Color(0xFF0071FF);
  static Color background = const Color(0xFFF5F6F8);
  static Color surface = Colors.white;
  static Color text = const Color(0xFF202124);
  static Color muted = const Color(0xFF6F737A);
  static Color border = const Color(0xFFE3E6EA);
  static const remoteToolbar = Color(0xFF24252B);

  static void configure(Brightness brightness) {
    if (brightness == Brightness.dark) {
      background = const Color(0xFF16181C);
      surface = const Color(0xFF202329);
      text = const Color(0xFFF2F3F5);
      muted = const Color(0xFFA6ABB4);
      border = const Color(0xFF343840);
    } else {
      background = const Color(0xFFF5F6F8);
      surface = Colors.white;
      text = const Color(0xFF202124);
      muted = const Color(0xFF6F737A);
      border = const Color(0xFFE3E6EA);
    }
  }

  static ThemeData get current {
    final brightness = background.computeLuminance() < 0.2
        ? Brightness.dark
        : Brightness.light;
    final base = ThemeData(
      useMaterial3: false,
      brightness: brightness,
      primaryColor: accent,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              primary: accent,
              secondary: accent,
              surface: surface,
              background: background,
              onPrimary: Colors.white,
              onSurface: text,
            )
          : ColorScheme.light(
              primary: accent,
              secondary: accent,
              surface: surface,
              background: background,
              onPrimary: Colors.white,
              onSurface: text,
            ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
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
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
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
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 600),
      ),
      textTheme: base.textTheme.copyWith(
        headline5: TextStyle(
          color: text,
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w600,
        ),
        subtitle1: TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyText2: TextStyle(color: text, fontSize: 14, height: 1.35),
        caption: TextStyle(color: muted, fontSize: 12, height: 1.35),
      ),
    );
  }
}
