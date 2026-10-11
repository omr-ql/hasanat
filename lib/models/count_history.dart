class PhraseRef {
  const PhraseRef({required this.id, required this.phrase});

  final String id;
  final String phrase;
}

class ChartBucket {
  const ChartBucket({
    required this.current,
    required this.previous,
    required this.label,
  });

  final int current;
  final int previous;
  final String label;
}

class ChartShare {
  const ChartShare({
    required this.id,
    required this.phrase,
    required this.count,
    required this.fraction,
  });

  final String id;
  final String phrase;
  final int count;
  final double fraction;
}

class ChartSnapshot {
  const ChartSnapshot({
    required this.buckets,
    required this.total,
    required this.previousTotal,
    required this.axisMax,
    required this.shares,
  });

  final List<ChartBucket> buckets;
  final int total;
  final int previousTotal;
  final int axisMax;
  final List<ChartShare> shares;

  /// Change against the previous window. Null when that window is empty.
  double? get changeRatio {
    if (previousTotal <= 0) return null;
    return (total - previousTotal) / previousTotal;
  }
}

enum ChartRange {
  all('الكل'),
  week('أسبوع'),
  month('شهر'),
  year('سنة');

  const ChartRange(this.label);

  final String label;
}

const List<String> kWeekdayShort = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];

const List<String> kMonthShort = [
  '',
  'ينا',
  'فبر',
  'مار',
  'أبر',
  'ماي',
  'يون',
  'يول',
  'أغس',
  'سبت',
  'أكت',
  'نوف',
  'ديس',
];

int dateKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime dateFromKey(int key) =>
    DateTime(key ~/ 10000, (key ~/ 100) % 100, key % 100);

String weekdayLabel(int weekday) => kWeekdayShort[weekday - 1];

/// Round the axis up to a multiple of 4 so the five ticks stay on whole numbers.
int chartAxisMax(int peak) {
  if (peak <= 0) return 4;
  var magnitude = 1;
  while (magnitude <= peak / 10 && magnitude < 1000000000) {
    magnitude *= 10;
  }
  for (final step in const [1, 2, 4, 5, 10]) {
    final candidate = step * magnitude;
    if (candidate >= peak && candidate % 4 == 0) return candidate;
  }
  final rounded = ((peak + 3) ~/ 4) * 4;
  return rounded < 4 ? 4 : rounded;
}

String formatAxisTick(int value) {
  final magnitude = value.abs();
  if (magnitude >= 1000000) return _scaled(value, 1000000, 'm');
  if (magnitude >= 1000) return _scaled(value, 1000, 'k');
  return '$value';
}

String formatChange(double ratio) {
  final percent = ratio.abs() * 100;
  final nearest = percent.roundToDouble();
  if (percent >= 10 || (percent - nearest).abs() < 0.05) {
    return '${percent.round()}%';
  }
  return '${percent.toStringAsFixed(1)}%';
}

String _scaled(int value, int unit, String suffix) {
  final scaled = value / unit;
  final nearest = scaled.roundToDouble();
  final text = scaled >= 10 || (scaled - nearest).abs() < 0.05
      ? '${scaled.round()}'
      : scaled.toStringAsFixed(1);
  return '$text$suffix';
}

class CountHistory {
  CountHistory();

  final Map<int, Map<String, int>> _days = {};

  bool get isEmpty {
    for (final day in _days.values) {
      if (day.isNotEmpty) return false;
    }
    return true;
  }

  int? get earliestDay {
    if (_days.isEmpty) return null;
    var earliest = _days.keys.first;
    for (final day in _days.keys) {
      if (day < earliest) earliest = day;
    }
    return earliest;
  }

  void add(String id, int day, int amount) {
    if (amount == 0) return;
    final bucket = _days.putIfAbsent(day, () => {});
    final next = (bucket[id] ?? 0) + amount;
    if (next <= 0) {
      bucket.remove(id);
      if (bucket.isEmpty) _days.remove(day);
    } else {
      bucket[id] = next;
    }
  }

  /// Removes the latest tap for [id]. Returns the day that changed.
  int? undo(String id) {
    final keys = _days.keys.toList()..sort();
    for (final day in keys.reversed) {
      final count = _days[day]?[id] ?? 0;
      if (count > 0) {
        add(id, day, -1);
        return day;
      }
    }
    return null;
  }

