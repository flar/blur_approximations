import 'dart:math';

import 'package:blur_approximations/src/blur_algorithm.dart';
import 'package:blur_approximations/src/test_case.dart';
import 'package:blur_approximations/src/vec2.dart';

class EvanWallaceHalfClosedFormAlgorithm extends BlurAlgorithm {
  @override String get name => 'Evan Wallace';

  @override
  BlurShaderInstance getInstance(TestCase testCase) {
    return _EvanWallaceHalfClosedFormShader(testCase);
  }
}

class _EvanWallaceHalfClosedFormShader extends BlurShaderInstance {
  static final double kSqrtTwoPi = sqrt(2.0 * pi);
  static final double kSqrtHalf = sqrt(0.5);

  // A standard gaussian function, used for weighting samples
  static double gaussian(double x, double sigma) {
    x /= sigma;
    return exp(x * x * -0.5) / (kSqrtTwoPi * sigma);
  }

  _EvanWallaceHalfClosedFormShader(TestCase testCase) {
    halfSize = Vec2.size(testCase.roundRect.halfSize);
    sigma = testCase.blurSigmas.width;
    corner = testCase.roundRect.cornerRadii.width;
    center = Vec2.offset(testCase.roundRect.rect.center);
  }

  late final double corner;
  late final double sigma;
  late final Vec2 halfSize;
  late final Vec2 center;

  // This approximates the error function, needed for the gaussian integral
  static Vec2 erf(Vec2 x) {
    Vec2 s = x.sign;
    Vec2 a = x.abs;
    // x = 1.0 + (0.278393 + (0.230389 + 0.078108 * (a * a)) * a) * a;
    x = ((a.mul(a) * 0.078108 + 0.230389).mul(a) + 0.278393).mul(a) + 1.0;
    x = x.mul(x);
    return s.sub(s.div(x.mul(x)));
  }

  // Return the blurred mask along the x dimension
  static double roundedBoxShadowX(double x, double y, double sigma, double corner, Vec2 halfSize) {
    double delta = min(halfSize.y - corner - y.abs(), 0.0);
    double curved = halfSize.x - corner + sqrt(max(0.0, corner * corner - delta * delta));
    Vec2 integral = erf((Vec2(-curved, curved) + x) * (kSqrtHalf / sigma)) * 0.5 + 0.5;
    return integral.y - integral.x;
  }

  // Return the mask for the shadow of a box from lower to upper
  static double roundedBoxShadow(
      Vec2 point,
      Vec2 halfSize,
      double sigma,
      double corner) {
    // Center everything to make the math easier
    // These transformations are now done by the calling method
    // Vec2 center = (lower.add(upper)) * 0.5;
    // Vec2 halfSize = (upper.sub(lower)) * 0.5;
    // point = point.sub(center);

    // The signal is only non-zero in a limited range, so don't waste samples
    double start = (point.y - 3.0 * sigma).clamp(-halfSize.y, halfSize.y);
    double end = (point.y + 3.0 * sigma).clamp(-halfSize.y, halfSize.y);

    // Accumulate samples (we can get away with surprisingly few samples)
    const int steps = 4;
    double stepSize = (end - start) / steps;
    double sampleY = start + stepSize * 0.5;
    double value = 0.0;
    for (int i = 0; i < steps; i++) {
      value += (roundedBoxShadowX(point.x, sampleY, sigma, corner, halfSize) *
          gaussian(point.y - sampleY, sigma) * stepSize);
      sampleY += stepSize;
    }

    return value;
  }

  @override
  double sample(Vec2 position) {
    return roundedBoxShadow(position.sub(center), halfSize, sigma, corner);
  }
}
