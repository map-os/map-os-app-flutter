import 'package:flutter/material.dart';

abstract class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;

  // Common EdgeInsets shortcuts
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingH_mdV_sm = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets paddingH_xlV_lg = EdgeInsets.symmetric(horizontal: xl, vertical: lg);
  static const EdgeInsets paddingH_md = EdgeInsets.symmetric(horizontal: md);

  // Card
  static const EdgeInsets cardMargin = EdgeInsets.all(sm);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  // Form
  static const EdgeInsets formFieldTop = EdgeInsets.only(top: sm);
}