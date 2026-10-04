import 'dart:async';

import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_rates/src/domain/fx_rates.dart';

sealed class FxState extends Equatable {
  const FxState();

  @override
  List<Object?> get props => [];
}

final class FxLoading extends FxState {
  const FxLoading();
}

final class FxLoaded extends FxState {
  const FxLoaded(this.snapshot);

  final FxSnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}

/// No rates at all: nothing saved and the provider could not answer.
final class FxError extends FxState {
  const FxError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Exchange rates on screen, with stale-while-revalidate from the
/// repository: saved rates first, fresh ones when due.
class FxCubit extends Cubit<FxState> {
  FxCubit(this.repository) : super(const FxLoading()) {
    unawaited(_listen(forceRefresh: false));
  }

  final FxRatesRepository repository;
  StreamSubscription<void>? _subscription;
  Completer<void>? _done;

  /// Asks the provider now (pull to refresh). Completes when it answers.
  Future<void> refresh() => _listen(forceRefresh: true);

  /// After an error: back to loading and asks the provider again.
  Future<void> retry() {
    emit(const FxLoading());
    return _listen(forceRefresh: true);
  }

  Future<void> _listen({required bool forceRefresh}) {
    _finish();
    final done = _done = Completer<void>();
    _subscription = repository.watchRates(forceRefresh: forceRefresh).listen((
      result,
    ) {
      if (!isClosed) emit(result.match(FxError.new, FxLoaded.new));
    }, onDone: _finish);
    return done.future;
  }

  /// Stops the current request and completes whoever awaits it.
  void _finish() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    final done = _done;
    _done = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  @override
  Future<void> close() {
    _finish();
    return super.close();
  }
}
