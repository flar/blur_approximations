import 'dart:typed_data';
import 'package:blur_approximations/src/vec2.dart';
import 'package:meta/meta.dart';

import 'package:blur_approximations/src/blur_result.dart';
import 'package:blur_approximations/src/test_case.dart';

abstract class BlurAlgorithm {
  Future<BlurResult> compute(TestCase testCase) async {
    Uint8List output = Uint8List(testCase.sampleFieldLength);
    int w = testCase.sampleFieldWidth;
    int h = testCase.sampleFieldHeight;
    BlurShaderInstance instance = getInstance(testCase);
    Stopwatch timer = Stopwatch();
    timer.start();
    double y = testCase.sampleStartY + 0.5;
    for (int j = 0; j < h; j++, y += 1.0) {
      double x = testCase.sampleStartX + 0.5;
      for (int i = 0; i < w; i++, x += 1.0) {
        double sample = instance.sample(Vec2(x, y));
        output[j * w + i] = (sample * 255.0).round().toInt();
      }
    }
    timer.stop();
    return BlurResult(
      algorithm: this,
      testCase: testCase,
      result: output,
      computeTime: timer.elapsed,
    );
  }

  String get name;

  @protected BlurShaderInstance getInstance(TestCase testCase);
}

abstract class BlurShaderInstance {
  double sample(Vec2 position);
}
