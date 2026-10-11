import 'package:flutter/material.dart';
import 'package:hasanat/models/salah_tasbih.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._box, this.mode, this.salah);

  static const String boxName = 'settings';
  static const String _themeKey = 'theme';
  static const String _salahStep = 'salah-step';
  static const String _salahCount = 'salah-count';
  static const String _salahDone = 'salah-done';

  final Box<String>? _box;
  ThemeMode mode;
  SalahProgress salah;

  bool get black => mode == ThemeMode.dark;

  factory AppSettings.light() =>
      AppSettings._(null, ThemeMode.light, const SalahProgress());

  static Future<AppSettings> open() async {
    final box = await Hive.openBox<String>(boxName);
    final stored = box.get(_themeKey);
    return AppSettings._(
      box,
      stored == 'black' ? ThemeMode.dark : ThemeMode.light,
      _readSalah(box),
    );
  }

  static SalahProgress _readSalah(Box<String> box) {
    final step = int.tryParse(box.get(_salahStep) ?? '') ?? 0;
    final count = int.tryParse(box.get(_salahCount) ?? '') ?? 0;
    return SalahProgress(
      step: step.clamp(0, kSalahTasbih.length - 1),
      count: count < 0 ? 0 : count,
      finished: box.get(_salahDone) == '1',
    );
  }

  Future<void> toggle() async {
    mode = black ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _box?.put(_themeKey, black ? 'black' : 'light');
  }

  Future<void> saveSalah(SalahProgress next) async {
    salah = next;
    notifyListeners();
    final box = _box;
    if (box == null) return;
    await box.put(_salahStep, '${next.step}');
    await box.put(_salahCount, '${next.count}');
    await box.put(_salahDone, next.finished ? '1' : '0');
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    final settings = scope?.notifier;
    assert(settings != null, 'SettingsScope is missing');
    return settings!;
  }
}
