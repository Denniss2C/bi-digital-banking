import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<Color> _colors(AppSemanticColors colors) => [
  colors.positive,
  colors.negative,
  colors.warning,
  colors.card,
  colors.border,
  colors.heroSurface,
  colors.onHeroSurface,
  colors.link,
];

void main() {
  const light = AppSemanticColors.light;
  const dark = AppSemanticColors.dark;

  test('lerp goes from one theme to the other, as a theme change does', () {
    expect(_colors(light.lerp(dark, 0)), _colors(light));
    expect(_colors(light.lerp(dark, 1)), _colors(dark));
    expect(
      light.lerp(dark, 0.5).negative,
      Color.lerp(light.negative, dark.negative, 0.5),
    );
    expect(light.lerp(null, 0.5), same(light));
  });

  test('copyWith replaces only the given colors', () {
    final custom = light.copyWith(link: Colors.purple);

    expect(custom.link, Colors.purple);
    expect(_colors(custom).take(7), _colors(light).take(7));
  });
}
