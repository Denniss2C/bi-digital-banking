import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

RenderObject _painted(WidgetTester tester) => tester.renderObject(
  find.descendant(
    of: find.byType(NexoLogo),
    matching: find.byType(CustomPaint),
  ),
);

void main() {
  group('NexoLogo', () {
    testWidgets('takes the given size', (tester) async {
      await tester.pumpWithTheme(const Center(child: NexoLogo(size: 40)));

      expect(tester.getSize(find.byType(NexoLogo)), const Size.square(40));
    });

    testWidgets('screen readers announce the brand as an image', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWithTheme(const Center(child: NexoLogo(size: 40)));

      expect(
        tester.getSemantics(find.byType(NexoLogo)),
        matchesSemantics(label: 'Nexo', isImage: true),
      );
      semantics.dispose();
    });

    testWidgets('without a label it is decorative', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWithTheme(
        const Center(child: NexoLogo(size: 40, semanticsLabel: null)),
      );

      expect(find.bySemanticsLabel('Nexo'), findsNothing);
      semantics.dispose();
    });

    testWidgets('the full logo is the mark on the navy square', (tester) async {
      await tester.pumpWithTheme(const Center(child: NexoLogo(size: 40)));

      // Order matters: the white strokes go over the orange "N".
      expect(
        _painted(tester),
        paints
          ..rrect(color: AppColors.navy)
          ..path(color: AppColors.orange)
          ..path(color: AppColors.white)
          ..circle(color: AppColors.orange),
      );
    });

    testWidgets('markOnly leaves out the navy square', (tester) async {
      await tester.pumpWithTheme(
        const Center(child: NexoLogo(size: 40, markOnly: true)),
      );

      expect(_painted(tester), isNot(paints..rrect()));
      expect(
        _painted(tester),
        paints
          ..path(color: AppColors.orange)
          ..path(color: AppColors.white)
          ..circle(color: AppColors.orange),
      );
    });
  });

  group('NexoLogoPainter', () {
    testWidgets('monochrome paints the whole mark in one color', (
      tester,
    ) async {
      const ink = Color(0xFF000000);
      await tester.pumpWithTheme(
        const Center(
          child: SizedBox.square(
            dimension: 40,
            child: CustomPaint(
              painter: NexoLogoPainter(markOnly: true, monochrome: ink),
            ),
          ),
        ),
      );

      expect(
        tester.renderObject(find.byType(CustomPaint).last),
        paints
          ..path(color: ink)
          ..path(color: ink)
          ..circle(color: ink),
      );
    });

    test('repaints only when what it draws changes', () {
      const logo = NexoLogoPainter();

      expect(logo.shouldRepaint(const NexoLogoPainter()), isFalse);
      expect(logo.shouldRepaint(const NexoLogoPainter(markOnly: true)), isTrue);
      expect(
        logo.shouldRepaint(const NexoLogoPainter(monochrome: AppColors.white)),
        isTrue,
      );
    });

    test('the mark fits the safe zone of Android adaptive icons', () {
      // The launcher may crop the 72 dp icon to a 66 dp circle: every corner
      // of the mark's bounds must stay inside it.
      const safeRadius = 33 / 72;
      final center = const Offset(0.5, 0.5);
      final bounds = Rect.fromCenter(
        center: center,
        width: NexoLogoPainter.markBounds.width,
        height: NexoLogoPainter.markBounds.height,
      );
      for (final corner in [
        bounds.topLeft,
        bounds.topRight,
        bounds.bottomLeft,
        bounds.bottomRight,
      ]) {
        expect((corner - center).distance, lessThan(safeRadius));
      }
    });
  });
}
