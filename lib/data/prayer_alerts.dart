import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hasanat/data/app_settings.dart';
import 'package:hasanat/data/prayer_times.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class PrayerAlerts {
  PrayerAlerts._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static var _ready = false;
  static Timer? _webTimer;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer',
      'مواقيت الصلاة',
      channelDescription: 'تنبيه عند دخول وقت الصلاة',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
    ),
    web: WebNotificationDetails(
      direction: WebNotificationDirection.rightToLeft,
    ),
  );

  static bool get enabled {
    if (!Hive.isBoxOpen(AppSettings.boxName)) return false;
    return Hive.box<String>(AppSettings.boxName).get(prayerAlertKey) == '1';
  }

  static Future<bool> enable({
    required double latitude,
    required double longitude,
  }) async {
    final ok = await _prepare(ask: true);
    if (!ok) return false;
    await _save(true);
    await sync(latitude: latitude, longitude: longitude);
    await _show(id: 900, title: 'تنبيه الصلاة', body: 'سيصلك عند كل صلاة');
    return true;
  }

  static Future<void> disable() async {
    _webTimer?.cancel();
    _webTimer = null;
    await _save(false);
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Reschedules saved alerts without asking for permission again.
  static Future<void> restore() async {
    if (!enabled) return;
    final place = _savedPlace();
    if (place == null) return;
    final ok = await _prepare(ask: false);
    if (!ok) return;
    await sync(latitude: place.$1, longitude: place.$2);
  }

  static Future<void> sync({
    required double latitude,
    required double longitude,
  }) async {
    if (!enabled || !_ready) return;
    _webTimer?.cancel();
    final upcoming = upcomingPrayers(
      latitude: latitude,
      longitude: longitude,
      now: DateTime.now(),
    );
    if (kIsWeb) {
      _armWeb(upcoming, latitude, longitude);
      return;
    }
    try {
      await _plugin.cancelAll();
      var id = 1;
      for (final moment in upcoming) {
        await _plugin.zonedSchedule(
          id: id,
          title: 'حان وقت ${moment.name}',
          body: 'حي على الصلاة',
          scheduledDate: tz.TZDateTime.from(moment.time, tz.local),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        id += 1;
      }
    } catch (_) {}
  }

  static void _armWeb(
    List<PrayerMoment> upcoming,
    double latitude,
    double longitude,
  ) {
    if (upcoming.isEmpty) return;
    final next = upcoming.first;
    var delay = next.time.difference(DateTime.now());
    if (delay.isNegative) delay = Duration.zero;
    _webTimer = Timer(delay, () async {
      await _show(id: 1, title: 'حان وقت ${next.name}', body: 'حي على الصلاة');
      await sync(latitude: latitude, longitude: longitude);
    });
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (_) {}
  }

  static Future<bool> _prepare({required bool ask}) async {
    if (!_ready) {
      await _setZone();
      try {
        final initialized = await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
        );
        if (initialized == false) return false;
      } catch (_) {
        return false;
      }
      _ready = true;
    }

    if (kIsWeb) {
      final web = _plugin
          .resolvePlatformSpecificImplementation<
            WebFlutterLocalNotificationsPlugin
          >();
      if (web == null) return false;
      if (web.permissionStatus == WebNotificationPermission.granted) {
        return true;
      }
      if (!ask) return false;
      final granted = await web.requestNotificationsPermission();
      return granted ?? false;
    }

    if (!ask) return true;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: true);
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted ?? true;
    }

    return true;
  }

  static Future<void> _setZone() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      return;
    } catch (_) {}
    final offset = DateTime.now().timeZoneOffset;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.currentTimeZone.offset == offset) {
        tz.setLocalLocation(location);
        return;
      }
    }
  }

  static (double, double)? _savedPlace() {
    if (!Hive.isBoxOpen(AppSettings.boxName)) return null;
    final box = Hive.box<String>(AppSettings.boxName);
    final latitude = double.tryParse(box.get(prayerLatKey) ?? '');
    final longitude = double.tryParse(box.get(prayerLngKey) ?? '');
    if (latitude == null || longitude == null) return null;
    return (latitude, longitude);
  }

  static Future<void> _save(bool value) async {
    if (!Hive.isBoxOpen(AppSettings.boxName)) return;
    await Hive.box<String>(
      AppSettings.boxName,
    ).put(prayerAlertKey, value ? '1' : '0');
  }
}
