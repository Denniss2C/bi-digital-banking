import 'package:accounts/src/domain/entities/account.dart';

/// The accounts, and their first movements, that every new customer gets.
///
/// It lives in Firestore ([path]), so it changes from the console or with
/// `make deploy-opening` without a new app version. Its source is
/// `firebase/opening-template.json`.
///
/// Pure Dart (no Flutter): the deploy tool validates the file with it before
/// publishing.
class OpeningTemplate {
  const OpeningTemplate(this.accounts);

  /// Reads the template document. Throws [FormatException] when it does not
  /// describe valid accounts: then nothing is opened, instead of writing half
  /// the data, or data the security rules would reject.
  factory OpeningTemplate.fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'] ?? 1;
    if (version is! int || version < 1) {
      throw const FormatException('"schemaVersion" must be a positive integer');
    }
    if (version > supportedSchemaVersion) {
      throw FormatException(
        'schemaVersion $version is newer than $supportedSchemaVersion',
      );
    }
    final accounts = [
      for (final (index, account) in _list(
        json,
        'accounts',
        'template',
      ).indexed)
        OpeningTemplateAccount._fromJson(account, 'accounts[$index]'),
    ];
    final ids = accounts.map((account) => account.id).toSet();
    if (ids.length != accounts.length) {
      throw const FormatException('Account ids must be unique');
    }
    return OpeningTemplate(accounts);
  }

  /// Firestore document with the template.
  static const path = 'templates/opening';

  /// Newest `schemaVersion` this app understands.
  static const supportedSchemaVersion = 1;

  final List<OpeningTemplateAccount> accounts;
}

class OpeningTemplateAccount {
  const OpeningTemplateAccount({
    required this.id,
    required this.type,
    required this.alias,
    required this.maskedNumber,
    required this.movements,
  });

  factory OpeningTemplateAccount._fromJson(Object? value, String where) {
    final json = _map(value, where);
    final id = _string(json, 'id', where);
    if (!RegExp(r'^[a-z0-9_-]{1,40}$').hasMatch(id)) {
      throw FormatException('$where: "id" must be a short lowercase id');
    }
    final typeName = _string(json, 'type', where);
    final type = AccountType.values
        .where((type) => type.name == typeName)
        .firstOrNull;
    if (type == null) {
      throw FormatException('$where: unknown type "$typeName"');
    }
    final movements = [
      for (final (index, movement) in _list(json, 'movements', where).indexed)
        OpeningTemplateMovement._fromJson(movement, '$where.movements[$index]'),
    ];
    // Same limits as the security rules (firebase/firestore.rules).
    var balance = 0;
    for (final (index, movement) in movements.indexed) {
      balance += movement.amountCents;
      if (balance < 0) {
        throw FormatException(
          '$where.movements[$index]: the balance cannot go below zero',
        );
      }
      if (index > 0 && movement.daysAgo > movements[index - 1].daysAgo) {
        throw FormatException(
          '$where.movements[$index]: movements go oldest first',
        );
      }
    }
    return OpeningTemplateAccount(
      id: id,
      type: type,
      alias: _string(json, 'alias', where, maxLength: 60),
      maskedNumber: _string(json, 'maskedNumber', where),
      movements: movements,
    );
  }

  /// Document id of the account (`savings`, `checking`...).
  final String id;
  final AccountType type;
  final String alias;
  final String maskedNumber;

  /// Oldest first.
  final List<OpeningTemplateMovement> movements;
}

class OpeningTemplateMovement {
  const OpeningTemplateMovement({
    required this.daysAgo,
    required this.amountCents,
    required this.description,
    required this.category,
  });

  factory OpeningTemplateMovement._fromJson(Object? value, String where) {
    final json = _map(value, where);
    final daysAgo = _int(json, 'daysAgo', where);
    final amountCents = _int(json, 'amountCents', where);
    if (daysAgo < 0) {
      throw FormatException('$where: "daysAgo" cannot be negative');
    }
    if (amountCents == 0) {
      throw FormatException('$where: "amountCents" cannot be zero');
    }
    return OpeningTemplateMovement(
      daysAgo: daysAgo,
      amountCents: amountCents,
      description: _string(json, 'description', where, maxLength: 140),
      category: _string(json, 'category', where),
    );
  }

  /// Days before the account opens (0 is the same day), so the dates are
  /// always recent.
  final int daysAgo;

  /// Positive for money in, negative for money out.
  final int amountCents;
  final String description;
  final String category;
}

Map<String, Object?> _map(Object? value, String where) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$where must be an object');
}

List<Object?> _list(Map<String, Object?> json, String key, String where) {
  final value = json[key];
  if (value is List<Object?> && value.isNotEmpty) return value;
  throw FormatException('$where: "$key" must be a non-empty list');
}

String _string(
  Map<String, Object?> json,
  String key,
  String where, {
  int? maxLength,
}) {
  final value = json[key];
  if (value is String &&
      value.trim().isNotEmpty &&
      (maxLength == null || value.length <= maxLength)) {
    return value;
  }
  throw FormatException(
    '$where: "$key" must be a non-empty text'
    '${maxLength == null ? '' : ' of at most $maxLength characters'}',
  );
}

/// Whole numbers; the Firestore console may store them as doubles (`5.0`).
int _int(Map<String, Object?> json, String key, String where) {
  final value = json[key];
  if (value is int) return value;
  if (value is double && value == value.roundToDouble()) return value.toInt();
  throw FormatException('$where: "$key" must be a whole number');
}
