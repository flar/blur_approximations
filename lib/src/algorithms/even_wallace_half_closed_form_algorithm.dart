import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:blur_approximations/src/blur_algorithm.dart';
import 'package:blur_approximations/src/test_case.dart';

class Vec2 {
  Vec2(this.x, this.y);
  Vec2.size(Size size) : x = size.width, y = size.height;

  final double x;
  final double y;

  // sadly, no multi-type operator overloads in Dart
  Vec2 add(Vec2 o) => Vec2(x + o.x, y + o.y);
  Vec2 sub(Vec2 o) => Vec2(x - o.x, y - o.y);
  Vec2 mul(Vec2 o) => Vec2(x * o.x, y * o.y);
  Vec2 div(Vec2 o) => Vec2(x / o.x, y / o.y);

  Vec2 operator+(double v) => Vec2(x + v, y + v);
  Vec2 operator*(double v) => Vec2(x * v, y * v);

  Vec2 get sign => Vec2(x.sign, y.sign);
  Vec2 get abs => Vec2(x.abs(), y.abs());
}

// License: CC0 (http://creativecommons.org/publicdomain/zero/1.0/)
class EvanWallaceHalfClosedFormAlgorithm extends BlurAlgorithm {
  @override String get name => 'Evan Wallace';

  // A standard gaussian function, used for weighting samples
  static double gaussian(double x, double sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma)) / (sqrt(2.0 * pi) * sigma);
  }

  // This approximates the error function, needed for the gaussian integral
  static Vec2 erf(Vec2 x) {
    Vec2 s = x.sign;
    Vec2 a = x.abs;
    // x = 1.0 + (0.278393 + (0.230389 + 0.078108 * (a * a)) * a) * a;
    x = a.mul(a.mul(a.mul(a) * 0.078108 + 0.230389) + 0.278393) + 1.0;
    x = x.mul(x);
    return s.sub(s.div(x.mul(x)));
  }

  // Return the blurred mask along the x dimension
  static double roundedBoxShadowX(double x, double y, double sigma, double corner, Vec2 halfSize) {
    double delta = min(halfSize.y - corner - y.abs(), 0.0);
    double curved = halfSize.x - corner + sqrt(max(0.0, corner * corner - delta * delta));
    Vec2 integral = erf((Vec2(-curved, curved) + x) * (sqrt(0.5) / sigma)) * 0.5 + 0.5;
    return integral.y - integral.x;
  }

  // Return the mask for the shadow of a box from lower to upper
  double roundedBoxShadow(Vec2 halfSize, Vec2 point, double sigma, double corner) {
    // Center everything to make the math easier
    // These transformations are now done by the calling method
    // Vec2 center = (lower.add(upper)) * 0.5;
    // Vec2 halfSize = (upper.sub(lower)) * 0.5;
    // point = point.sub(center);

    // The signal is only non-zero in a limited range, so don't waste samples
    double low = point.y - halfSize.y;
    double high = point.y + halfSize.y;
    double start = (-3.0 * sigma).clamp(low, high);
    double end = (3.0 * sigma).clamp(low, high);

    // Accumulate samples (we can get away with surprisingly few samples)
    double step = (end - start) / 4.0;
    double y = start + step * 0.5;
    double value = 0.0;
    for (int i = 0; i < 4; i++) {
      value += roundedBoxShadowX(point.x, point.y - y, sigma, corner, halfSize) * gaussian(y, sigma) * step;
      y += step;
    }

    return value;
  }

  @override
  void computeOutput(TestCase testCase, Uint8List output) {
    Vec2 halfSize = Vec2.size(testCase.roundRect.rectSize) * 0.5;
    int w = testCase.sampleFieldWidth;
    int h = testCase.sampleFieldHeight;
    double sigma = testCase.blurSigmas.width;
    double corner = testCase.roundRect.cornerRadii.width;
    double y = 0.5 - testCase.sampleDistanceY - halfSize.y;
    for (int j = 0; j < h; j++, y += 1.0) {
      double x = 0.5 - testCase.sampleDistanceX - halfSize.x;
      for (int i = 0; i < w; i++, x += 1.0) {
        double sample = roundedBoxShadow(halfSize, Vec2(x, y), sigma, corner);
        output[j * w + i] = (sample * 255.0).round().toInt();
      }
    }
  }
}
