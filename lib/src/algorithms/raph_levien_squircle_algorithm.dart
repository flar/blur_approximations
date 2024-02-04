import 'dart:typed_data';
import 'dart:math';

import 'package:blur_approximations/src/blur_algorithm.dart';
import 'package:blur_approximations/src/test_case.dart';

class RaphLevienSquircleAlgorithm extends BlurAlgorithm {
  static double hypotenuse(double x, double y) {
    return sqrt(x * x + y * y);
  }

  static double eccentricity(double sInverse, double d) {
    return exp(-pow(0.5 * sInverse * d, 2));
  }

  // use crate::math::compute_erf7;
  static double computeErf7(double x) {
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
    var rectW = testCase.roundRect.rectSize.width;
    var rectH = testCase.roundRect.rectSize.height;
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
    for (int j = 0; j < fieldH; j++) {
      var y = j.toDouble() + 0.5 - 0.5 * fieldH.toDouble();
      var y0 = y.abs() - (rectH * 0.5 - r1);
      var y1 = max(y0, 0.0);
      for (int i = 0; i < fieldW; i++) {
        var x = i.toDouble() + 0.5 - 0.5 * fieldW.toDouble();
        var x0 = x.abs() - (rectW * 0.5 - r1);
        var x1 = max(x0, 0.0);
        var dPos = pow(pow(x1, exponent) + pow(y1, exponent), exponentInv);
        var dNeg = min(max(x0, y0), 0.0);
        var d = dPos + dNeg - r1;
        var z = scale * (computeErf7(sInv * (minEdge + d)) - computeErf7(sInv * d));
        output[j * fieldW + i] = (z * 255.0).round().toInt();
      }
    }
  }
}