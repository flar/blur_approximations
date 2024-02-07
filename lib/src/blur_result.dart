import 'dart:typed_data';
import 'dart:ui';

import 'package:blur_approximations/src/blur_algorithm.dart';
import 'package:blur_approximations/src/test_case.dart';

class BlurResult {
  BlurResult({
    required this.algorithm,
    required this.testCase,
    required this.result,
    required this.computeTime,
  }) {
    assert(result.length == testCase.sampleFieldLength);
  }

  final BlurAlgorithm algorithm;
  final TestCase testCase;
  final Uint8List result;
  final Duration computeTime;
  Image? image;
  Image? refDiffImage;
  int minDiff = 0;
  int maxDiff = 0;
  double avgDiff = 0.0;
}
