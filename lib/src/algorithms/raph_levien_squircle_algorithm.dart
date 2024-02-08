import 'dart:typed_data';
import 'dart:math';

import 'package:blur_approximations/src/blur_algorithm.dart';
import 'package:blur_approximations/src/test_case.dart';

class RaphLevienSquircleAlgorithm extends BlurAlgorithm {
  @override String get name => 'Raph Levien Squircle';

  static final double kTwoOverSqrtPi = 2.0 / sqrt(pi);

  static double hypotenuse(double x, double y) {
    return sqrt(x * x + y * y);
  }

  static double eccentricity(double sInverse, double d) {
    return exp(-pow(0.5 * sInverse * d, 2));
  }

  // use crate::math::compute_erf7;
  static double computeErf7(double x) {
    x *= kTwoOverSqrtPi;
    var xx = x * x;
    x = x + (0.24295 + (0.03395 + 0.0104 * xx) * xx) * (x * xx);
    return x / sqrt(1.0 + x * x);
  }

  /// Generate a blurred rounded rectangle using distance field approximation.
  /// From: https://git.sr.ht/~raph/blurrr/tree/master/src/distfield.rs
  @override
  void computeOutput(TestCase testCase, Uint8List output) {
    // To avoid divide by 0; potentially should be a bigger number for antialiasing.
    var sigma = max(testCase.blurSigmas.width, 1e-6);
    var rectW = testCase.roundRect.rect.width;
    var rectH = testCase.roundRect.rect.height;
    var radius = testCase.roundRect.cornerRadii.width;
    var fieldW = testCase.sampleFieldWidth;
    var fieldH = testCase.sampleFieldHeight;

    var minEdge = min<double>(rectW, rectH);
    var rMax = 0.5 * minEdge;
    var r0 = min(hypotenuse(radius, sigma * 1.15), rMax);
    var r1 = min(hypotenuse(radius, sigma * 2.0), rMax);

    var exponent = 2.0 * r1 / r0;

    var sInv = 1.0 / sigma;

    // Pull in long end (make less eccentric).
    var delta = 1.25 * sigma * (eccentricity(sInv, rectW) - eccentricity(sInv, rectH));
    rectW = rectW + min(delta, 0.0);
    rectH = rectH - max(delta, 0.0);

    var exponentInv = 1.0 / exponent;
    var scale = 0.5 * computeErf7(sInv * 0.5 * (max(rectW, rectH) - 0.5 * radius));
    var y = testCase.sampleStartY + 0.5 - testCase.roundRect.rect.center.dy;
    for (int j = 0; j < fieldH; j++, y += 1.0) {
      var y0 = y.abs() - (rectH * 0.5 - r1);
      var y1 = max(y0, 0.0);
      var y1exp = pow(y1, exponent);
      var x = testCase.sampleStartX + 0.5 - testCase.roundRect.rect.center.dx;
      for (int i = 0; i < fieldW; i++, x += 1.0) {
        var x0 = x.abs() - (rectW * 0.5 - r1);
        var x1 = max(x0, 0.0);
        var dPos = pow(pow(x1, exponent) + y1exp, exponentInv);
        var dNeg = min(max(x0, y0), 0.0);
        var d = dPos + dNeg - r1;
        var z = scale * (computeErf7(sInv * (minEdge + d)) - computeErf7(sInv * d));
        output[j * fieldW + i] = (z * 255.0).round().toInt();
      }
    }
  }
}
