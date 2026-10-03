import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  group('AppButton', () {
    testWidgets('shows the label and reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWithTheme(
        AppButton(label: 'Transferir', onPressed: () => taps++),
      );

      await tester.tap(find.text('Transferir'));

      expect(taps, 1);
    });

    testWidgets('primary text is navy on orange (AA contrast)', (tester) async {
      await tester.pumpWithTheme(
        AppButton(label: 'Continuar', onPressed: () {}),
      );

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Continuar'),
      );
      expect(paragraph.text.style?.color, AppColors.navy);
    });

    testWidgets('is at least 48 px tall', (tester) async {
      await tester.pumpWithTheme(AppButton(label: 'Ok', onPressed: () {}));

      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(AppSpacing.minTouchTarget),
      );
    });

    testWidgets('loading ignores taps but keeps the label for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWithTheme(
        AppButton(label: 'Pagar', onPressed: () => taps++, isLoading: true),
      );

      await tester.tap(find.byType(FilledButton));

      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Pagar'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a long label at 200% text scale does not overflow', (
      tester,
    ) async {
      await tester.pumpWithTheme(
        AppButton(
          label: 'Continuar con la transferencia entre cuentas propias',
          icon: Icons.arrow_forward,
          onPressed: () {},
        ),
        textScale: 2,
        surfaceSize: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
