import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory dir;
  late Box<dynamic> box;
  late HiveKeyValueStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('kv_store_test');
    Hive.init(dir.path);
    box = await Hive.openBox<dynamic>('test_settings');
    store = HiveKeyValueStore(box);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  group('HiveKeyValueStore', () {
    test('returns null for a missing key', () {
      expect(store.read<bool>('onboarding_seen'), isNull);
    });

    test('writes and reads back typed values', () async {
      await store.write('onboarding_seen', true);
      await store.write('segment', 'saver');

      expect(store.read<bool>('onboarding_seen'), isTrue);
      expect(store.read<String>('segment'), 'saver');
    });

    test('persists across box reopen', () async {
      await store.write('onboarding_seen', true);
      await box.close();

      final reopened = HiveKeyValueStore(
        await Hive.openBox<dynamic>('test_settings'),
      );

      expect(reopened.read<bool>('onboarding_seen'), isTrue);
    });

    test('delete removes the value', () async {
      await store.write('onboarding_seen', true);
      await store.delete('onboarding_seen');

      expect(store.read<bool>('onboarding_seen'), isNull);
    });
  });
}
