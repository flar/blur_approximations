import 'dart:ui';

import 'package:blur_approximations/src/round_rect.dart';

class TestCase {
  TestCase({
    required this.roundRect,
    required this.blurSigmas,
  });

  final RoundRect roundRect;
  final Size blurSigmas;

  int get sampleDistanceX => (blurSigmas.width * 3).ceil();
  int get sampleDistanceY => (blurSigmas.height * 3).ceil();

  int get sampleStartX => roundRect.rect.left.floor() - sampleDistanceX;
  int get sampleEndX => roundRect.rect.right.ceil() + sampleDistanceX;
  int get sampleStartY => roundRect.rect.top.floor() - sampleDistanceY;
  int get sampleEndY => roundRect.rect.bottom.ceil() + sampleDistanceY;

  int get sampleFieldWidth => sampleEndX - sampleStartY;
  int get sampleFieldHeight => sampleEndY - sampleStartY;
  int get sampleFieldLength => sampleFieldWidth * sampleFieldHeight;
}
