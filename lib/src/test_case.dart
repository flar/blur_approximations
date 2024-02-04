import 'dart:ui';

import 'package:blur_approximations/src/round_rect.dart';

class TestCase {
  TestCase({
    required this.roundRect,
    required this.blurSigmas,
  });

  final RoundRect roundRect;
  final Size blurSigmas;

  int get sampleFieldWidth => (roundRect.rectSize.width + blurSigmas.width * 6).ceil();
  int get sampleFieldHeight => (roundRect.rectSize.height + blurSigmas.height * 6).ceil();
  int get sampleFieldLength => sampleFieldWidth * sampleFieldHeight;

  int get sampleDistanceX => (blurSigmas.width * 3).ceil();
  int get sampleDistanceY => (blurSigmas.height * 3).ceil();
}