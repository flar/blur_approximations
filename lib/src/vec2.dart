import 'dart:math';
import 'dart:ui';

class Vec2 {
  Vec2(this.x, this.y);
  Vec2.size(Size size) : x = size.width, y = size.height;
  Vec2.offset(Offset size) : x = size.dx, y = size.dy;

  final double x;
  final double y;

  // sadly, no multi-type operator overloads in Dart
  Vec2 add(Vec2 o) => Vec2(x + o.x, y + o.y);
  Vec2 sub(Vec2 o) => Vec2(x - o.x, y - o.y);
  Vec2 mul(Vec2 o) => Vec2(x * o.x, y * o.y);
  Vec2 div(Vec2 o) => Vec2(x / o.x, y / o.y);
  Vec2 divInto(double v) => Vec2(v / x, v / y);

  Vec2 operator-() => Vec2(-x, -y);
  Vec2 operator+(double v) => Vec2(x + v, y + v);
  Vec2 operator*(double v) => Vec2(x * v, y * v);
  Vec2 operator/(double v) => Vec2(x / v, y / v);

  Vec2 get sign => Vec2(x.sign, y.sign);
  Vec2 get abs => Vec2(x.abs(), y.abs());
  Vec2 get expV => Vec2(exp(x), exp(y));
  Vec2 get reciprocal => Vec2(1.0 / x, 1.0 / y);
}
