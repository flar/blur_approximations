// License: CC0 (http://creativecommons.org/publicdomain/zero/1.0/)
import 'dart:math';

import 'package:blur_approximations/src/blur_algorithm.dart';
import 'package:blur_approximations/src/test_case.dart';
import 'package:blur_approximations/src/vec2.dart';

class ImpellerCommitEd498f1Algorithm extends BlurAlgorithm {
  @override String get name => 'Impeller #ed498f1';

  @override
  BlurShaderInstance getInstance(TestCase testCase) {
    return _ImpellerCommitEd498f1Shader(testCase);
  }
}

class _ImpellerCommitEd498f1Shader extends BlurShaderInstance {
  static const int kSampleCount = 4;
  // sqrt(2 * pi)
  static const double kSqrtTwoPi = 2.50662827463;
  // sqrt(3)
  static const double kSqrtThree = 1.73205080757;

  /// Gaussian distribution function.
  static double gaussian(double x, double sigma) {
    var variance = sigma * sigma;
    return exp(-0.5 * x * x / variance) / (kSqrtTwoPi * sigma);
  }

  /// Simpler (but less accurate) approximation of the Gaussian integral.
  static Vec2 fastGaussianIntegral(Vec2 x, double sigma) {
    // return 1.0 / (1.0 + exp(-kSqrtThree / sigma * x));
    return ((x * -kSqrtThree / sigma).expV + 1.0).reciprocal;
  }

  _ImpellerCommitEd498f1Shader(TestCase testCase) {
    halfSize = Vec2.size(testCase.roundRect.halfSize);
    sigma = testCase.blurSigmas.width;
    corners = Vec2.size(testCase.roundRect.cornerRadii);
    center = Vec2.offset(testCase.roundRect.rect.center);
  }

  late final Vec2 halfSize;
  late final Vec2 center;
  late final double sigma;
  late final Vec2 corners;

  /// Closed form unidirectional rounded rect blur mask solution using the
  /// analytical Gaussian integral (with approximated erf).
  static double rrectBlurX(
      Vec2 samplePosition,
      Vec2 halfSize,
      double blurSigma,
      Vec2 corners) {
    // The vertical edge of the rrect consists of a flat portion and a curved
    // portion, the two of which vary in size depending on the size of the
    // corner radii, both adding up to half_size.y.
    // half_size.y - corner_radii.y is the size of the vertical flat
    // portion of the rrect.
    // subtracting the absolute value of the Y sample_position will be
    // negative (and then clamped to 0) for positions that are located
    // vertically in the flat part of the rrect, and will be the relative
    // distance from the center of curvature otherwise.
    var spaceY = min(0.0, halfSize.y - corners.y - samplePosition.y.abs());
    // space is now in the range [0.0, corner_radii.y]. If the y sample was
    // in the flat portion of the rrect, it will be 0.0

    // We will now calculate rrectDistance as the distance from the center-line
    // of the rrect towards the near side of the rrect.
    // half_size.x - frag_info.corner_radii.x is the size of the horizontal
    // flat portion of the rrect.
    // We add to that the X size (space_x) of the curved corner measured at
    // the indicated Y coordinate we calculated as spaceY, such that:
    //   (spaceY / corner_radii.y)^2 + (space_x / corner_radii.x)^2 == 1.0
    // Since we want the space_x, we rearrange the equation as:
    //   space_x = corner_radii.x * sqrt(1.0 - (spaceY / corner_radii.y)^2)
    // We need to prevent negative values inside the sqrt which can occur
    // when the Y sample was beyond the vertical size of the rrect and thus
    // spaceY was larger than corner_radii.y.
    // The calling function RRectBlur will never provide a Y sample outside
    // of that range, though, so the max(0.0) is mostly a precaution.
    var unitSpaceY = spaceY / corners.y;
    var unitSpaceX = sqrt(max(0.0, 1.0 - unitSpaceY * unitSpaceY));
    var rrectDistance =
        halfSize.x - corners.x * (1.0 - unitSpaceX);

    // Now we integrate the Gaussian over the range of the relative positions
    // of the left and right sides of the rrect relative to the sampling
    // X coordinate.
    var integral = fastGaussianIntegral(
        Vec2(-rrectDistance, rrectDistance) + samplePosition.x,
        blurSigma);
    // integral.y contains the evaluation of the indefinite gaussian integral
    // function at (X + rrectDistance) and integral.x contains the evaluation
    // of it at (X - rrectDistance). Subtracting the two produces the
    // integral result over the range from one to the other.
    return integral.y - integral.x;
  }

  static double rrectBlur(
      Vec2 samplePosition,
      Vec2 halfSize,
      double blurSigma,
      Vec2 corners) {
    // Limit the sampling range to 3 standard deviations in the Y direction from
    // the kernel center to incorporate 99.7% of the color contribution.
    var halfSamplingRange = blurSigma * 3.0;

    // We want to cover the range [Y - half_range, Y + half_range], but we
    // don't want to sample beyond the edge of the rrect (where the RRectBlurX
    // function produces bad information and where the real answer at those
    // locations will be 0.0 anyway).
    var beginY = max(-halfSamplingRange, samplePosition.y - halfSize.y);
    var endY = min(halfSamplingRange, samplePosition.y + halfSize.y);
    var interval = (endY - beginY) / kSampleCount;

    // Sample the X blur kSampleCount times, weighted by the Gaussian function.
    var result = 0.0;
    for (int sampleI = 0; sampleI < kSampleCount; sampleI++) {
      var y = beginY + interval * (sampleI + 0.5);
      var sample = Vec2(samplePosition.x, samplePosition.y - y);
      var blurX = rrectBlurX(sample, halfSize, blurSigma, corners);
      result += blurX * gaussian(y, blurSigma) * interval;
    }

    return result;
  }

  @override
  double sample(Vec2 position) {
    return rrectBlur(position.sub(center), halfSize, sigma, corners);
  }
}