  List<int> clearId(String id) {
    final touched = <int>[];
    for (final day in _days.keys.toList()) {
      if (_days[day]?.containsKey(id) ?? false) {
        touched.add(day);
        _days[day]!.remove(id);
        if (_days[day]!.isEmpty) _days.remove(day);
      }
    }
    return touched;
  }

  Map<String, int> countsOn(int day) {
    final bucket = _days[day];
    if (bucket == null || bucket.isEmpty) return const {};
    return Map<String, int>.from(bucket);
  }

  int totalOn(int day, {String? id}) {
    final bucket = _days[day];
    if (bucket == null) return 0;
    if (id == null) {
      var sum = 0;
      for (final value in bucket.values) {
        sum += value;
      }
      return sum;
    }
    return bucket[id] ?? 0;
  }

  int totalBetween(int from, int to, {String? id}) {
    var sum = 0;
    for (final entry in _days.entries) {
      if (entry.key < from || entry.key > to) continue;
      if (id == null) {
        for (final value in entry.value.values) {
          sum += value;
        }
      } else {
        sum += entry.value[id] ?? 0;
      }
    }
    return sum;
  }

  factory CountHistory.fromRaw(Map<dynamic, dynamic> raw) {
    final history = CountHistory();
    for (final entry in raw.entries) {
      final day = int.tryParse('${entry.key}');
      if (day == null) continue;
      final counts = decodeDay('${entry.value}');
      if (counts.isEmpty) continue;
      history._days[day] = counts;
    }
    return history;
  }
}

String encodeDay(Map<String, int> counts) {
  return counts.entries.map((entry) => '${entry.key}=${entry.value}').join('|');
}

Map<String, int> decodeDay(String raw) {
  final counts = <String, int>{};
  if (raw.isEmpty) return counts;
  for (final part in raw.split('|')) {
    final split = part.split('=');
    if (split.length != 2) continue;
    final value = int.tryParse(split[1]);
    if (value == null || value <= 0 || split[0].isEmpty) continue;
    counts[split[0]] = value;
  }
  return counts;
}

ChartSnapshot buildChart({
  required CountHistory history,
  required ChartRange range,
  required DateTime now,
  required List<PhraseRef> phrases,
}) {
  final today = dateOnly(now);
  final window = _window(history, range, today);
  final buckets = _buckets(history, range, today, window);
  final total = buckets.fold<int>(0, (sum, bucket) => sum + bucket.current);
  final previousTotal = buckets.fold<int>(
    0,
    (sum, bucket) => sum + bucket.previous,
  );
  final peak = buckets.fold<int>(0, (peak, bucket) {
    final higher = bucket.current > bucket.previous
        ? bucket.current
        : bucket.previous;
    return higher > peak ? higher : peak;
  });
  return ChartSnapshot(
    buckets: buckets,
    total: total,
    previousTotal: previousTotal,
    axisMax: chartAxisMax(peak),
    shares: _shares(history, window.start, window.end, phrases),
  );
}

