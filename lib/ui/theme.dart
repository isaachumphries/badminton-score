import 'package:flutter/material.dart';

import '../engine/types.dart';

const paper = Color(0xFFF6F4EE);
const ink = Color(0xFF1B1F1D);
const muted = Color(0xFF6B726E);
const teamAColor = Color(0xFF1F6F5C);
const teamBColor = Color(0xFFD2612A);
const courtFill = Color(0xFFE3EAE4);
const courtLine = Color(0xFF8FA398);

Color teamColor(Side s) => s == Side.a ? teamAColor : teamBColor;

const tabular = [FontFeature.tabularFigures()];

ThemeData appTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teamAColor,
        surface: paper,
        brightness: Brightness.light,
      ),
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: ink,
            displayColor: ink,
          ),
    );
