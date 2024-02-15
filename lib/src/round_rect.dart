import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class RoundRect {
  RoundRect({required this.rect, required Size cornerRadii}) {
    halfSize = rect.size * 0.5;
    double cornerWidth = max(min(cornerRadii.width, halfSize.width), 0.0);
    double cornerHeight = max(min(cornerRadii.height, halfSize.height), 0.0);
    this.cornerRadii = Size(cornerWidth, cornerHeight);
    flatSize = Size(
      halfSize.width - cornerRadii.width,
      halfSize.height - cornerRadii.height,
    );
  }

  final Rect rect;
  late final Size cornerRadii;
  late final Size halfSize;
  late final Size flatSize;

  static const double kMinCornerRadius = 1e-6;

  bool contains(Offset position) {
    var relX = (position.dx - rect.left - halfSize.width).abs();
    var relY = (position.dy - rect.top - halfSize.height).abs();
    if (relX > halfSize.width || relY > halfSize.height) {
      return false;
    }
    if ((relX -= flatSize.width) < kMinCornerRadius ||
        (relY -= flatSize.height) < kMinCornerRadius) {
      return true;
    }
    if (cornerRadii.width < kMinCornerRadius ||
        cornerRadii.height < kMinCornerRadius) {
      return false;
    }
    relX /= cornerRadii.width;
    relY /= cornerRadii.height;
    return (relX * relX + relY * relY) <= 1.0;
  }
}