class _Window {
  const _Window(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

_Window _window(CountHistory history, ChartRange range, DateTime today) {
  switch (range) {
    case ChartRange.week:
      return _Window(today.subtract(const Duration(days: 6)), today);
    case ChartRange.month:
      return _Window(DateTime(today.year, today.month, 1), today);
    case ChartRange.year:
      return _Window(DateTime(today.year, 1, 1), today);
    case ChartRange.all:
      final earliest = history.earliestDay;
      if (earliest == null) {
        return _Window(today.subtract(const Duration(days: 6)), today);
      }
      final start = dateFromKey(earliest);
      if (today.difference(start).inDays < 6) {
        return _Window(today.subtract(const Duration(days: 6)), today);
      }
      return _Window(start, today);
  }
}

List<ChartBucket> _buckets(
  CountHistory history,
  ChartRange range,
  DateTime today,
  _Window window,
) {
  switch (range) {
    case ChartRange.week:
      return _dailyBuckets(history, window.start, today, previousDays: 7);
    case ChartRange.month:
      return _dailyBuckets(history, window.start, today, previousMonth: true);
    case ChartRange.year:
      return _yearBuckets(history, today);
    case ChartRange.all:
      final span = window.end.difference(window.start).inDays + 1;
      if (span <= 7) {
        return _dailyBuckets(history, window.start, today, previousDays: span);
      }
      return _spanBuckets(history, window);
  }
}

List<ChartBucket> _dailyBuckets(
  CountHistory history,
  DateTime start,
  DateTime end, {
  int? previousDays,
  bool previousMonth = false,
}) {
  final buckets = <ChartBucket>[];
  for (
    var day = start;
    !day.isAfter(end);
    day = day.add(const Duration(days: 1))
  ) {
    final current = history.totalOn(dateKey(day));
    var previous = 0;
    if (previousMonth) {
      final prior = DateTime(day.year, day.month - 1, 1);
      final maxDay = DateTime(prior.year, prior.month + 1, 0).day;
      if (day.day <= maxDay) {
        previous = history.totalOn(
          dateKey(DateTime(prior.year, prior.month, day.day)),
        );
      }
    } else if (previousDays != null) {
      previous = history.totalOn(
        dateKey(day.subtract(Duration(days: previousDays))),
      );
    }
    final showDay = previousMonth
        ? day.day == 1 || (day.day - 1) % 7 == 0
        : true;
    buckets.add(
      ChartBucket(
        current: current,
        previous: previous,
        label: showDay
            ? (previousMonth ? '${day.day}' : weekdayLabel(day.weekday))
            : '',
      ),
    );
  }
  return buckets;
}

List<ChartBucket> _yearBuckets(CountHistory history, DateTime today) {
  final buckets = <ChartBucket>[];
  var cursor = DateTime(today.year, 1, 1);
  var labeledMonth = 0;
  while (!cursor.isAfter(today)) {
    final weekEnd = cursor.add(const Duration(days: 6));
    final end = weekEnd.isAfter(today) ? today : weekEnd;
    final previousStart = _sameDayLastYear(cursor);
    final previousEnd = _sameDayLastYear(end);
    final label = cursor.month == labeledMonth ? '' : kMonthShort[cursor.month];
    if (label.isNotEmpty) labeledMonth = cursor.month;
    buckets.add(
      ChartBucket(
        current: history.totalBetween(dateKey(cursor), dateKey(end)),
        previous: history.totalBetween(
          dateKey(previousStart),
          dateKey(previousEnd),
        ),
        label: label,
      ),
    );
    cursor = cursor.add(const Duration(days: 7));
  }
  return buckets;
}

List<ChartBucket> _spanBuckets(CountHistory history, _Window window) {
  final span = window.end.difference(window.start).inDays + 1;
  final count = span > 28 ? 24 : span;
  final size = (span / count).ceil();
  final previousOrigin = window.start.subtract(Duration(days: span));
  final buckets = <ChartBucket>[];
  var labeledMonth = 0;
  var index = 0;
  while (index < count) {
    final start = window.start.add(Duration(days: index * size));
    if (start.isAfter(window.end)) break;
    final rawEnd = start.add(Duration(days: size - 1));
    final end = rawEnd.isAfter(window.end) ? window.end : rawEnd;
    final offset = start.difference(window.start).inDays;
    final length = end.difference(start).inDays;
    final previousStart = previousOrigin.add(Duration(days: offset));
    final previousEnd = previousStart.add(Duration(days: length));
    final label = start.month == labeledMonth ? '' : kMonthShort[start.month];
    if (label.isNotEmpty) labeledMonth = start.month;
    buckets.add(
      ChartBucket(
        current: history.totalBetween(dateKey(start), dateKey(end)),
        previous: history.totalBetween(
          dateKey(previousStart),
          dateKey(previousEnd),
        ),
        label: label,
      ),
    );
    index += 1;
  }
  return buckets;
}

DateTime _sameDayLastYear(DateTime date) {
  final maxDay = DateTime(date.year - 1, date.month + 1, 0).day;
  final day = date.day > maxDay ? maxDay : date.day;
  return DateTime(date.year - 1, date.month, day);
}

List<ChartShare> _shares(
  CountHistory history,
  DateTime start,
  DateTime end,
  List<PhraseRef> phrases,
) {
  final from = dateKey(start);
  final to = dateKey(end);
  final shares = <ChartShare>[];
  var total = 0;
  final counts = <String, int>{};
  for (final phrase in phrases) {
    final count = history.totalBetween(from, to, id: phrase.id);
    counts[phrase.id] = count;
    total += count;
  }
  for (final phrase in phrases) {
    final count = counts[phrase.id] ?? 0;
    if (count <= 0) continue;
    shares.add(
      ChartShare(
        id: phrase.id,
        phrase: phrase.phrase,
        count: count,
        fraction: total == 0 ? 0 : count / total,
      ),
    );
  }
  shares.sort((a, b) => b.count.compareTo(a.count));
  return shares;
}
