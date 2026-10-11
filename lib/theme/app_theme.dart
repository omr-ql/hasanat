import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.ink,
    required this.muted,
    required this.blue,
    required this.line,
    required this.track,
    required this.card,
    required this.danger,
    required this.canvas,
    required this.wash,
    required this.good,
    required this.goodSoft,
    required this.dangerSoft,
    required this.blueSoft,
  });

  final Color ink;
  final Color muted;
  final Color blue;
  final Color line;
  final Color track;
  final Color card;
  final Color danger;
  final Color canvas;
  final Color wash;
  final Color good;
  final Color goodSoft;
  final Color dangerSoft;
  final Color blueSoft;

  static const light = AppPalette(
    ink: Color(0xFF222222),
    muted: Color(0xFF767676),
    blue: Color(0xFF097AFF),
    line: Color(0xFFE6E9F0),
    track: Color(0xFFEEF1F6),
    card: Color(0xFFFFFFFF),
    danger: Color(0xFFE5484D),
    canvas: Color(0xFFF5F7FB),
    wash: Color(0xFFE7F1FF),
    good: Color(0xFF1F9D55),
    goodSoft: Color(0xFFE7F8EE),
    dangerSoft: Color(0xFFFDECEC),
    blueSoft: Color(0xFFE8F3FF),
  );

  static const dark = AppPalette(
    ink: Color(0xFFF4F6FA),
    muted: Color(0xFFA3A8B3),
    blue: Color(0xFF3D92FF),
    line: Color(0xFF2C3340),
    track: Color(0xFF2A3140),
    card: Color(0xFF1C212B),
    danger: Color(0xFFFF6B6B),
    canvas: Color(0xFF10141C),
    wash: Color(0xFF10141C),
    good: Color(0xFF3DDC8A),
    goodSoft: Color(0xFF143226),
    dangerSoft: Color(0xFF3A1C1C),
    blueSoft: Color(0xFF162033),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>()!;
  }

  @override
  AppPalette copyWith({
    Color? ink,
    Color? muted,
    Color? blue,
    Color? line,
    Color? track,
    Color? card,
    Color? danger,
    Color? canvas,
    Color? wash,
    Color? good,
    Color? goodSoft,
    Color? dangerSoft,
    Color? blueSoft,
  }) {
    return AppPalette(
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      blue: blue ?? this.blue,
      line: line ?? this.line,
      track: track ?? this.track,
      card: card ?? this.card,
      danger: danger ?? this.danger,
      canvas: canvas ?? this.canvas,
      wash: wash ?? this.wash,
      good: good ?? this.good,
      goodSoft: goodSoft ?? this.goodSoft,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      blueSoft: blueSoft ?? this.blueSoft,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      line: Color.lerp(line, other.line, t)!,
      track: Color.lerp(track, other.track, t)!,
      card: Color.lerp(card, other.card, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      wash: Color.lerp(wash, other.wash, t)!,
      good: Color.lerp(good, other.good, t)!,
      goodSoft: Color.lerp(goodSoft, other.goodSoft, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      blueSoft: Color.lerp(blueSoft, other.blueSoft, t)!,
    );
  }
}

List<BoxShadow> cardShadow(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return const [];
  }
  return const [
    BoxShadow(color: Color(0x14222222), blurRadius: 24, offset: Offset(0, 10)),
  ];
}

TextStyle arabicStyle(
  AppPalette palette, {
  double size = 16,
  FontWeight weight = FontWeight.w700,
  double height = 1.25,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'Cairo',
    fontWeight: weight,
    fontSize: size,
    height: height,
    color: color ?? palette.ink,
  );
}

TextStyle figureStyle(AppPalette palette, {double size = 32, Color? color}) {
  return TextStyle(
    fontFamily: 'Jakarta',
    fontFamilyFallback: const ['Cairo'],
    fontWeight: FontWeight.w700,
    fontSize: size,
    height: 1,
    letterSpacing: -0.6,
    color: color ?? palette.ink,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

ThemeData buildHasanatTheme(Brightness brightness) {
  final palette = brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
  final blue = palette.blue;

  final scheme = ColorScheme.fromSeed(seedColor: blue, brightness: brightness)
      .copyWith(
        primary: blue,
        onPrimary: Colors.white,
        secondary: blue,
        onSecondary: Colors.white,
        surface: palette.card,
        onSurface: palette.ink,
        primaryContainer: palette.blueSoft,
        onPrimaryContainer: blue,
        secondaryContainer: blue,
        onSecondaryContainer: Colors.white,
        outline: palette.line,
        error: palette.danger,
        onError: Colors.white,
      );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.wash,
    fontFamily: 'Cairo',
    splashFactory: InkRipple.splashFactory,
    extensions: [palette],
  );

  final applied = base.textTheme.apply(
    fontFamily: 'Cairo',
    bodyColor: palette.ink,
    displayColor: palette.ink,
  );
  final textTheme = applied.copyWith(
    bodyLarge: applied.bodyLarge?.copyWith(height: 1.4),
    bodyMedium: applied.bodyMedium?.copyWith(height: 1.4, color: palette.muted),
    titleLarge: applied.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: 22,
      height: 1.25,
    ),
    titleMedium: applied.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );

  const buttonText = TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 1.1,
  );

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleMedium,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 56),
        elevation: 0,
        shape: const StadiumBorder(),
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.ink,
        backgroundColor: palette.card,
        side: BorderSide(color: palette.line),
        minimumSize: const Size(64, 56),
        shape: const StadiumBorder(),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: blue, textStyle: buttonText),
    ),
    chipTheme: base.chipTheme.copyWith(
      showCheckmark: false,
      backgroundColor: palette.canvas,
      selectedColor: blue,
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      side: BorderSide(color: palette.line),
      shape: const StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.canvas,
      labelStyle: TextStyle(fontFamily: 'Cairo', color: palette.muted),
      hintStyle: TextStyle(fontFamily: 'Cairo', color: palette.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: blue, width: 1.6),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.card,
      showDragHandle: true,
      dragHandleColor: palette.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
