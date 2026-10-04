import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui/sdui.dart';

import '../helpers.dart';

/// Shows its label and counts taps: enough to check order, failures and
/// kept state.
class _Counter extends StatefulWidget {
  const _Counter(this.label);

  final String label;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var _taps = 0;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => _taps++),
    child: Text('${widget.label} $_taps'),
  );
}

final _registry = SduiRegistry({
  'counter': (context, props, onAction) =>
      _Counter(props.string('label') ?? '?'),
  'broken': (context, props, onAction) =>
      throw const SduiPropsException('"title" is required'),
  'button': (context, props, onAction) => TextButton(
    onPressed: () => onAction(props.action('action')!),
    child: const Text('Go'),
  ),
});

void main() {
  Future<void> show(
    WidgetTester tester,
    String json, {
    SduiActionHandler? onAction,
    SduiErrorHandler? onError,
  }) => tester.pumpSdui(
    SduiView(
      layout: layoutOf(json),
      registry: _registry,
      onAction: onAction ?? (_) {},
      onComponentError: onError,
    ),
  );

  testWidgets('renders known components in order and skips unknown ones', (
    tester,
  ) async {
    await show(tester, '''
      {"components": [
        {"type": "counter", "props": {"label": "A"}},
        {"type": "stories"},
        {"type": "counter", "props": {"label": "B"}}
      ]}
    ''');

    expect(find.text('A 0'), findsOneWidget);
    expect(find.text('B 0'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('A 0')).dy,
      lessThan(tester.getTopLeft(find.text('B 0')).dy),
    );
  });

  testWidgets('a component that fails is skipped and reported', (tester) async {
    final errors = <String>[];
    await show(tester, '''
      {"components": [
        {"type": "broken", "id": "promo-1"},
        {"type": "counter", "props": {"label": "A"}}
      ]}
    ''', onError: (node, error, _) => errors.add('${node.id}: $error'));

    expect(find.text('A 0'), findsOneWidget);
    expect(errors, ['promo-1: SduiPropsException: "title" is required']);
  });

  testWidgets('a component keeps its state when the layout is reordered', (
    tester,
  ) async {
    await show(tester, '''
      {"components": [
        {"type": "counter", "id": "a", "props": {"label": "A"}},
        {"type": "counter", "id": "b", "props": {"label": "B"}}
      ]}
    ''');
    await tester.tap(find.text('A 0'));
    await tester.pump();

    await show(tester, '''
      {"components": [
        {"type": "counter", "id": "b", "props": {"label": "B"}},
        {"type": "counter", "id": "a", "props": {"label": "A"}}
      ]}
    ''');

    expect(find.text('A 1'), findsOneWidget);
    expect(find.text('B 0'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('B 0')).dy,
      lessThan(tester.getTopLeft(find.text('A 1')).dy),
    );
  });

  testWidgets('a repeated id does not break the screen', (tester) async {
    await show(tester, '''
      {"components": [
        {"type": "counter", "id": "x", "props": {"label": "A"}},
        {"type": "counter", "id": "x", "props": {"label": "B"}}
      ]}
    ''');

    expect(tester.takeException(), isNull);
    expect(find.text('A 0'), findsOneWidget);
    expect(find.text('B 0'), findsOneWidget);
  });

  testWidgets('component actions reach the host', (tester) async {
    final actions = <SduiAction>[];
    await show(tester, '''
      {"components": [
        {"type": "button", "props": {"action": {"type": "navigate", "route": "/fx"}}}
      ]}
    ''', onAction: actions.add);

    await tester.tap(find.text('Go'));

    expect(actions, [const SduiNavigateAction('/fx')]);
  });
}
