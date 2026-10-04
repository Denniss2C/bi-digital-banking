import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:accounts/src/presentation/sdui/balance_card_component.dart';
import 'package:accounts/src/presentation/sdui/recent_movements_component.dart';
import 'package:sdui/sdui.dart';

/// SDUI components owned by accounts, for the shell to register:
/// `registry.registerAll(accountsSduiComponents(...))`.
///
/// - `balance_card`: live total balance. Props: `action`.
/// - `tx_list`: newest movements of all the accounts. Props: `title`,
///   `limit` (1 to 10, default 5) and `action` ("Ver todos").
Map<String, SduiComponentBuilder> accountsSduiComponents({
  required AccountsRepository repository,
  required String userId,
  DateTime Function() now = DateTime.now,
}) {
  return {
    'balance_card': (context, props, onAction) {
      final action = props.action('action');
      return BalanceCardComponent(
        repository: repository,
        userId: userId,
        onTap: action == null ? null : () => onAction(action),
      );
    },
    'tx_list': (context, props, onAction) {
      final action = props.action('action');
      return RecentMovementsComponent(
        repository: repository,
        userId: userId,
        limit: (props.integer('limit') ?? 5).clamp(1, 10),
        now: now,
        title: props.text('title', languageCode: context.sduiLanguageCode),
        onSeeAll: action == null ? null : () => onAction(action),
      );
    },
  };
}
