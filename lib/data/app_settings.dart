import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._box, this.mode);

  static const String boxName = 'settings';
  static const String _themeKey = 'theme';

  final Box<String>? _box;
  ThemeMode mode;

  bool get black => mode == ThemeMode.dark;

  factory AppSettings.light() => AppSettings._(null, ThemeMode.light);

  static Future<AppSettings> open() async {
    final box = await Hive.openBox<String>(boxName);
    final stored = box.get(_themeKey);
    return AppSettings._(
      box,
      stored == 'black' ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> toggle() async {
    mode = black ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _box?.put(_themeKey, black ? 'black' : 'light');
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
