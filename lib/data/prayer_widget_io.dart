import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hasanat/data/app_settings.dart';
import 'package:hasanat/data/prayer_times.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';

const prayerWidgetGroup = 'group.com.hasanat.app.hasanat';
const prayerWidgetKind = 'PrayerWidget';
const prayerWidgetKey = 'prayer-widget';

Future<void> publishSavedPrayerWidget() async {
  if (!Hive.isBoxOpen(AppSettings.boxName)) return;
  final box = Hive.box<String>(AppSettings.boxName);
  final latitude = double.tryParse(box.get(prayerLatKey) ?? '');
  final longitude = double.tryParse(box.get(prayerLngKey) ?? '');
  if (latitude == null || longitude == null) return;
  await publishPrayerWidget(latitude: latitude, longitude: longitude);
}

Future<void> publishPrayerWidget({
  required double latitude,
  required double longitude,
}) async {
  if (defaultTargetPlatform != TargetPlatform.iOS) return;
  try {
    await HomeWidget.setAppGroupId(prayerWidgetGroup);
    final rows = prayerWidgetRows(
      latitude: latitude,
      longitude: longitude,
      now: DateTime.now(),
    );
    await HomeWidget.saveWidgetData<String>(prayerWidgetKey, jsonEncode(rows));
    await HomeWidget.updateWidget(iOSName: prayerWidgetKind);
  } catch (_) {}
}
