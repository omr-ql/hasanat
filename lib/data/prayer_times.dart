import 'package:adhan/adhan.dart';

class PrayerSlot {
  const PrayerSlot({required this.name, required this.time, required this.next});

  final String name;
  final DateTime time;
  final bool next;
}

class DayPrayers {
  const DayPrayers({
    required this.slots,
    required this.nextName,
    required this.nextTime,
    required this.nextIsTomorrow,
  });

  final List<PrayerSlot> slots;
  final String nextName;
  final DateTime nextTime;
  final bool nextIsTomorrow;
}

const String prayerLatKey = 'prayer-lat';
const String prayerLngKey = 'prayer-lng';
const String prayerAlertKey = 'prayer-alert';

class PrayerMoment {
  const PrayerMoment({required this.name, required this.time});

  final String name;
  final DateTime time;
}

/// The next prayers, starting from [now], across [days] calendar days.
List<PrayerMoment> upcomingPrayers({
  required double latitude,
  required double longitude,
  required DateTime now,
  int days = 2,
}) {
  final moments = <PrayerMoment>[];
  for (var day = 0; day < days; day++) {
    final probe = DateTime(now.year, now.month, now.day + day, 12);
    final prayers = prayersFor(
      latitude: latitude,
      longitude: longitude,
      now: probe,
    );
    for (final slot in prayers.slots) {
      if (slot.time.isAfter(now)) {
        moments.add(PrayerMoment(name: slot.name, time: slot.time));
      }
    }
  }
  return moments;
}

/// Today's five prayers for [latitude] and [longitude], in the device timezone.
DayPrayers prayersFor({
  required double latitude,
  required double longitude,
  required DateTime now,
}) {
  final coordinates = Coordinates(latitude, longitude);
  final parameters = CalculationMethod.umm_al_qura.getParameters()
    ..madhab = Madhab.shafi;

  PrayerTimes on(DateTime day) {
    return PrayerTimes(
      coordinates,
      DateComponents.from(day),
      parameters,
    );
  }

  final today = on(now);
  final tomorrow = on(now.add(const Duration(days: 1)));
  final entries = <(String, DateTime)>[
    ('الفجر', today.fajr),
    ('الظهر', today.dhuhr),
    ('العصر', today.asr),
    ('المغرب', today.maghrib),
    ('العشاء', today.isha),
  ];

  var nextName = 'الفجر';
  var nextTime = tomorrow.fajr;
  var tomorrowNext = true;
  for (final entry in entries) {
    if (entry.$2.isAfter(now)) {
      nextName = entry.$1;
      nextTime = entry.$2;
      tomorrowNext = false;
      break;
    }
  }

  return DayPrayers(
    slots: [
      for (final entry in entries)
        PrayerSlot(
          name: entry.$1,
          time: entry.$2,
          next: !tomorrowNext && entry.$1 == nextName,
        ),
    ],
    nextName: nextName,
    nextTime: nextTime,
    nextIsTomorrow: tomorrowNext,
  );
}

/// Two days of prayer rows for the iPhone home-screen tile.
List<Map<String, Object>> prayerWidgetRows({
  required double latitude,
  required double longitude,
  required DateTime now,
}) {
  final rows = <Map<String, Object>>[];
  for (var day = 0; day < 2; day++) {
    final probe = DateTime(now.year, now.month, now.day + day, 12);
    final prayers = prayersFor(
      latitude: latitude,
      longitude: longitude,
      now: probe,
    );
    for (final slot in prayers.slots) {
      rows.add({
        'name': slot.name,
        'time': formatPrayerClock(slot.time),
        'at': slot.time.millisecondsSinceEpoch,
      });
    }
  }
  return rows;
}

String formatPrayerClock(DateTime time) {
  final hour24 = time.hour;
  final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = hour24 < 12 ? 'ص' : 'م';
  return '$hour:$minute $suffix';
}
