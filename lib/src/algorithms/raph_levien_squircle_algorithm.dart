import 'dart:math';

import 'package:blur_approximations/src/blur_algorithm.dart';
import 'package:blur_approximations/src/test_case.dart';
import 'package:blur_approximations/src/vec2.dart';

class RaphLevienSquircleAlgorithm extends BlurAlgorithm {
  @override String get name => 'Raph Levien Squircle';

  @override
  BlurShaderInstance getInstance(TestCase testCase) {
    return _RaphLevienSquircleShader(testCase);
  }
}

class _RaphLevienSquircleShader extends BlurShaderInstance {
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

  _RaphLevienSquircleShader(TestCase testCase) {
    var sigma = max(testCase.blurSigmas.width * sqrt(2), 1e-6);
    double rectW = testCase.roundRect.rect.width;
    double rectH = testCase.roundRect.rect.height;
    var radius = testCase.roundRect.cornerRadii.width;
    center = Vec2.offset(testCase.roundRect.rect.center);

    minEdge = min<double>(rectW, rectH);
    var rMax = 0.5 * minEdge;
    var r0 = min(hypotenuse(radius, sigma * 1.15), rMax);
    r1 = min(hypotenuse(radius, sigma * 2.0), rMax);

    exponent = 2.0 * r1 / r0;

    sInv = 1.0 / sigma;

    // Pull in long end (make less eccentric).
    var delta = 1.25 * sigma * (eccentricity(sInv, rectW) - eccentricity(sInv, rectH));
    rectW = rectW + min(delta, 0.0);
    rectH = rectH - max(delta, 0.0);

    this.rectW = rectW;
    this.rectH = rectH;
    exponentInv = 1.0 / exponent;
    scale = 0.5 * computeErf7(sInv * 0.5 * (max(rectW, rectH) - 0.5 * radius));
  }

  late final double rectW;
  late final double rectH;
  late final Vec2 center;
  late final double minEdge;
  late final double r1;
  late final double exponent;
  late final double sInv;
  late final double exponentInv;
  late final double scale;

  @override
  double sample(Vec2 position) {
    var x = position.x - center.x;
    var y = position.y - center.y;

    var y0 = y.abs() - (rectH * 0.5 - r1);
    var y1 = max(y0, 0.0);
    var y1exp = pow(y1, exponent);
    var x0 = x.abs() - (rectW * 0.5 - r1);
    var x1 = max(x0, 0.0);
    var dPos = pow(pow(x1, exponent) + y1exp, exponentInv);
    var dNeg = min(max(x0, y0), 0.0);
    var d = dPos + dNeg - r1;
    var z = scale * (computeErf7(sInv * (minEdge + d)) - computeErf7(sInv * d));
    return z;
  }
}
