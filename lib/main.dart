import 'dart:ui' as ui;

import 'package:blur_approximations/src/algorithms/gaussian_2d_algorithm.dart';
import 'package:blur_approximations/src/algorithms/raph_levien_squircle_algorithm.dart';
import 'package:blur_approximations/src/blur_result.dart';
import 'package:blur_approximations/src/round_rect.dart';
import 'package:blur_approximations/src/test_case.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
      ),
      home: const MyHomePage(title: 'Blur algorithm test bench'),
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

  BlurResult? refResult;
  BlurResult? sqResult;

  @override
  void initState() {
    super.initState();
    radius.addListener(() { _asyncMethod(); });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      radius.value = 2.0;
    });
  }

  void _asyncMethod() async {
    RoundRect rr = RoundRect(rectSize: const Size(100.0, 100.0), cornerRadii: const Size(10, 10));
    TestCase tc = TestCase(roundRect: rr, blurSigmas: Size(radius.value, radius.value));
    var ref = await Gaussian2DAlgorithm().compute(tc);
    setState(() {
      refResult = ref;
    });
    var sq = await RaphLevienSquircleAlgorithm().compute(tc);
    setState(() {
      sqResult = sq;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      backgroundColor: Colors.grey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CustomPaint(
                  painter: _ResultPainter(result: refResult),
                  size: refResult == null
                      ? const Size(20, 20)
                      : Size(
                    refResult!.testCase.sampleFieldWidth.toDouble(),
                    refResult!.testCase.sampleFieldHeight.toDouble(),
                  ),
                ),
                CustomPaint(
                  painter: _DiffResultPainter(resultA: refResult, resultB: sqResult),
                  size: refResult == null || sqResult == null
                      ? const Size(20, 20)
                      : Size(
                    refResult!.testCase.sampleFieldWidth.toDouble(),
                    refResult!.testCase.sampleFieldHeight.toDouble(),
                  ),
                ),
                CustomPaint(
                  painter: _ResultPainter(result: sqResult),
                  size: sqResult == null
                      ? const Size(20, 20)
                      : Size(
                    sqResult!.testCase.sampleFieldWidth.toDouble(),
                    sqResult!.testCase.sampleFieldHeight.toDouble(),
                  ),
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
                  onChanged: (value) {
                    radius.value = value;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPainter extends CustomPainter {
  _ResultPainter({required this.result});

  final BlurResult? result;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (result != null) {
      int w = result!.testCase.sampleFieldWidth;
      int h = result!.testCase.sampleFieldHeight;
      var buf = result!.result;
      Paint paint = Paint();
      for (int yi = 0; yi < h; yi++) {
        for (int xi = 0; xi < w; xi++) {
          int c = 255 - buf[yi * w + xi];
          paint.color = Color.fromARGB(0xff, c, c, c);
          canvas.drawRect(Rect.fromLTWH(xi.toDouble(), yi.toDouble(), 1, 1), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DiffResultPainter extends CustomPainter {
  _DiffResultPainter({required this.resultA, required this.resultB});

  final BlurResult? resultA;
  final BlurResult? resultB;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (resultA != null && resultB != null) {
      int w = resultA!.testCase.sampleFieldWidth;
      int h = resultA!.testCase.sampleFieldHeight;
      var bufA = resultA!.result;
      var bufB = resultB!.result;
      Paint paint = Paint();
      for (int yi = 0; yi < h; yi++) {
        for (int xi = 0; xi < w; xi++) {
          int c = 255 - (bufA[yi * w + xi] - bufB[yi * w + xi]).abs();
          paint.color = Color.fromARGB(0xff, 0xff, c, 0xff);
          canvas.drawRect(Rect.fromLTWH(xi.toDouble(), yi.toDouble(), 1, 1), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}