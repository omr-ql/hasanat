import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hasanat/data/dhikr_store.dart';
import 'package:hasanat/models/dhikr.dart';
import 'package:hive_ce/hive.dart';

void main() {
  group('Dhikr', () {
    Dhikr sample() {
      return Dhikr(
        id: 'x',
        phrase: 'اختبار',
        isPreset: false,
        createdAt: 1,
        target: 33,
      );
    }

    test('finishes a round at the target, then starts the next at 1', () {
      final dhikr = sample();
      for (var tap = 0; tap < 32; tap++) {
        expect(dhikr.increment(), isFalse);
      }
      expect(dhikr.count, 32);
      expect(dhikr.increment(), isTrue);
      expect(dhikr.count, 33);
      expect(dhikr.rounds, 1);
      expect(dhikr.total, 33);
      expect(dhikr.roundComplete, isTrue);

      expect(dhikr.increment(), isFalse);
      expect(dhikr.count, 1);
      expect(dhikr.rounds, 1);
      expect(dhikr.total, 34);
      expect(dhikr.roundComplete, isFalse);
    });

    test('a target of 1 completes on every tap', () {
      final dhikr = sample()..setTarget(1);
      expect(dhikr.increment(), isTrue);
      expect(dhikr.increment(), isTrue);
      expect(dhikr.rounds, 2);
      expect(dhikr.count, 1);
      expect(dhikr.total, 2);
    });

    test('undo steps back from a completed target', () {
      final dhikr = sample()..setTarget(3);
      dhikr.increment();
      dhikr.increment();
      expect(dhikr.increment(), isTrue);
      expect(dhikr.decrement(), isTrue);
      expect(dhikr.count, 2);
      expect(dhikr.rounds, 0);
      expect(dhikr.total, 2);
      expect(dhikr.decrement(), isTrue);
      expect(dhikr.decrement(), isTrue);
      expect(dhikr.decrement(), isFalse);
      expect(dhikr.count, 0);
      expect(dhikr.total, 0);
    });

    test('reset round keeps the lifetime total', () {
      final dhikr = sample();
      dhikr.increment();
      dhikr.increment();
      dhikr.resetRound();
      expect(dhikr.count, 0);
      expect(dhikr.total, 2);
      dhikr.resetAll();
      expect(dhikr.total, 0);
      expect(dhikr.rounds, 0);
    });

    test('target is clamped and the current count cannot pass it', () {
      final dhikr = sample()..count = 40;
      dhikr.setTarget(0);
      expect(dhikr.target, 1);
      expect(dhikr.count, 1);
      dhikr.setTarget(10000);
      expect(dhikr.target, kMaxTarget);
    });

    test('preset names stay fixed', () {
      final dhikr = Dhikr(
        id: 'istighfar',
        phrase: 'استغفر الله',
        isPreset: true,
        createdAt: 1,
      );
      dhikr.rename('شيء آخر');
      expect(dhikr.phrase, 'استغفر الله');
    });
  });

  group('DhikrStore', () {
    late Directory directory;
    late DhikrStore store;

    setUp(() async {
      directory = Directory.systemTemp.createTempSync('hasanat_');
      store = await DhikrStore.openInDirectory(directory.path);
    });

    tearDown(() async {
      await Hive.close();
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    test('seeds the adhkar in order', () {
      expect(store.presets.map((item) => item.phrase).toList(), [
        'استغفر الله',
        'الحمد لله',
        'سبحان الله',
        'الله أكبر',
        'الصلاة على النبي',
      ]);
      expect(store.custom, isEmpty);
    });

    test('keeps a custom phrase and its count after a restart', () async {
      final created = await store.createCustom(phrase: '  لا إله إلا الله  ');
      expect(created.phrase, 'لا إله إلا الله');
      expect(created.target, 33);
      created.increment();
      await store.save(created);

      await Hive.close();
      final reopened = await DhikrStore.openInDirectory(directory.path);
      final restored = reopened.custom.single;
      expect(restored.phrase, 'لا إله إلا الله');
      expect(restored.count, 1);
      expect(restored.total, 1);
      expect(reopened.presets, hasLength(5));
    });

    test('refuses to delete a preset and drops a custom phrase', () async {
      final created = await store.createCustom(
        phrase: 'حسبي الله',
        target: 100,
      );
      expect(created.target, 100);
      await store.delete('istighfar');
      expect(store.find('istighfar'), isNotNull);
      await store.delete(created.id);
      expect(store.find(created.id), isNull);
    });

    test('rejects an empty phrase', () async {
      await expectLater(store.createCustom(phrase: '   '), throwsArgumentError);
    });
  });
}
