import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:blur_approximations/src/blur_algorithm.dart';
import 'package:blur_approximations/src/test_case.dart';

class Gaussian2DAlgorithm extends BlurAlgorithm {
  static final double kSqrtTwoPi = sqrt(2.0 * pi);

  @override String get name => 'Gaussian';

  double gaussianCoefficient(double x, double sigma) {
    var variance = sigma * sigma;
    return exp(-0.5 * x * x / variance) / (kSqrtTwoPi * sigma);
  }

  // Returns a list of gaussian coefficients computed over the
  // range [-sampleCount + 0.5, +sampleCount - 0.5]
  Float64List getGaussians(int sampleCount, double sigma) {
    var list = Float64List(sampleCount * 2);
    for (int i = -sampleCount; i < sampleCount; i++) {
      list[i+sampleCount] = gaussianCoefficient(i + 0.5, sigma);
    }
    return list;
  }

  @override
  void computeOutput(TestCase testCase, Uint8List output) {
    int outW = testCase.sampleFieldWidth;
    int outH = testCase.sampleFieldHeight;
    int samplesX = testCase.sampleDistanceX;
    int samplesY = testCase.sampleDistanceY;
    var gaussiansX = getGaussians(samplesX, testCase.blurSigmas.width);
    var gaussiansY = getGaussians(samplesY, testCase.blurSigmas.height);
    List<Float64List> hBlurs = List<Float64List>.generate(gaussiansY.length, (i) => Float64List(outW));
    double y = (testCase.roundRect.rectSize.height - testCase.sampleFieldHeight) * 0.5 + 0.5;
    for (int j = 0; j < outH; j++, y += 1.0) {
      Float64List nextBlur = hBlurs[0];
      for (int k = 1; k < gaussiansY.length; k++) {
        hBlurs[k-1] = hBlurs[k];
      }
      double x = (testCase.roundRect.rectSize.width - testCase.sampleFieldWidth) * 0.5 + 0.5;
      for (int i = 0; i < outW; i++, x += 1.0) {
        double total = 0.0;
        for (int si = -samplesX; si < samplesX; si++) {
          if (testCase.roundRect.contains(Offset(y + samplesY, x + si))) {
            total += gaussiansX[si + samplesX];
          }
        }
        nextBlur[i] = total;
      }
      hBlurs[gaussiansY.length - 1] = nextBlur;
      for (int i = 0; i < outW; i++) {
        double total = 0.0;
        for (int sj = 0; sj < gaussiansY.length; sj++) {
          total += hBlurs[sj][i] * gaussiansY[sj];
        }
        output[j * outW + i] = (total * 255.0).round().toInt();
      }
    }
  }
}
