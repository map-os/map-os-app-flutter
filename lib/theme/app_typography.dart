import 'package:flutter/material.dart';

abstract class AppTypography {
  static const double h1 = 22;
  static const double h2 = 20;
  static const double body = 16;
  static const double small = 14;
  static const double caption = 12;

  static TextStyle h1Style([Color? color]) => TextStyle(
        fontSize: h1,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle h2Style([Color? color]) => TextStyle(
        fontSize: h2,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyStyle([Color? color]) => TextStyle(
        fontSize: body,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyBold([Color? color]) => TextStyle(
        fontSize: body,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle smallStyle([Color? color]) => TextStyle(
        fontSize: small,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle captionStyle([Color? color]) => TextStyle(
        fontSize: caption,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextTheme textTheme = TextTheme(
    headlineLarge: h1Style(),
    headlineMedium: h2Style(),
    bodyLarge: bodyStyle(),
    bodyMedium: smallStyle(),
    bodySmall: captionStyle(),
  );
}