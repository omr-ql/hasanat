import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hasanat/data/app_settings.dart';
import 'package:hasanat/data/reminders.dart';
import 'package:hasanat/theme/app_theme.dart';
import 'package:hasanat/widgets/ui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class ReminderCard extends StatefulWidget {
  const ReminderCard({super.key});

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  ReminderLibrary? _library;
  Timer? _timer;
  var _loading = false;
  Quote? _pickedHadith;
  Quote? _pickedPrayer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!Hive.isBoxOpen(AppSettings.boxName)) return;
    final box = Hive.box<String>(AppSettings.boxName);
    final cached = ReminderLibrary.decode(box.get(remindersCacheKey));
    final fetchedAt = int.tryParse(box.get(remindersFetchedKey) ?? '') ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - fetchedAt;
    final fresh = cached != null && !cached.isEmpty && age < kReminderCacheLife.inMilliseconds;
    if (!mounted) return;
    setState(() {
      _library = cached;
      _loading = !fresh;
    });
    _arm();
    if (fresh) return;
    try {
      final downloaded = await downloadReminders();
      final next = (cached ?? const ReminderLibrary(hadiths: [], prayers: [])).merge(
        downloaded,
      );
      await box.put(remindersCacheKey, next.encode());
      await box.put(
        remindersFetchedKey,
        '${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      setState(() {
        _library = next;
        _loading = false;
      });
      _arm();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _arm() {
    _timer?.cancel();
    if (_library == null || _library!.isEmpty) return;
    final now = DateTime.now();
    final slot = kReminderSlot.inMilliseconds;
    final next = (now.millisecondsSinceEpoch ~/ slot + 1) * slot;
    final wait = Duration(
      milliseconds: next - now.millisecondsSinceEpoch + 250,
    );
    _timer = Timer(wait, () {
      if (!mounted) return;
      setState(() {
        _pickedHadith = null;
        _pickedPrayer = null;
      });
      _arm();
    });
  }

  bool get _canShuffle {
    final library = _library;
    if (library == null) return false;
    return library.hadiths.length > 1 || library.prayers.length > 1;
  }

  void _shuffle() {
    final library = _library;
    if (library == null) return;
    final now = DateTime.now();
    setState(() {
      _pickedHadith = _different(
        library.hadiths,
        _pickedHadith ?? library.hadithAt(now),
      );
      _pickedPrayer = _different(
        library.prayers,
        _pickedPrayer ?? library.prayerAt(now),
      );
    });
  }

  Quote? _different(List<Quote> items, Quote? current) {
    if (items.isEmpty) return null;
    if (items.length == 1) return items.single;
    final random = Random();
    for (var attempt = 0; attempt < 8; attempt++) {
      final next = items[random.nextInt(items.length)];
      if (next.text != current?.text) return next;
    }
    final index = items.indexWhere((item) => item.text == current?.text);
    return items[(index + 1) % items.length];
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final now = DateTime.now();
    final hadith = _pickedHadith ?? _library?.hadithAt(now);
    final prayer = _pickedPrayer ?? _library?.prayerAt(now);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حديث ودعاء',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: arabicStyle(palette, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'يتبدل كل عشر دقائق',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: arabicStyle(
              palette,
              size: 12,
              weight: FontWeight.w600,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 12),
          if (hadith == null && prayer == null)
            Text(
              _loading
                  ? 'يُحضر الحديث والدعاء…'
                  : 'يظهران عند الاتصال، ثم يبقيان على الجهاز.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: arabicStyle(
                palette,
                size: 14,
                weight: FontWeight.w600,
                height: 1.4,
                color: palette.muted,
              ),
            )
          else ...[
            if (hadith != null) ...[
              Text(
                'حديث',
                style: arabicStyle(
                  palette,
                  size: 12,
                  weight: FontWeight.w700,
                  color: palette.blue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hadith.text,
                key: const Key('reminder-hadith'),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: arabicStyle(
                  palette,
                  size: 15,
                  weight: FontWeight.w600,
                  height: 1.55,
                ),
              ),
              if (hadith.source.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  hadith.source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(
                    palette,
                    size: 12,
                    weight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
              ],
            ],
            if (hadith != null && prayer != null) const SizedBox(height: 14),
            if (prayer != null) ...[
              Text(
                'دعاء',
                style: arabicStyle(
                  palette,
                  size: 12,
                  weight: FontWeight.w700,
                  color: palette.blue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                prayer.text,
                key: const Key('reminder-prayer'),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: arabicStyle(
                  palette,
                  size: 15,
                  weight: FontWeight.w600,
                  height: 1.55,
                ),
              ),
              if (prayer.source.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  prayer.source,
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
            ],
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                key: const Key('next-reminder'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: _canShuffle ? _shuffle : null,
                child: const Text('حديث ودعاء آخر'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
