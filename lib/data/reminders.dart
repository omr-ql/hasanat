import 'dart:convert';

import 'package:http/http.dart' as http;

const Duration kReminderSlot = Duration(minutes: 10);
const Duration kReminderCacheLife = Duration(days: 1);

const String _hadithUrl =
    'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-nawawi.min.json';
const String _hadithFallback =
    'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-nawawi.json';
const String _prayerUrl = 'https://ummahapi.com/api/duas';

const String remindersCacheKey = 'reminders-v1';
const String remindersFetchedKey = 'reminders-at';

class Quote {
  const Quote({required this.text, required this.source});

  final String text;
  final String source;

  Map<String, String> toJson() => {'t': text, 's': source};

  static Quote? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final text = (raw['t'] as String?)?.trim() ?? '';
    if (text.isEmpty) return null;
    return Quote(text: text, source: (raw['s'] as String?)?.trim() ?? '');
  }
}

class ReminderLibrary {
  const ReminderLibrary({required this.hadiths, required this.prayers});

  final List<Quote> hadiths;
  final List<Quote> prayers;

  bool get isEmpty => hadiths.isEmpty && prayers.isEmpty;

  Quote? hadithAt(DateTime now, {int shift = 0}) =>
      _pick(hadiths, now, shift: shift);

  Quote? prayerAt(DateTime now, {int shift = 0}) =>
      _pick(prayers, now, shift: shift);

  static Quote? _pick(List<Quote> items, DateTime now, {int shift = 0}) {
    if (items.isEmpty) return null;
    final slot = now.millisecondsSinceEpoch ~/ kReminderSlot.inMilliseconds;
    final index = (slot + shift) % items.length;
    return items[index < 0 ? index + items.length : index];
  }

  ReminderLibrary merge(ReminderLibrary newer) {
    return ReminderLibrary(
      hadiths: newer.hadiths.isEmpty ? hadiths : newer.hadiths,
      prayers: newer.prayers.isEmpty ? prayers : newer.prayers,
    );
  }

  String encode() {
    return jsonEncode({
      'hadiths': [for (final quote in hadiths) quote.toJson()],
      'prayers': [for (final quote in prayers) quote.toJson()],
    });
  }

  static ReminderLibrary? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      return ReminderLibrary(
        hadiths: _quotes(json['hadiths']),
        prayers: _quotes(json['prayers']),
      );
    } catch (_) {
      return null;
    }
  }
}

List<Quote> _quotes(Object? raw) {
  if (raw is! List) return const [];
  return [for (final item in raw) Quote.fromJson(item)].whereType<Quote>().toList();
}

List<Quote> parseNawawiHadiths(String body) {
  final json = jsonDecode(body);
  if (json is! Map) return const [];
  final hadiths = json['hadiths'];
  if (hadiths is! List) return const [];
  final quotes = <Quote>[];
  for (final item in hadiths) {
    if (item is! Map) continue;
    final text = (item['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) continue;
    final number = item['hadithnumber'] ?? item['arabicnumber'];
    quotes.add(Quote(text: text, source: 'الأربعون النووية · $number'));
  }
  return quotes;
}

List<Quote> parsePrayers(String body) {
  final json = jsonDecode(body);
  if (json is! Map) return const [];
  final data = json['data'];
  final duas = data is Map ? data['duas'] : null;
  if (duas is! List) return const [];
  final quotes = <Quote>[];
  for (final item in duas) {
    if (item is! Map) continue;
    final text = (item['arabic'] as String?)?.trim() ?? '';
    if (text.isEmpty) continue;
    final source = (item['source'] as String?)?.trim() ?? '';
    quotes.add(Quote(text: text, source: source));
  }
  return quotes;
}

Future<String> _get(Uri uri) async {
  final response = await http.get(uri).timeout(const Duration(seconds: 12));
  if (response.statusCode != 200) {
    throw http.ClientException('HTTP ${response.statusCode}', uri);
  }
  return response.body;
}

Future<List<Quote>> _readHadiths() async {
  try {
    return parseNawawiHadiths(await _get(Uri.parse(_hadithUrl)));
  } catch (_) {
    try {
      return parseNawawiHadiths(await _get(Uri.parse(_hadithFallback)));
    } catch (_) {
      return const [];
    }
  }
}

Future<List<Quote>> _readPrayers() async {
  try {
    return parsePrayers(await _get(Uri.parse(_prayerUrl)));
  } catch (_) {
    return const [];
  }
}

Future<ReminderLibrary> downloadReminders() async {
  final hadiths = await _readHadiths();
  final prayers = await _readPrayers();
  final library = ReminderLibrary(hadiths: hadiths, prayers: prayers);
  if (library.isEmpty) {
    throw const FormatException('empty reminder library');
  }
  return library;
}
