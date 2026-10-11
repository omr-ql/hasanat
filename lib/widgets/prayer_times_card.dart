import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hasanat/data/app_settings.dart';
import 'package:hasanat/data/prayer_alerts.dart';
import 'package:hasanat/data/prayer_times.dart';
import 'package:hasanat/data/prayer_widget.dart';
import 'package:hasanat/theme/app_theme.dart';
import 'package:hasanat/widgets/ui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class PrayerTimesCard extends StatefulWidget {
  const PrayerTimesCard({super.key});

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  double? _latitude;
  double? _longitude;
  var _locating = false;
  var _alerts = false;
  String? _error;
  String? _alertError;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _readSaved();
    final latitude = _latitude;
    final longitude = _longitude;
    if (latitude != null && longitude != null) {
      unawaited(
        publishPrayerWidget(latitude: latitude, longitude: longitude),
      );
    }
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _readSaved() {
    if (!Hive.isBoxOpen(AppSettings.boxName)) return;
    final box = Hive.box<String>(AppSettings.boxName);
    final latitude = double.tryParse(box.get(prayerLatKey) ?? '');
    final longitude = double.tryParse(box.get(prayerLngKey) ?? '');
    if (latitude == null || longitude == null) return;
    _latitude = latitude;
    _longitude = longitude;
    _alerts = box.get(prayerAlertKey) == '1';
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _fail('شغّل خدمة الموقع ثم أعد المحاولة.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _fail('لم يُسمح بالموقع، فلا تظهر المواقيت.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (Hive.isBoxOpen(AppSettings.boxName)) {
        final box = Hive.box<String>(AppSettings.boxName);
        await box.put(prayerLatKey, '${position.latitude}');
        await box.put(prayerLngKey, '${position.longitude}');
      }
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locating = false;
      });
      if (_alerts) {
        await PrayerAlerts.sync(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
      await publishPrayerWidget(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      _fail('تعذّر قراءة الموقع. حاول مرة أخرى.');
    }
  }

  Future<void> _toggleAlerts(bool value) async {
    final latitude = _latitude;
    final longitude = _longitude;
    if (latitude == null || longitude == null) return;
    if (!value) {
      await PrayerAlerts.disable();
      if (!mounted) return;
      setState(() {
        _alerts = false;
        _alertError = null;
      });
      return;
    }
    final ok = await PrayerAlerts.enable(
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;
    setState(() {
      _alerts = ok;
      _alertError = ok ? null : 'اسمح بالإشعارات ليصلك التنبيه.';
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _locating = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final latitude = _latitude;
    final longitude = _longitude;
    final day = latitude == null || longitude == null
        ? null
        : prayersFor(latitude: latitude, longitude: longitude, now: DateTime.now());
    final nextLabel = day == null
        ? null
        : day.nextIsTomorrow
        ? 'القادم: الفجر غداً'
        : 'القادم: ${day.nextName}';

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مواقيت الصلاة',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: arabicStyle(palette, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            nextLabel ?? 'حسب موقعك، بطريقة أم القرى',
            key: const Key('prayer-next'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: arabicStyle(
              palette,
              size: 13,
              weight: FontWeight.w600,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 12),
          if (day == null) ...[
            Text(
              _error ??
                  (_locating
                      ? 'يُحدَّد موقعك…'
                      : 'اسمح بالموقع مرة واحدة، وتُحسب المواقيت على الجهاز.'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: arabicStyle(
                palette,
                size: 14,
                weight: FontWeight.w600,
                height: 1.4,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                key: const Key('prayer-locate'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: _locating ? null : _locate,
                child: Text(_error == null ? 'استخدم موقعي' : 'حاول مرة أخرى'),
              ),
            ),
          ] else
            for (final slot in day.slots) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      slot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: arabicStyle(
                        palette,
                        size: 15,
                        color: slot.next ? palette.blue : palette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatPrayerClock(slot.time),
                    key: Key('prayer-${slot.name}'),
                    maxLines: 1,
                    style: figureStyle(
                      palette,
                      size: 16,
                      color: slot.next ? palette.blue : palette.ink,
                    ),
                  ),
                ],
              ),
              if (slot != day.slots.last) const SizedBox(height: 8),
            ],
          if (day != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تنبيه عند الصلاة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: arabicStyle(palette, size: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        kIsWeb
                            ? 'يصل ما دامت الصفحة مفتوحة'
                            : 'يصل حتى لو أُغلق التطبيق',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: arabicStyle(
                          palette,
                          size: 12,
                          weight: FontWeight.w600,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  key: const Key('prayer-alert'),
                  value: _alerts,
                  onChanged: _toggleAlerts,
                ),
              ],
            ),
            if (_alertError != null) ...[
              const SizedBox(height: 6),
              Text(
                _alertError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: arabicStyle(
                  palette,
                  size: 13,
                  weight: FontWeight.w600,
                  color: palette.danger,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
