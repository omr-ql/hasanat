import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hasanat/data/app_settings.dart';
import 'package:hasanat/dhikr_scope.dart';
import 'package:hasanat/models/salah_tasbih.dart';
import 'package:hasanat/theme/app_theme.dart';
import 'package:hasanat/widgets/count_ring.dart';
import 'package:hasanat/widgets/hasanat_page.dart';
import 'package:hasanat/widgets/ui.dart';

class SalahTasbihScreen extends StatefulWidget {
  const SalahTasbihScreen({super.key});

  @override
  State<SalahTasbihScreen> createState() => _SalahTasbihScreenState();
}

class _SalahTasbihScreenState extends State<SalahTasbihScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 160),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    final settings = SettingsScope.of(context);
    final before = settings.salah;
    if (before.finished) return;
    final store = DhikrScope.of(context);
    final dhikr = store.find(before.current.id);
    final next = before.tap();
    unawaited(
      _press.forward(from: 0).then((_) {
        if (mounted) _press.reverse();
      }),
    );
    if (dhikr != null) await store.increment(dhikr);
    await settings.saveSalah(next);
    final advanced = next.finished || next.step != before.step;
    unawaited(
      advanced
          ? HapticFeedback.mediumImpact()
          : HapticFeedback.selectionClick(),
    );
  }

  Future<void> _undo() async {
    final settings = SettingsScope.of(context);
    final before = settings.salah;
    final id = before.undoId;
    if (id == null) return;
    final store = DhikrScope.of(context);
    final dhikr = store.find(id);
    if (dhikr != null) await store.decrement(dhikr);
    await settings.saveSalah(before.undo());
    unawaited(HapticFeedback.selectionClick());
  }

  Future<void> _restart() async {
    await SettingsScope.of(context).saveSalah(const SalahProgress());
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final progress = settings.salah;
    final step = progress.current;
    final palette = AppPalette.of(context);
    final finished = progress.finished;
    final place = finished
        ? kSalahTasbih.length
        : progress.step + 1;

    return HasanatPage(
      child: ScreenWash(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    DeltaChip(
                      label: finished ? 'تمت' : '$place من ${kSalahTasbih.length}',
                      neutral: !progress.started,
                    ),
                    const Spacer(),
                    CircleIconButton(
                      icon: Icons.arrow_back,
                      tooltip: 'رجوع',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'تسبيح بعد الصلاة',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(
                    palette,
                    size: 14,
                    weight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  finished ? 'تقبّل الله' : step.phrase,
                  key: const Key('salah-phrase'),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(
                    palette,
                    size: 22,
                    weight: FontWeight.w800,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  finished
                      ? 'تمت هذه الصلاة. ابدأها من جديد بعد الصلاة التالية.'
                      : 'مرة واحدة مع كل ضغطة',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(
                    palette,
                    size: 14,
                    weight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = math.min(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      final size = (side.isFinite ? side : 180.0)
                          .clamp(0.0, 280.0)
                          .toDouble();
                      return Center(
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 1, end: 0.96).animate(
                            CurvedAnimation(
                              parent: _press,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: GestureDetector(
                            key: const Key('salah-ring'),
                            behavior: HitTestBehavior.opaque,
                            onTap: finished ? null : _tap,
                            child: CountRing(
                              progress: progress.progress,
                              size: size,
                              stroke: size < 140 ? 10 : 14,
                              trackColor: palette.track,
                              valueColor: finished
                                  ? palette.good
                                  : palette.blue,
                              fillColor: palette.card,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      finished ? '${step.target}' : '${progress.count}',
                                      key: const Key('salah-count'),
                                      style: figureStyle(
                                        palette,
                                        size: 72,
                                        color: finished
                                            ? palette.good
                                            : palette.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'من ${step.target}',
                                      style: arabicStyle(
                                        palette,
                                        size: 14,
                                        weight: FontWeight.w600,
                                        color: palette.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    CircleIconButton(
                      key: const Key('salah-undo'),
                      icon: Icons.undo_rounded,
                      tooltip: 'تراجع',
                      onPressed: progress.undoId == null ? null : _undo,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: finished ? const Key('salah-restart') : null,
                        onPressed: finished ? _restart : _tap,
                        child: Text(
                          finished ? 'صلاة جديدة' : 'عدّ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
