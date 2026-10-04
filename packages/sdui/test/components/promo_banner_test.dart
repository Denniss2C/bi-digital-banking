import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui/sdui.dart';

import '../helpers.dart';

void main() {
  const savingsPromo = {
    'eyebrow': 'Nexo Ahorro Flexible',
    'title': {
      'es': '¡Tu rendimiento subió al 8.5% anual!',
      'en': 'Your yield is now 8.5% a year!',
    },
    'body': 'Sin plazos forzosos.',
    'footnote': 'Tasa vigente 2026',
    'icon': 'trending_up',
    'cta': {
      'label': 'Simular ahora',
      'action': {'type': 'navigate', 'route': '/accounts'},
    },
  };

  Future<List<SduiAction>> pump(
    WidgetTester tester,
    Map<String, Object?> props, {
    Locale locale = const Locale('es'),
    ThemeData? theme,
  }) async {
    final actions = <SduiAction>[];
    await tester.pumpSdui(
      SduiView(
        layout: SduiLayout(
          components: [
            SduiNode(type: 'promo_banner', properties: SduiProps(props)),
          ],
        ),
        registry: SduiRegistry(standardSduiComponents),
        onAction: actions.add,
      ),
      locale: locale,
      theme: theme,
    );
    return actions;
  }

  testWidgets('shows its texts and runs its action', (tester) async {
    final actions = await pump(tester, savingsPromo);

    expect(find.text('NEXO AHORRO FLEXIBLE'), findsOneWidget);
    expect(find.text('¡Tu rendimiento subió al 8.5% anual!'), findsOneWidget);
    expect(find.text('Sin plazos forzosos.'), findsOneWidget);
    expect(find.text('Tasa vigente 2026'), findsOneWidget);

    await tester.tap(find.text('Simular ahora'));
    expect(actions, [const SduiNavigateAction('/accounts')]);
  });

  testWidgets('texts follow the app language', (tester) async {
    await pump(tester, savingsPromo, locale: const Locale('en'));

    expect(find.text('Your yield is now 8.5% a year!'), findsOneWidget);
  });

  testWidgets('without a supported action there is no button', (tester) async {
    await pump(tester, {
      'title': 'Nuevo',
      'cta': {
        'label': 'Abrir',
        'action': {'type': 'open_url', 'url': 'https://nexo.ec'},
      },
    });

    expect(find.text('Nuevo'), findsOneWidget);
    expect(find.byType(AppButton), findsNothing);
  });

  test('a title is required', () {
    expect(
      () => PromoBanner.fromProps(
        SduiProps(const {'body': 'Sin título'}),
        languageCode: 'es',
        onAction: (_) {},
      ),
      throwsA(isA<SduiPropsException>()),
    );
  });

  test('an unknown tone falls back to primary', () {
    final banner = PromoBanner.fromProps(
      SduiProps(const {'title': 'Hola', 'tone': 'neon'}),
      languageCode: 'es',
      onAction: (_) {},
    );

    expect(banner.tone, PromoTone.primary);
  });

  for (final (themeName, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    for (final tone in PromoTone.values) {
      testWidgets('${tone.name} tone keeps every text AA ($themeName)', (
        tester,
      ) async {
        await pump(tester, {...savingsPromo, 'tone': tone.name}, theme: theme);

        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(PromoBanner),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final background = (box.decoration as BoxDecoration).color!;
        for (final text in [
          'NEXO AHORRO FLEXIBLE',
          '¡Tu rendimiento subió al 8.5% anual!',
          'Sin plazos forzosos.',
          'Tasa vigente 2026',
        ]) {
          final color = tester
              .renderObject<RenderParagraph>(find.text(text))
              .text
              .style!
              .color!;
          expect(
            contrastRatio(color, background),
            greaterThanOrEqualTo(4.5),
            reason: text,
          );
        }
      });
    }
  }
}
