import 'package:accounts/accounts.dart';
import 'package:accounts/src/presentation/presentation_helpers.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/helpers.dart';

void main() {
  late MockAccountsRepository repository;

  setUp(() => repository = MockAccountsRepository());

  void stubAccounts(Either<Failure, AccountsSnapshot> result) => when(
    () => repository.watchAccounts('u'),
  ).thenAnswer((_) => Stream.value(result));

  group('AccountsPage', () {
    Future<void> pump(WidgetTester tester, {List<Account>? opened}) =>
        tester.pumpLocalized(
          AccountsPage(
            repository: repository,
            userId: 'u',
            onOpenAccount: (account) => opened?.add(account),
          ),
        );

    testWidgets('shows the total balance and opens an account', (tester) async {
      stubAccounts(
        const Right(
          AccountsSnapshot(accounts: [savings, checking], isFromCache: false),
        ),
      );
      final opened = <Account>[];
      await pump(tester, opened: opened);

      expect(find.text(r'$4,400.50'), findsOneWidget);
      expect(find.text('2 cuentas'), findsOneWidget);
      expect(find.byType(AppOfflineBanner), findsNothing);

      await tester.tap(find.text('Cuenta Corriente'));
      expect(opened, [checking]);
    });

    testWidgets('hero texts are light on navy (contrast)', (tester) async {
      stubAccounts(
        const Right(AccountsSnapshot(accounts: [savings], isFromCache: false)),
      );
      await pump(tester);

      // With one account the total equals its balance: look only inside
      // the hero card.
      final hero = find.byWidgetPredicate(
        (widget) => widget is AppCard && widget.variant == AppCardVariant.hero,
      );
      for (final text in [r'$3,845.50', 'SALDO TOTAL DISPONIBLE', '1 cuenta']) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: hero, matching: find.text(text)),
        );
        expect(paragraph.text.style?.color, AppColors.white, reason: text);
      }
    });

    testWidgets('cached data shows the offline notice', (tester) async {
      stubAccounts(
        const Right(AccountsSnapshot(accounts: [savings], isFromCache: true)),
      );
      await pump(tester);

      expect(find.byType(AppOfflineBanner), findsOneWidget);
      expect(find.text('Cuenta de Ahorros'), findsOneWidget);
    });

    testWidgets('no accounts yet shows the preparing state', (tester) async {
      stubAccounts(
        const Right(AccountsSnapshot(accounts: [], isFromCache: false)),
      );
      await pump(tester);

      expect(find.text('Estamos preparando tus cuentas'), findsOneWidget);
    });

    testWidgets('an error offers a retry', (tester) async {
      stubAccounts(const Left(NetworkFailure()));
      await pump(tester);

      expect(find.text('No pudimos cargar tus cuentas'), findsOneWidget);
      expect(
        find.text('Revisa tu conexión e inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('AccountDetailPage', () {
    testWidgets('shows the balance and loads more movements on scroll', (
      tester,
    ) async {
      stubAccounts(
        const Right(AccountsSnapshot(accounts: [savings], isFromCache: false)),
      );
      const cursor = TransactionCursor('next');
      when(
        () => repository.fetchTransactions(
          userId: 'u',
          accountId: 'savings',
          after: null,
          pageSize: 20,
        ),
      ).thenAnswer(
        (_) async => Right(
          TransactionPage(
            items: [for (var i = 0; i < 20; i++) movement(i)],
            next: cursor,
          ),
        ),
      );
      when(
        () => repository.fetchTransactions(
          userId: 'u',
          accountId: 'savings',
          after: cursor,
          pageSize: 20,
        ),
      ).thenAnswer((_) async => Right(TransactionPage(items: [movement(99)])));

      await tester.pumpLocalized(const SizedBox()); // warm up localizations
      await tester.pumpLocalized(
        AccountDetailPage(
          repository: repository,
          userId: 'u',
          accountId: 'savings',
          now: () => DateTime(2026, 10, 3),
        ),
      );

      expect(find.text(r'$3,845.50'), findsOneWidget);
      expect(find.text('Movimiento 0'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Movimiento 99'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Movimiento 99'), findsOneWidget);
    });
  });

  group('formatMovementDate', () {
    setUpAll(() => initializeDateFormatting('es'));

    test('uses Hoy / Ayer and a short date otherwise', () async {
      final l10n = await AccountsLocalizations.delegate.load(
        const Locale('es'),
      );
      final now = DateTime(2026, 10, 3, 18);
      String format(DateTime d) =>
          formatMovementDate(d, now: now, l10n: l10n, locale: 'es');

      expect(format(DateTime(2026, 10, 3, 11, 30)), 'Hoy · 11:30');
      expect(format(DateTime(2026, 10, 2, 9, 5)), 'Ayer · 9:05');
      expect(format(DateTime(2026, 9, 15)), '15 sept');
    });
  });
}
