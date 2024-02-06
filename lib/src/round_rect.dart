import 'dart:ui';

import 'package:flutter/material.dart';

class RoundRect {
  RoundRect({required this.rectSize, required this.cornerRadii}) {
    assert(cornerRadii.width >= 0 && cornerRadii.width * 2 <= rectSize.width);
    assert(cornerRadii.height >= 0 && cornerRadii.height * 2 <= rectSize.height);
  }

  final Size rectSize;
  final Size cornerRadii;

  static const double kMinCornerRadius = 1e-6;

  bool contains(Offset position) {
    var halfW = rectSize.width * 0.5;
    var halfH = rectSize.height * 0.5;
    var relX = (position.dx - halfW).abs() - (halfW - cornerRadii.width);
    var relY = (position.dy - halfH).abs() - (halfH - cornerRadii.height);
    if (relX > cornerRadii.width || relY > cornerRadii.height) {
      return false;
    }
    if (relX < kMinCornerRadius || relY < kMinCornerRadius) {
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
