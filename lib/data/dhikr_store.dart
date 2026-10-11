import 'package:flutter/foundation.dart';
import 'package:hasanat/models/count_history.dart';
import 'package:hasanat/models/dhikr.dart';
import 'package:hasanat/models/salah_tasbih.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class DhikrStore extends ChangeNotifier {
  DhikrStore._(this._box, this._log, this.history);

  static const String boxName = 'dhikr';
  static const String logName = 'count_log';

  final Box<Dhikr> _box;
  final Box<String> _log;
  final CountHistory history;
  int _sequence = 0;

  static Future<DhikrStore> open() async {
    await Hive.initFlutter();
    return _openBox();
  }

  @visibleForTesting
  static Future<DhikrStore> openInDirectory(String path) async {
    Hive.init(path);
    return _openBox();
  }

  @visibleForTesting
  static Future<DhikrStore> openInMemory() async {
    _registerAdapter();
    final box = await Hive.openBox<Dhikr>(boxName, bytes: Uint8List(0));
    final log = await Hive.openBox<String>(logName, bytes: Uint8List(0));
    return _fromBoxes(box, log);
  }

  static Future<DhikrStore> _openBox() async {
    _registerAdapter();
    final box = await Hive.openBox<Dhikr>(boxName);
    final log = await Hive.openBox<String>(logName);
    return _fromBoxes(box, log);
  }

  static void _registerAdapter() {
    if (!Hive.isAdapterRegistered(DhikrAdapter.typeIdConst)) {
      Hive.registerAdapter(const DhikrAdapter());
    }
  }

  static Future<DhikrStore> _fromBoxes(Box<Dhikr> box, Box<String> log) async {
    final store = DhikrStore._(box, log, CountHistory.fromRaw(log.toMap()));
    await store._ensurePresets();
    return store;
  }

  List<Dhikr> get presets => [
    for (final preset in kPresets)
      if (_box.get(preset.id) case final Dhikr dhikr) dhikr,
  ];

  List<Dhikr> get custom {
    final items = _box.values.where((item) => !item.isPreset).toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  /// Every saved dhikr, including phrases that only appear after the prayer.
  List<Dhikr> get recorded {
    final items = _box.values.toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  Dhikr? find(String id) => _box.get(id);

  Future<void> save(Dhikr dhikr) async {
    notifyListeners();
    await _box.put(dhikr.id, dhikr);
  }

  Future<bool> increment(Dhikr dhikr, {DateTime? at}) async {
    final finished = dhikr.increment();
    final day = dateKey(at ?? DateTime.now());
    history.add(dhikr.id, day, 1);
    notifyListeners();
    await _box.put(dhikr.id, dhikr);
    await _writeDay(day);
    return finished;
  }

  Future<bool> decrement(Dhikr dhikr) async {
    if (!dhikr.decrement()) return false;
    final day = history.undo(dhikr.id);
    notifyListeners();
    await _box.put(dhikr.id, dhikr);
    if (day != null) await _writeDay(day);
    return true;
  }

  Future<void> resetAll(Dhikr dhikr) async {
    dhikr.resetAll();
    final days = history.clearId(dhikr.id);
    notifyListeners();
    await _box.put(dhikr.id, dhikr);
    for (final day in days) {
      await _writeDay(day);
    }
  }

  Future<Dhikr> createCustom({
    required String phrase,
    int target = kDefaultTarget,
  }) async {
    final text = phrase.trim();
    if (text.isEmpty || text.length > kMaxPhraseLength) {
      throw ArgumentError.value(phrase, 'phrase');
    }
    final dhikr = Dhikr(
      id: 'c${DateTime.now().microsecondsSinceEpoch}${_sequence++}',
      phrase: text,
      isPreset: false,
      target: target.clamp(1, kMaxTarget),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _box.put(dhikr.id, dhikr);
    notifyListeners();
    return dhikr;
  }

  Future<void> delete(String id) async {
    final current = _box.get(id);
    if (current == null || current.isPreset) return;
    final days = history.clearId(id);
    notifyListeners();
    await _box.delete(id);
    for (final day in days) {
      await _writeDay(day);
    }
  }

  Future<void> _writeDay(int day) async {
    final counts = history.countsOn(day);
    if (counts.isEmpty) {
      await _log.delete('$day');
    } else {
      await _log.put('$day', encodeDay(counts));
    }
  }

  Future<void> _ensurePresets() async {
    await _ensureList(kPresets);
    await _ensureList(kSalahStored);
  }

  Future<void> _ensureList(List<PresetDhikr> presets) async {
    for (final preset in presets) {
      final current = _box.get(preset.id);
      if (current == null) {
        await _box.put(
          preset.id,
          Dhikr(
            id: preset.id,
            phrase: preset.phrase,
            isPreset: true,
            createdAt: preset.createdAt,
            target: preset.target,
          ),
        );
      } else if (current.phrase != preset.phrase) {
        current.phrase = preset.phrase;
        await _box.put(current.id, current);
      }
    }
  }
}
