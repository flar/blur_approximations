import 'dart:typed_data';
import 'package:meta/meta.dart';

import 'package:blur_approximations/src/blur_result.dart';
import 'package:blur_approximations/src/test_case.dart';

abstract class BlurAlgorithm {
  Future<BlurResult> compute(TestCase testCase) async {
    Uint8List output = Uint8List(testCase.sampleFieldLength);
    Stopwatch timer = Stopwatch();
    timer.start();
    computeOutput(testCase, output);
    timer.stop();
    return BlurResult(
      algorithm: this,
      testCase: testCase,
      result: output,
      computeTime: timer.elapsed,
    );
  }

  String get name;

  @protected void computeOutput(TestCase testCase, Uint8List output);
}
