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
  // range [-sampleCount, +sampleCount]
  Float64List getGaussians(int sampleCount, double sigma) {
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
      Float64List newBlur = hBlurs.removeAt(0);
      double x = (testCase.roundRect.rectSize.width - testCase.sampleFieldWidth) * 0.5 + 0.5;
      for (int i = 0; i < outW; i++, x += 1.0) {
        double total = 0.0;
        for (int si = -samplesX; si <= samplesX; si++) {
          if (testCase.roundRect.contains(Offset(y + samplesY, x + si))) {
            total += gaussiansX[si + samplesX];
          }
        }
        newBlur[i] = total;
      }
      hBlurs.add(newBlur);
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
