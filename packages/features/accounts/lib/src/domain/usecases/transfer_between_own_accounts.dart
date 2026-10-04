import 'package:accounts/src/domain/entities/transfer.dart';
import 'package:accounts/src/domain/repositories/accounts_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Moves money between two accounts of the same customer.
///
/// The rules that do not depend on fresh data are checked here, before any
/// request. Insufficient funds is checked by the repository inside the
/// Firestore transaction, against the balance at that exact moment.
class TransferBetweenOwnAccounts {
  const TransferBetweenOwnAccounts(this._repository);

  /// Demo limit per transfer: $5,000.00.
  static const maxAmountCents = 500000;
  static const maxConceptLength = 60;

  final AccountsRepository _repository;

  /// [transferId] is the idempotency key from
  /// [AccountsRepository.newTransferId]: reuse it to retry the same transfer.
  Future<Either<Failure, TransferReceipt>> call({
    required String userId,
    required String transferId,
    required String fromAccountId,
    required String toAccountId,
    required int amountCents,
    String concept = '',
  }) async {
    final error = validate(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amountCents: amountCents,
      concept: concept,
    );
    if (error != null) return Left(ValidationFailure(code: error.name));

    return _repository.transfer(
      userId: userId,
      transferId: transferId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amountCents: amountCents,
      concept: concept.trim(),
    );
  }

  /// Rules shared with the form, so the UI and the use case never disagree.
  static TransferError? validate({
    required String fromAccountId,
    required String toAccountId,
    required int amountCents,
    required String concept,
  }) {
    if (fromAccountId == toAccountId) return TransferError.sameAccount;
    if (amountCents <= 0) return TransferError.invalidAmount;
    if (amountCents > maxAmountCents) return TransferError.limitExceeded;
    if (concept.trim().length > maxConceptLength) {
      return TransferError.conceptTooLong;
    }
    return null;
  }
}
