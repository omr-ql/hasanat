import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hasanat/models/dhikr.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class DhikrStore extends ChangeNotifier {
  DhikrStore._(this._box);

  static const String boxName = 'dhikr';

  final Box<Dhikr> _box;
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
    if (!Hive.isAdapterRegistered(DhikrAdapter.typeIdConst)) {
      Hive.registerAdapter(const DhikrAdapter());
    }
    final box = await Hive.openBox<Dhikr>(boxName, bytes: Uint8List(0));
    final store = DhikrStore._(box);
    await store._ensurePresets();
    return store;
  }

  static Future<DhikrStore> _openBox() async {
    if (!Hive.isAdapterRegistered(DhikrAdapter.typeIdConst)) {
      Hive.registerAdapter(const DhikrAdapter());
    }
    final box = await Hive.openBox<Dhikr>(boxName);
    final store = DhikrStore._(box);
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

  Dhikr? find(String id) => _box.get(id);

  Future<void> save(Dhikr dhikr) async {
    notifyListeners();
    await _box.put(dhikr.id, dhikr);
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
    await _box.delete(id);
    notifyListeners();
  }

  Future<void> _ensurePresets() async {
    for (final preset in kPresets) {
      final current = _box.get(preset.id);
      if (current == null) {
        await _box.put(
          preset.id,
          Dhikr(
            id: preset.id,
            phrase: preset.phrase,
            isPreset: true,
            createdAt: preset.createdAt,
          ),
        );
      } else if (current.phrase != preset.phrase) {
        current.phrase = preset.phrase;
        await _box.put(current.id, current);
      }
    }
  }
}
