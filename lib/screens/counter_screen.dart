import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hasanat/dhikr_scope.dart';
import 'package:hasanat/models/dhikr.dart';
import 'package:hasanat/theme/app_theme.dart';
import 'package:hasanat/widgets/count_ring.dart';
import 'package:hasanat/widgets/editor_sheets.dart';
import 'package:hasanat/widgets/hasanat_page.dart';
import 'package:hasanat/widgets/ui.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key, required this.id});

  final String id;

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen>
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

  Future<void> _increment(Dhikr dhikr) async {
    unawaited(
      _press.forward(from: 0).then((_) {
        if (mounted) _press.reverse();
      }),
    );
    final completed = await DhikrScope.of(context).increment(dhikr);
    unawaited(
      completed
          ? HapticFeedback.mediumImpact()
          : HapticFeedback.selectionClick(),
    );
  }

  Future<void> _decrement(Dhikr dhikr) async {
    if (!await DhikrScope.of(context).decrement(dhikr)) return;
    unawaited(HapticFeedback.selectionClick());
  }

  Future<void> _editTarget(Dhikr dhikr) async {
    final next = await showTargetEditor(context, current: dhikr.target);
    if (next == null || !mounted) return;
    dhikr.setTarget(next);
    await DhikrScope.of(context).save(dhikr);
  }

  Future<void> _setTarget(Dhikr dhikr, int target) async {
    dhikr.setTarget(target);
    await DhikrScope.of(context).save(dhikr);
  }

  Future<void> _rename(Dhikr dhikr) async {
    final draft = await showPhraseEditor(
      context,
      initialPhrase: dhikr.phrase,
      initialTarget: dhikr.target,
      includeTarget: false,
    );
    if (draft == null || !mounted) return;
    dhikr.rename(draft.phrase);
    await DhikrScope.of(context).save(dhikr);
  }

  Future<void> _resetRound(Dhikr dhikr) async {
    if (dhikr.count == 0) return;
    final approved = await confirmAction(
      context,
      title: 'تصفير الحلقة؟',
      message: 'يعود العدّاد الحالي إلى صفر. المجموع والحلقات تبقى كما هي.',
      confirmLabel: 'تصفير',
    );
    if (!approved || !mounted) return;
    dhikr.resetRound();
    await DhikrScope.of(context).save(dhikr);
  }

  Future<void> _resetAll(Dhikr dhikr) async {
    final approved = await confirmAction(
      context,
      title: 'تصفير الكل؟',
      message: 'يعود العدّاد والمجموع والحلقات إلى صفر.',
      confirmLabel: 'تصفير الكل',
      destructive: true,
    );
    if (!approved || !mounted) return;
    await DhikrScope.of(context).resetAll(dhikr);
  }

  Future<void> _delete(Dhikr dhikr) async {
    final approved = await confirmAction(
      context,
      title: 'حذف الذكر؟',
      message: 'يُحذف «${dhikr.phrase}» وعدّاده من الجهاز، ولا يُسترجع.',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!approved || !mounted) return;
    await DhikrScope.of(context).delete(dhikr.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = DhikrScope.of(context);
    final dhikr = store.find(widget.id);
    if (dhikr == null) {
      return const HasanatPage(child: SizedBox.shrink());
    }

    final palette = AppPalette.of(context);
    final complete = dhikr.roundComplete;
    final actionLabel = dhikr.total == 0
        ? 'ابدأ العد'
        : complete
        ? 'حلقة جديدة'
        : 'عدّ';

    return HasanatPage(
      child: ScreenWash(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back,
                      tooltip: 'رجوع',
                      matchTextDirection: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    PopupMenuButton<_CounterAction>(
                      tooltip: 'المزيد',
                      onSelected: (action) {
                        switch (action) {
                          case _CounterAction.rename:
                            unawaited(_rename(dhikr));
                          case _CounterAction.resetRound:
                            unawaited(_resetRound(dhikr));
                          case _CounterAction.resetAll:
                            unawaited(_resetAll(dhikr));
                          case _CounterAction.delete:
                            unawaited(_delete(dhikr));
                        }
                      },
                      itemBuilder: (context) => [
                        if (!dhikr.isPreset)
                          const PopupMenuItem(
                            value: _CounterAction.rename,
                            child: Text('تعديل النص'),
                          ),
                        const PopupMenuItem(
                          value: _CounterAction.resetRound,
                          child: Text('تصفير الحلقة'),
                        ),
                        const PopupMenuItem(
                          value: _CounterAction.resetAll,
                          child: Text('تصفير الكل'),
                        ),
                        if (!dhikr.isPreset)
                          PopupMenuItem(
                            value: _CounterAction.delete,
                            child: Text(
                              'حذف',
                              style: TextStyle(color: palette.danger),
                            ),
                          ),
                      ],
                      child: CircleIconButton(
                        icon: Icons.more_horiz,
                        tooltip: 'المزيد',
                        mutedWhenDisabled: false,
                        onPressed: null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  dhikr.phrase,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(
                    palette,
                    size: 26,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cheerFor(dhikr),
                  key: complete ? const Key('round-complete') : null,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(
                    palette,
                    size: 14,
                    weight: FontWeight.w600,
                    color: complete ? palette.good : palette.muted,
                  ),
                ),
                const SizedBox(height: 12),
                _ProgressDash(
                  progress: dhikr.progress,
                  color: complete ? palette.good : palette.blue,
                  track: palette.track,
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
                          child: Semantics(
                            button: true,
                            label:
                                'زيادة ${dhikr.phrase}، ${dhikr.count} من ${dhikr.target}',
                            child: GestureDetector(
                              key: const Key('count-ring'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _increment(dhikr),
                              child: CountRing(
                                progress: dhikr.progress,
                                size: size,
                                stroke: size < 140 ? 10 : 14,
                                trackColor: palette.track,
                                valueColor: complete
                                    ? palette.good
                                    : palette.blue,
                                fillColor: palette.card,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${dhikr.count}',
                                        key: const Key('count-value'),
                                        style: figureStyle(
                                          palette,
                                          size: 72,
                                          color: complete
                                              ? palette.good
                                              : palette.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'من ${dhikr.target}',
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
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (final goal in const [33, 100, 500]) ...[
                        _GoalPill(
                          label: '$goal',
                          selected: dhikr.target == goal,
                          onTap: () => _setTarget(dhikr, goal),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _GoalPill(
                        key: const Key('edit-target'),
                        label: 'مخصص',
                        selected: ![33, 100, 500].contains(dhikr.target),
                        onTap: () => _editTarget(dhikr),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleIconButton(
                      key: const Key('undo-count'),
                      icon: Icons.undo_rounded,
                      tooltip: 'تراجع',
                      onPressed: dhikr.count == 0
                          ? null
                          : () => _decrement(dhikr),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _increment(dhikr),
                        child: Text(
                          actionLabel,
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

class _ProgressDash extends StatelessWidget {
  const _ProgressDash({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 112,
          height: 6,
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1).toDouble(),
            backgroundColor: track,
            color: color,
            minHeight: 6,
          ),
        ),
      ),
    );
  }
}

class _GoalPill extends StatelessWidget {
  const _GoalPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: selected ? palette.blue : palette.card,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? palette.blue : palette.line),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              style: arabicStyle(
                palette,
                size: 14,
                color: selected ? Colors.white : palette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CounterAction { rename, resetRound, resetAll, delete }
