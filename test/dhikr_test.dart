import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hasanat/data/app_settings.dart';
import 'package:hasanat/data/dhikr_store.dart';
import 'package:hasanat/data/prayer_times.dart';
import 'package:hasanat/data/reminders.dart';
import 'package:hasanat/models/count_history.dart';
import 'package:hasanat/models/dhikr.dart';
import 'package:hasanat/models/salah_tasbih.dart';
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

    test('undo steps back into a finished round', () {
      final dhikr = sample()..setTarget(3);
      dhikr.increment();
      dhikr.increment();
      dhikr.increment();
      dhikr.increment();
      expect(dhikr.count, 1);
      expect(dhikr.rounds, 1);
      expect(dhikr.total, 4);

      expect(dhikr.decrement(), isTrue);
      expect(dhikr.count, 3);
      expect(dhikr.rounds, 1);
      expect(dhikr.total, 3);
      expect(dhikr.roundComplete, isTrue);

      expect(dhikr.decrement(), isTrue);
      expect(dhikr.count, 2);
      expect(dhikr.rounds, 0);
      expect(dhikr.total, 2);
    });

    test('a target of 1 undoes one completed tap at a time', () {
      final dhikr = sample()..setTarget(1);
      dhikr.increment();
      dhikr.increment();
      expect(dhikr.decrement(), isTrue);
      expect(dhikr.count, 1);
      expect(dhikr.rounds, 1);
      expect(dhikr.total, 1);
      expect(dhikr.decrement(), isTrue);
      expect(dhikr.count, 0);
      expect(dhikr.rounds, 0);
      expect(dhikr.total, 0);
      expect(dhikr.decrement(), isFalse);
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
      expect(store.find('salam')?.target, 1);
      expect(store.find('tahlil'), isNotNull);
      expect(store.presets, hasLength(5));
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

    test('remembers black mode', () async {
      final settings = await AppSettings.open();
      expect(settings.black, isFalse);
      await settings.toggle();
      expect(settings.black, isTrue);

      await Hive.close();
      Hive.init(directory.path);
      final restored = await AppSettings.open();
      expect(restored.mode, ThemeMode.dark);
    });

    test('rejects an empty phrase', () async {
      await expectLater(store.createCustom(phrase: '   '), throwsArgumentError);
    });

    test('keeps daily taps for the chart and drops them on reset', () async {
      final created = await store.createCustom(phrase: 'سبحان الله وبحمده');
      await store.increment(created, at: DateTime(2026, 10, 4));
      await store.increment(created, at: DateTime(2026, 10, 11));
      await store.increment(created, at: DateTime(2026, 10, 11));

      await Hive.close();
      final reopened = await DhikrStore.openInDirectory(directory.path);
      final restored = reopened.custom.single;
      final chart = buildChart(
        history: reopened.history,
        range: ChartRange.week,
        now: DateTime(2026, 10, 11),
        phrases: [PhraseRef(id: restored.id, phrase: restored.phrase)],
      );
      expect(chart.total, 2);
      expect(chart.previousTotal, 1);
      expect(formatChange(chart.changeRatio!), '100%');

      await reopened.resetAll(restored);
      final cleared = buildChart(
        history: reopened.history,
        range: ChartRange.week,
        now: DateTime(2026, 10, 11),
        phrases: [PhraseRef(id: restored.id, phrase: restored.phrase)],
      );
      expect(cleared.total, 0);
      expect(restored.total, 0);
    });
  });

  group('chart', () {
    test('draws this week against the week before', () {
      final history = CountHistory();
      history.add('istighfar', dateKey(DateTime(2026, 10, 11)), 43);
      history.add('istighfar', dateKey(DateTime(2026, 10, 4)), 40);
      final chart = buildChart(
        history: history,
        range: ChartRange.week,
        now: DateTime(2026, 10, 11),
        phrases: const [PhraseRef(id: 'istighfar', phrase: 'استغفر الله')],
      );

      expect(chart.buckets, hasLength(7));
      expect(chart.total, 43);
      expect(chart.previousTotal, 40);
      expect(chart.changeRatio, closeTo(0.075, 0.0001));
      expect(formatChange(chart.changeRatio!), '7.5%');
      expect(chart.axisMax, 100);
      expect(formatAxisTick(chart.axisMax), '100');
      expect(formatAxisTick(100000), '100k');
      expect(
        chart.buckets.last.label,
        weekdayLabel(DateTime(2026, 10, 11).weekday),
      );
      expect(chart.shares.single.count, 43);
      expect(chart.shares.single.fraction, 1);
    });

    test('labels the year by month through today', () {
      final history = CountHistory();
      history.add('hamd', dateKey(DateTime(2026, 1, 3)), 10);
      history.add('hamd', dateKey(DateTime(2026, 10, 2)), 4);
      final chart = buildChart(
        history: history,
        range: ChartRange.year,
        now: DateTime(2026, 10, 11),
        phrases: const [PhraseRef(id: 'hamd', phrase: 'الحمد لله')],
      );

      expect(chart.buckets.first.label, 'Jan');
      expect(
        chart.buckets.map((bucket) => bucket.label),
        contains('Oct'),
      );
      expect(chart.total, 14);
      expect(chart.buckets.any((bucket) => bucket.current == 4), isTrue);
    });

    test('undo removes the latest day first', () {
      final history = CountHistory();
      history.add('a', dateKey(DateTime(2026, 10, 10)), 2);
      history.add('a', dateKey(DateTime(2026, 10, 11)), 1);
      expect(history.undo('a'), dateKey(DateTime(2026, 10, 11)));
      expect(history.totalOn(dateKey(DateTime(2026, 10, 11))), 0);
      expect(history.totalOn(dateKey(DateTime(2026, 10, 10))), 2);
    });
  });

  group('after the prayer', () {
    test('three istighfar lead into the salam, then the tasbih', () {
      var progress = const SalahProgress();
      expect(progress.current.phrase, 'أستغفر الله');
      for (var i = 0; i < 3; i++) {
        progress = progress.tap();
      }
      expect(progress.current.id, 'salam');
      expect(progress.count, 0);
      progress = progress.tap();
      expect(progress.current.id, 'subhan');
      expect(progress.current.target, 33);
    });

    test('the last phrase finishes the hundred and undo steps back', () {
      var progress = const SalahProgress();
      while (!progress.finished) {
        progress = progress.tap();
      }
      expect(progress.current.id, 'tahlil');
      expect(progress.undoId, 'tahlil');
      progress = progress.undo();
      expect(progress.finished, isFalse);
      expect(progress.current.id, 'tahlil');
      expect(progress.count, 0);
    });
  });

  group('reminders', () {
    test('reads a hadith and a prayer, then moves on after ten minutes', () {
      final hadiths = parseNawawiHadiths(
        '{"hadiths":[{"hadithnumber":1,"text":" إنما الأعمال بالنيات "}]}',
      );
      final prayers = parsePrayers(
        '{"data":{"duas":[{"arabic":" رب اغفر لي ","source":"مسلم"}]}}',
      );
      expect(hadiths.single.text, 'إنما الأعمال بالنيات');
      expect(hadiths.single.source, 'الأربعون النووية · 1');
      expect(prayers.single.text, 'رب اغفر لي');

      final library = ReminderLibrary(
        hadiths: [
          const Quote(text: 'الأول', source: '١'),
          const Quote(text: 'الثاني', source: '٢'),
        ],
        prayers: prayers,
      );
      final first = DateTime.fromMillisecondsSinceEpoch(0);
      final next = first.add(kReminderSlot);
      expect(library.hadithAt(first)!.text, 'الأول');
      expect(library.hadithAt(first, shift: 1)!.text, 'الثاني');
      expect(library.hadithAt(next)!.text, 'الثاني');
      expect(library.prayerAt(first)!.source, 'مسلم');
      expect(ReminderLibrary.decode(library.encode())!.hadiths, hasLength(2));
    });
  });

  group('prayer times', () {
    test('keeps the five prayers in order and formats the clock', () {
      final noon = DateTime(2026, 10, 11, 12);
      final day = prayersFor(latitude: 21.4225, longitude: 39.8262, now: noon);
      expect(
        day.slots.map((slot) => slot.name).toList(),
        ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'],
      );
      for (var i = 0; i < day.slots.length - 1; i++) {
        expect(day.slots[i].time.isBefore(day.slots[i + 1].time), isTrue);
      }
      expect(day.slots.where((slot) => slot.next), hasLength(1));
      expect(formatPrayerClock(DateTime(2026, 10, 11, 5, 7)), '5:07 ص');
      expect(formatPrayerClock(DateTime(2026, 10, 11, 18, 3)), '6:03 م');

      final afterIsha = day.slots.last.time.add(const Duration(minutes: 1));
      final later = prayersFor(
        latitude: 21.4225,
        longitude: 39.8262,
        now: afterIsha,
      );
      expect(later.nextIsTomorrow, isTrue);
      expect(later.nextName, 'الفجر');

      final upcoming = upcomingPrayers(
        latitude: 21.4225,
        longitude: 39.8262,
        now: noon,
      );
      expect(upcoming, isNotEmpty);
      expect(upcoming.first.time.isAfter(noon), isTrue);
      expect(upcoming.length, lessThanOrEqualTo(10));

      final rows = prayerWidgetRows(
        latitude: 21.4225,
        longitude: 39.8262,
        now: noon,
      );
      expect(rows, hasLength(10));
      expect(rows.first['name'], 'الفجر');
      expect(rows[5]['name'], 'الفجر');
    });
  });
}
