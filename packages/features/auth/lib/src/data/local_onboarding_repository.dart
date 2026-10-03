import 'package:auth/src/domain/repositories/onboarding_repository.dart';
import 'package:core/core.dart';

/// [OnboardingRepository] stored in the device's [KeyValueStore].
class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository(this._store);

  static const _key = 'auth.onboarding_seen';

  final KeyValueStore _store;

  @override
  bool get hasSeenOnboarding => _store.read<bool>(_key) ?? false;

  @override
  Future<void> markOnboardingSeen() => _store.write(_key, true);
}
