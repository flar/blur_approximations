import 'dart:typed_data';

import 'package:blur_approximations/src/test_case.dart';

class BlurResult {
  BlurResult({required this.testCase, required this.result, required this.computeTime}) {
    assert(result.length == testCase.sampleFieldLength);
  }

  final TestCase testCase;
  final Uint8List result;
  final Duration computeTime;
}