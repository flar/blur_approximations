import 'dart:typed_data';

import 'package:blur_approximations/src/test_case.dart';

class BlurResult {
  BlurResult({required this.testCase, required this.result}) {
    assert(result.length == testCase.sampleFieldLength);
  }

  TestCase testCase;
  Uint8List result;
}