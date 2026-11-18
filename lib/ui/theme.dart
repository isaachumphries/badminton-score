import 'package:flutter/material.dart';

import '../engine/types.dart';

// Warm neutral ramp. Team colours only mark players, never whole surfaces.
const paper = Color(0xFFF7F4EE); // page
const card = Color(0xFFFDFBF7); // raised card
const raised = Color(0xFFEFE9DF); // inset controls
const ink = Color(0xFF1F1B16); // primary text, primary buttons
const secondary = Color(0xFF5E554A);
const muted = Color(0xFF7B7266);
const hairline = Color(0x141F1B16); // ink at 8%

const teamAColor = Color(0xFF1E6E5A);
const teamBColor = Color(0xFFD2622B);
const teamBText = Color(0xFFB04E1C); // orange dark enough for small text
const courtFill = Color(0xFF34555E);

Color teamColor(Side s) => s == Side.a ? teamAColor : teamBColor;
Color teamTextColor(Side s) => s == Side.a ? teamAColor : teamBText;

const tabular = [FontFeature.tabularFigures()];

/// Fonts are variable, so the weight axis is set explicitly as well.
TextStyle _style(String family, double size, FontWeight w, Color color,
        double? lineHeight, double? spacing) =>
    TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: w,
      fontVariations: [FontVariation.weight(w.value.toDouble())],
      color: color,
      height: lineHeight == null ? null : lineHeight / size,
      letterSpacing: spacing,
    );

TextStyle sans(double size,
        {FontWeight weight = FontWeight.w400,
        Color color = ink,
        double? lineHeight}) =>
    _style('InstrumentSans', size, weight, color, lineHeight, null);

TextStyle mono(double size,
        {FontWeight weight = FontWeight.w400, Color color = muted}) =>
    _style('GeistMono', size, weight, color, null, null)
        .copyWith(fontFeatures: tabular);

/// Scoreboard figures.
TextStyle figures(double size, {Color color = ink}) =>
    _style('Geist', size, FontWeight.w500, color, size, -0.03 * size)
        .copyWith(fontFeatures: tabular);

ThemeData appTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'InstrumentSans',
    scaffoldBackgroundColor: paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ink,
      primary: ink,
      onPrimary: card,
      surface: paper,
      brightness: Brightness.light,
    ),
    splashFactory: InkRipple.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: sans(18, weight: FontWeight.w500),
      contentTextStyle: sans(15, color: secondary, lineHeight: 22),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        textStyle: sans(15, weight: FontWeight.w500),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: ink),
  );
}
