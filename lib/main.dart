import 'dart:math';
import 'dart:ui' as ui;

import 'package:blur_approximations/src/algorithms/even_wallace_half_closed_form_algorithm.dart';
import 'package:blur_approximations/src/algorithms/gaussian_2d_algorithm.dart';
import 'package:blur_approximations/src/algorithms/raph_levien_squircle_algorithm.dart';
import 'package:blur_approximations/src/blur_result.dart';
import 'package:blur_approximations/src/round_rect.dart';
import 'package:blur_approximations/src/test_case.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'Blur algorithm test bench'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ValueNotifier<double> radius = ValueNotifier(1);
  ValueNotifier<double> rectWidth = ValueNotifier(100);
  ValueNotifier<double> rectHeight = ValueNotifier(100);
  ValueNotifier<double> cornerWidth = ValueNotifier(10);
  ValueNotifier<double> cornerHeight = ValueNotifier(10);

  BlurResult? refResult;
  BlurResult? sqResult;
  BlurResult? evanResult;

  @override
  void initState() {
    super.initState();
    radius.addListener(() { _asyncMethod(); });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      radius.value = 20.0;
    });
  }

  void makeBlurImage(BlurResult blur) {
    int w = blur.testCase.sampleFieldWidth;
    int h = blur.testCase.sampleFieldHeight;
    int len = blur.testCase.sampleFieldLength;
    Uint8List output = blur.result;
    Uint8List pixels = Uint8List(len * 4);
    for (int i = 0; i < len; i++) {
      int gray = 255 - output[i];
      pixels[i * 4]     = gray;  // red
      pixels[i * 4 + 1] = gray;  // green
      pixels[i * 4 + 2] = gray;  // blue
      pixels[i * 4 + 3] = 0xff;  // alpha
    }
    ui.decodeImageFromPixels(pixels, w, h, ui.PixelFormat.rgba8888, (result) {
      setState(() {
        blur.image = result;
      });
    });
  }

  void makeDiffImage(BlurResult blur, BlurResult ref) {
    int w = blur.testCase.sampleFieldWidth;
    int h = blur.testCase.sampleFieldHeight;
    int len = blur.testCase.sampleFieldLength;
    Uint8List output = blur.result;
    Uint8List reference = ref.result;
    Uint8List pixels = Uint8List(len * 4);
    int minDiff = 0;
    int maxDiff = 0;
    int totalDiff = 0;
    for (int i = 0; i < len; i++) {
      int diff = output[i] - reference[i];
      minDiff = min(minDiff, diff);
      maxDiff = max(maxDiff, diff);
      totalDiff += diff.abs();
      if (diff < 0) {
        // the more negative the diff,
        // the more the algorithm underestimated the shadow,
        // the redder the image will be
        pixels[i * 4]     = 0xff;         // red
        pixels[i * 4 + 1] = 0xff + diff;  // green
        pixels[i * 4 + 2] = 0xff + diff;  // blue
      } else {
        // the more positive the diff,
        // the more the algorithm overestimated the shadow,
        // the bluer the image will be
        pixels[i * 4]     = 0xff - diff;  // red
        pixels[i * 4 + 1] = 0xff - diff;  // green
        pixels[i * 4 + 2] = 0xff;         // blue
      }
      pixels[i * 4 + 3] = 0xff;  // alpha
    }
    ui.decodeImageFromPixels(pixels, w, h, ui.PixelFormat.rgba8888, (result) {
      setState(() {
        blur.refDiffImage = result;
        blur.minDiff = minDiff;
        blur.maxDiff = maxDiff;
        blur.avgDiff = (1000 * totalDiff / len).round() / 1000.0;
      });
    });
  }

  void _asyncMethod() async {
    RoundRect rr = RoundRect(
      rect: Rect.fromLTWH(0, 0, rectWidth.value, rectHeight.value),
      cornerRadii: Size(cornerWidth.value, cornerHeight.value),
    );
    TestCase tc = TestCase(roundRect: rr, blurSigmas: Size(radius.value, radius.value));
    var ref = await Gaussian2DAlgorithm().compute(tc);
    setState(() {
      refResult = ref;
    });
    makeBlurImage(ref);
    var sq = await RaphLevienSquircleAlgorithm().compute(tc);
    setState(() {
      sqResult = sq;
    });
    makeBlurImage(sq);
    makeDiffImage(sq, ref);
    var evan = await EvanWallaceHalfClosedFormAlgorithm().compute(tc);
    setState(() {
      evanResult = evan;
    });
    makeBlurImage(evan);
    makeDiffImage(evan, ref);
  }

  @override
  Widget build(BuildContext context) {
    // big enough for any of the results for any of the possible parameters
    // 100 x 100 round rect + 20*3 padding on all sides
    Size resultSize = const Size(220, 220);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.grey.shade200,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CustomPaint(
                  painter: _ResultPainter(result: refResult),
                  size: resultSize,
                ),
                CustomPaint(
                  painter: _DiffResultPainter(result: sqResult),
                  size: resultSize,
                ),
                CustomPaint(
                  painter: _ResultPainter(result: sqResult),
                  size: resultSize,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CustomPaint(
                  painter: _ResultPainter(result: refResult),
                  size: resultSize,
                ),
                CustomPaint(
                  painter: _DiffResultPainter(result: evanResult),
                  size: resultSize,
                ),
                CustomPaint(
                  painter: _ResultPainter(result: evanResult),
                  size: resultSize,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('blur radius'),
                Slider(
                  value: radius.value,
                  min: 0.1,
                  max: 20.0,
                  divisions: 199,
                  onChanged: (value) {
                    radius.value = value;
                  },
                  activeColor: Colors.green.shade800,
                  inactiveColor: Colors.green.shade200,
                ),
                Text('${(radius.value * 10.0).round() / 10.0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void centerText(
    Canvas canvas,
    Offset position,
    String s,
    {
      required double relativeY,
      required Color color,
    }) {
  TextSpan span = TextSpan(
    text: s,
    style: TextStyle(color: color),
  );
  TextPainter painter = TextPainter(
    text: span,
    textDirection: TextDirection.ltr,
  );
  painter.layout();
  double x = position.dx - painter.width * 0.5;
  double y = position.dy + (relativeY - 0.5) * painter.height;
  painter.paint(canvas, Offset(x, y));
}

class _ResultPainter extends CustomPainter {
  _ResultPainter({required this.result});

  final BlurResult? result;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    if (result != null) {
      int w = result!.testCase.sampleFieldWidth;
      int h = result!.testCase.sampleFieldHeight;
      Offset rCenter = result!.testCase.roundRect.rect.center;
      double x = size.width * 0.5 - (rCenter.dx - result!.testCase.sampleStartX);
      double y = size.height * 0.5 - (rCenter.dy - result!.testCase.sampleStartY);
      if (result!.image != null) {
        canvas.drawImage(result!.image!, Offset(x, y), Paint());
      } else {
        canvas.drawRect(
          Rect.fromLTWH(x, y, w.toDouble(), h.toDouble()),
          Paint()..color = Colors.yellow,
        );
      }
      double elapsed = result!.computeTime.inMicroseconds / 1000.0;
      centerText(
        canvas, Offset(size.width * 0.5, 0), '$elapsed ms',
        relativeY: 0.5,
        color: Colors.blue.shade800,
      );
      centerText(
        canvas, Offset(size.width * 0.5, size.height), result!.algorithm.name,
        relativeY: -0.5,
        color: Colors.blue.shade800,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DiffResultPainter extends CustomPainter {
  _DiffResultPainter({required this.result});

  final BlurResult? result;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    if (result != null) {
      Offset rCenter = result!.testCase.roundRect.rect.center;
      double x = size.width * 0.5 - (rCenter.dx - result!.testCase.sampleStartX);
      double y = size.height * 0.5 - (rCenter.dy - result!.testCase.sampleStartY);
      if (result!.refDiffImage != null) {
        canvas.drawImage(result!.refDiffImage!, Offset(x, y), Paint());
      }
      centerText(
        canvas, Offset(size.width * 0.5, 0), 'diff range = [${result!.minDiff}, ${result!.maxDiff}]',
        relativeY: 0.5,
        color: Colors.blue.shade800,
      );
      centerText(
        canvas, Offset(size.width * 0.5, size.height), 'diff average = ${result!.avgDiff}',
        relativeY: -0.5,
        color: Colors.blue.shade800,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
