import 'package:accounts/accounts.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sdui/sdui.dart';

import '../helpers/helpers.dart';

void main() {
  late MockAccountsRepository repository;

  setUp(() {
    repository = MockAccountsRepository();
    when(() => repository.watchAccounts('u')).thenAnswer(
      (_) => Stream.value(
        const Right(
          AccountsSnapshot(accounts: [savings, checking], isFromCache: false),
        ),
      ),
    );
    when(
      () => repository.fetchTransactions(
        userId: 'u',
        accountId: any(named: 'accountId'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (invocation) async => Right(
        TransactionPage(
          items: invocation.namedArguments[#accountId] == 'savings'
              ? [movement(1, at: DateTime(2026, 10, 3, 9, 5))]
              : const [],
        ),
      ),
    );
  });

  Future<List<SduiAction>> pump(
    WidgetTester tester,
    List<Map<String, Object?>> components,
  ) async {
    final actions = <SduiAction>[];
    final registry = SduiRegistry(
      accountsSduiComponents(
        repository: repository,
        userId: 'u',
        now: () => DateTime(2026, 10, 3, 18),
      ),
    );
    await tester.pumpLocalized(
      Scaffold(
        body: SingleChildScrollView(
          child: SduiView(
            layout: SduiLayout(
              components: [
                for (final component in components)
                  SduiNode(
                    type: component['type']! as String,
                    properties: SduiProps(
                      (component['props'] as Map<String, Object?>?) ?? {},
                    ),
                  ),
              ],
            ),
            registry: registry,
            onAction: actions.add,
          ),
        ),
      ),
    );
    return actions;
  }

  const toAccounts = {'type': 'navigate', 'route': '/accounts'};

  group('balance_card', () {
    testWidgets('shows the live total and opens its action', (tester) async {
      final actions = await pump(tester, [
        {
          'type': 'balance_card',
          'props': {'action': toAccounts},
        },
      ]);

      expect(find.text(r'$4,400.50'), findsOneWidget);
      expect(find.text('2 cuentas'), findsOneWidget);

      await tester.tap(find.text(r'$4,400.50'));
      expect(actions, [const SduiNavigateAction('/accounts')]);
    });

    testWidgets('offline data says so', (tester) async {
      when(() => repository.watchAccounts('u')).thenAnswer(
        (_) => Stream.value(
          const Right(AccountsSnapshot(accounts: [savings], isFromCache: true)),
        ),
      );
      await pump(tester, [
        {'type': 'balance_card'},
      ]);

      expect(
        find.text(
          '1 cuenta · Sin conexión · mostrando tus últimos datos guardados',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an error offers a retry', (tester) async {
      when(
        () => repository.watchAccounts('u'),
      ).thenAnswer((_) => Stream.value(const Left(NetworkFailure())));
      await pump(tester, [
        {'type': 'balance_card'},
      ]);

      expect(find.text('No pudimos cargar tus cuentas'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('tx_list', () {
    testWidgets('lists the newest movements with a "see all" link', (
      tester,
    ) async {
      final actions = await pump(tester, [
        {
          'type': 'tx_list',
          'props': {'limit': 3, 'action': toAccounts},
        },
      ]);

      expect(find.text('Movimientos recientes'), findsOneWidget);
      expect(find.text('Movimiento 1'), findsOneWidget);

      await tester.tap(find.text('Ver todos'));
      expect(actions, [const SduiNavigateAction('/accounts')]);
    });

    testWidgets('the server can rename it; without action, no link', (
      tester,
    ) async {
      await pump(tester, [
        {
          'type': 'tx_list',
          'props': {
            'title': {'es': 'Tus últimos movimientos'},
          },
        },
      ]);

      expect(find.text('Tus últimos movimientos'), findsOneWidget);
      expect(find.text('Ver todos'), findsNothing);
    });

    testWidgets('no movements yet shows the empty state', (tester) async {
      when(
        () => repository.fetchTransactions(
          userId: 'u',
          accountId: any(named: 'accountId'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => const Right(TransactionPage(items: [])));
      await pump(tester, [
        {'type': 'tx_list'},
      ]);

      expect(find.text('Aún no tienes movimientos'), findsOneWidget);
    });

    testWidgets('the limit stays between 1 and 10', (tester) async {
      await pump(tester, [
        {
          'type': 'tx_list',
          'props': {'limit': 500},
        },
      ]);

      verify(
        () => repository.fetchTransactions(
          userId: 'u',
          accountId: 'savings',
          pageSize: 10,
        ),
      ).called(1);
    });
  });
}
