import 'dart:typed_data';
import 'package:meta/meta.dart';

import 'package:blur_approximations/src/blur_result.dart';
import 'package:blur_approximations/src/test_case.dart';

abstract class BlurAlgorithm {
  Future<BlurResult> compute(TestCase testCase) async {
    Uint8List output = Uint8List(testCase.sampleFieldLength);
    computeOutput(testCase, output);
    return BlurResult(testCase: testCase, result: output);
  }

  @protected void computeOutput(TestCase testCase, Uint8List output);
}
