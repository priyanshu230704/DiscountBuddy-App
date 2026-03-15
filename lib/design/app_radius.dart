import 'package:flutter/material.dart';

/// Global radius tokens to keep corners consistent.
class AppRadius {
  static const BorderRadius small = BorderRadius.all(Radius.circular(8));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(12));
  static const BorderRadius large = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xLarge = BorderRadius.all(Radius.circular(24));

  static const BorderRadius card = xLarge;
  static const BorderRadius button = large;
  static const BorderRadius chip = BorderRadius.all(Radius.circular(18));
  static const BorderRadius bottomSheetTop = BorderRadius.vertical(
    top: Radius.circular(32),
  );
}

