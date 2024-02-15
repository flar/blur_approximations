import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:blur_approximations/src/blur_algorithm.dart';
import 'package:blur_approximations/src/round_rect.dart';
import 'package:blur_approximations/src/test_case.dart';
import 'package:blur_approximations/src/vec2.dart';

class Gaussian2DAlgorithm extends BlurAlgorithm {
  @override String get name => 'Gaussian';

  @override
  BlurShaderInstance getInstance(TestCase testCase) {
    return _Gaussian2DShader(testCase);
  }
}

class _Gaussian2DShader extends BlurShaderInstance {
  static final double kSqrtTwoPi = sqrt(2.0 * pi);

  static double gaussianCoefficient(double v, double sigma) {
    v /= sigma;
    return exp(-0.5 * v * v) / (kSqrtTwoPi * sigma);
  }

  // Returns a list of gaussian coefficients computed over the
  // range [-sampleCount, +sampleCount]
  static Float64List getGaussians(int sampleCount, double sigma) {
    var list = Float64List(sampleCount * 2 + 1);
    double total = 0.0;
    for (int i = -sampleCount; i <= sampleCount; i++) {
      double gauss = gaussianCoefficient(i.toDouble(), sigma);
      list[i+sampleCount] = gauss;
      total += gauss;
    }
    // for small sigmas the center weight might be > 1.0
    // for larger sigmas the total might be only about .997
    // This step normalizes both conditions
    for (int i = 0; i < list.length; i++) {
      list[i] /= total;
    }
    return list;
  }

  _Gaussian2DShader(TestCase testCase) {
    roundRect = testCase.roundRect;
    outW = testCase.sampleFieldWidth;
    sampleCountX = testCase.sampleDistanceX;
    sampleCountY = testCase.sampleDistanceY;
    gaussiansX = getGaussians(sampleCountX, testCase.blurSigmas.width);
    gaussiansY = getGaussians(sampleCountY, testCase.blurSigmas.height);
    hBlurs = List<Float64List>.generate(gaussiansY.length, (i) => Float64List(outW));
    hStartX = testCase.sampleStartX + 0.5;
  }

  late final RoundRect roundRect;
  late final int outW;
  late final int sampleCountX;
  late final int sampleCountY;
  late final Float64List gaussiansX;
  late final Float64List gaussiansY;
  late final List<Float64List> hBlurs;
  late final double hStartX;

  double hCurY = double.negativeInfinity;

  @override
  double sample(Vec2 position) {
    double y = position.y;
    if (y != hCurY) {
      assert(y == double.negativeInfinity || y == hCurY + 1.0);
      Float64List reusedBlur = hBlurs.removeAt(0);
      double sampleX = hStartX;
      double sampleY = y + sampleCountY;
      for (int i = 0; i < outW; i++, sampleX += 1.0) {
        double total = 0.0;
        for (int si = -sampleCountX; si <= sampleCountX; si++) {
          if (roundRect.contains(Offset(sampleX + si, sampleY))) {
            total += gaussiansX[si + sampleCountX];
          }
        }
        reusedBlur[i] = total;
      }
      hBlurs.add(reusedBlur);
      hCurY = y;
    }
    int si = (position.x - hStartX).round().toInt();
    double total = 0.0;
    for (int sj = 0; sj < gaussiansY.length; sj++) {
      total += hBlurs[sj][si] * gaussiansY[sj];
    }
    return total;
  }
}
