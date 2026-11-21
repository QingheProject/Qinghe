import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';

/// 青禾标志：青绿方块中的一株禾苗。
///
/// 传入 [progress] 时依次播放方块放大、线条描绘与叶片填充。
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 48, this.progress, super.key});

  final double size;
  final Animation<double>? progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      image: true,
      label: '青禾',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _BrandMarkPainter(
            progress: progress ?? kAlwaysCompleteAnimation,
            tile: colors.accent,
            stroke: colors.onAccent,
          ),
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter({
    required this.progress,
    required this.tile,
    required this.stroke,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color tile;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final tileT = AppMotion.interval(t, 0, 0.4);
    final drawT = AppMotion.interval(t, 0.2, 0.8, Curves.easeInOutCubic);
    final fillT = AppMotion.interval(t, 0.6, 1, Curves.easeOut);
    final s = size.shortestSide;

    canvas
      ..save()
      ..translate(s / 2, s / 2)
      ..scale(0.6 + 0.4 * tileT)
      ..translate(-s / 2, -s / 2)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & Size.square(s),
          Radius.circular(s * 0.28),
        ),
        Paint()..color = tile.withValues(alpha: tileT),
      )
      ..restore();

    if (drawT <= 0) return;

    final line = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final leftLeaf = _leftLeaf(s);
    final rightLeaf = _rightLeaf(s);

    for (final path in [_stem(s), _ground(s), leftLeaf, rightLeaf]) {
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * drawT), line);
      }
    }

    if (fillT > 0) {
      final fill = Paint()..color = stroke.withValues(alpha: fillT);
      canvas
        ..drawPath(leftLeaf, fill)
        ..drawPath(rightLeaf, fill);
    }
  }

  Path _stem(double s) => Path()
    ..moveTo(0.5 * s, 0.78 * s)
    ..cubicTo(0.5 * s, 0.64 * s, 0.5 * s, 0.5 * s, 0.5 * s, 0.4 * s);

  Path _ground(double s) => Path()
    ..moveTo(0.32 * s, 0.78 * s)
    ..lineTo(0.68 * s, 0.78 * s);

  Path _leftLeaf(double s) => Path()
    ..moveTo(0.5 * s, 0.62 * s)
    ..cubicTo(0.4 * s, 0.62 * s, 0.26 * s, 0.56 * s, 0.24 * s, 0.42 * s)
    ..cubicTo(0.38 * s, 0.42 * s, 0.48 * s, 0.5 * s, 0.5 * s, 0.62 * s)
    ..close();

  Path _rightLeaf(double s) => Path()
    ..moveTo(0.5 * s, 0.48 * s)
    ..cubicTo(0.56 * s, 0.34 * s, 0.67 * s, 0.25 * s, 0.79 * s, 0.25 * s)
    ..cubicTo(0.79 * s, 0.39 * s, 0.67 * s, 0.49 * s, 0.5 * s, 0.48 * s)
    ..close();

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.tile != tile ||
      oldDelegate.stroke != stroke;
}
