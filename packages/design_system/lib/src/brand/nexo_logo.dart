import 'dart:math' as math;

import 'package:design_system/src/tokens/app_colors.dart';
import 'package:flutter/widgets.dart';

/// The Nexo logo from the design (`docs/design/screens/logo_*`), drawn as a
/// vector so it stays sharp at any size.
///
/// The app icon and the splash images are rendered from the same painter
/// (`apps/banking_app/tool/brand_assets_test.dart`), so the brand has a
/// single source.
class NexoLogo extends StatelessWidget {
  const NexoLogo({
    required this.size,
    this.markOnly = false,
    this.semanticsLabel = 'Nexo',
    super.key,
  });

  /// Width and height.
  final double size;

  /// Only the "N" and the dot, without the navy square. Use it on navy
  /// backgrounds, such as the splash: its white strokes need a dark one.
  final bool markOnly;

  /// Name for screen readers, or `null` when the logo is decorative (e.g.
  /// next to the brand name already written).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final logo = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: NexoLogoPainter(markOnly: markOnly)),
    );
    final label = semanticsLabel;
    if (label == null) return ExcludeSemantics(child: logo);
    return Semantics(label: label, image: true, child: logo);
  }
}

/// Paints the Nexo logo in the largest centered square of the canvas.
///
/// Coordinates are fractions of the icon square, measured on the design's
/// 272 px logo: the orange "N", a white stem and diagonal over it, and an
/// orange dot.
class NexoLogoPainter extends CustomPainter {
  const NexoLogoPainter({this.markOnly = false, this.monochrome});

  /// See [NexoLogo.markOnly].
  final bool markOnly;

  /// Paints the whole mark in this color (Android themed icons).
  final Color? monochrome;

  /// Corner radius of the navy square, as in the design.
  static const cornerRadius = 0.257;

  /// Area of the square covered by the mark (strokes and dot).
  static const markBounds = Rect.fromLTRB(0.278, 0.226, 0.818, 0.762);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas
      ..save()
      ..translate((size.width - side) / 2, (size.height - side) / 2)
      ..scale(side);
    if (markOnly) {
      // The mark fills the canvas.
      canvas
        ..translate(0.5, 0.5)
        ..scale(1 / math.max(markBounds.width, markBounds.height))
        ..translate(-markBounds.center.dx, -markBounds.center.dy);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & const Size.square(1),
          const Radius.circular(cornerRadius),
        ),
        Paint()..color = AppColors.navy,
      );
      // Centered: the design's image has it slightly to the right, which
      // looks off-center inside the round masks of Android icons.
      canvas.translate(0.5 - markBounds.center.dx, 0.5 - markBounds.center.dy);
    }
    _paintMark(canvas);
    canvas.restore();
  }

  void _paintMark(Canvas canvas) {
    Paint stroke(Color color, double width) => Paint()
      ..color = monochrome ?? color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Orange "N": left stem, diagonal and right stem.
    canvas.drawPath(
      Path()
        ..moveTo(0.318, 0.721)
        ..lineTo(0.318, 0.272)
        ..lineTo(0.546, 0.592)
        ..lineTo(0.546, 0.272),
      stroke(AppColors.orange, 0.080),
    );
    // White stem and diagonal, over the right stem.
    canvas.drawPath(
      Path()
        ..moveTo(0.546, 0.728)
        ..lineTo(0.546, 0.406)
        ..lineTo(0.728, 0.728),
      stroke(AppColors.white, 0.068),
    );
    canvas.drawCircle(
      const Offset(0.750, 0.294),
      0.068,
      Paint()..color = monochrome ?? AppColors.orange,
    );
  }

  @override
  bool shouldRepaint(NexoLogoPainter oldDelegate) =>
      oldDelegate.markOnly != markOnly || oldDelegate.monochrome != monochrome;
}
