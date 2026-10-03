import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryKeyValueStore implements KeyValueStore {
  final values = <String, Object?>{};

  @override
  T? read<T>(String key) => values[key] as T?;

  @override
  Future<void> write<T>(String key, T value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  group('LocalOnboardingRepository', () {
    test('a fresh install has not seen the onboarding', () {
      final repository = LocalOnboardingRepository(_InMemoryKeyValueStore());

      expect(repository.hasSeenOnboarding, isFalse);
    });

    test('remembers that the onboarding was seen', () async {
      final store = _InMemoryKeyValueStore();
      await LocalOnboardingRepository(store).markOnboardingSeen();

      expect(LocalOnboardingRepository(store).hasSeenOnboarding, isTrue);
    });
  });
}
