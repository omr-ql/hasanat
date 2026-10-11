import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hasanat/data/app_settings.dart';
import 'package:hasanat/dhikr_scope.dart';
import 'package:hasanat/dhikr_style.dart';
import 'package:hasanat/models/dhikr.dart';
import 'package:hasanat/screens/counter_screen.dart';
import 'package:hasanat/theme/app_theme.dart';
import 'package:hasanat/widgets/editor_sheets.dart';
import 'package:hasanat/widgets/ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final draft = await showPhraseEditor(context);
    if (draft == null || !context.mounted) return;
    await DhikrScope.of(
      context,
    ).createCustom(phrase: draft.phrase, target: draft.target);
  }

  @override
  Widget build(BuildContext context) {
    final store = DhikrScope.of(context);
    final palette = AppPalette.of(context);
    final presets = store.presets;
    final custom = store.custom;
    final everyone = [...presets, ...custom];
    final total = everyone.fold<int>(0, (sum, item) => sum + item.total);
    final rounds = everyone.fold<int>(0, (sum, item) => sum + item.rounds);

    return ScreenWash(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _HomeHeader(
                    palette: palette,
                    total: total,
                    rounds: rounds,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _TotalCard(
                    total: total,
                    rounds: rounds,
                    palette: palette,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'الأذكار',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 142,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final dhikr = presets[index];
                    return _DhikrCard(
                      dhikr: dhikr,
                      accent: accentFor(dhikr.id),
                      icon: iconFor(dhikr.id),
                      onTap: () => _open(context, dhikr.id),
                    );
                  }, childCount: presets.length),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'أذكاري',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleIconButton(
                        key: const Key('add-dhikr'),
                        icon: Icons.add,
                        tooltip: 'إضافة',
                        filled: true,
                        size: 44,
                        onPressed: () => _add(context),
                      ),
                    ],
                  ),
                ),
              ),
              if (custom.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(child: _EmptyCustom()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList.separated(
                    itemCount: custom.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final dhikr = custom[index];
                      return _CustomTile(
                        dhikr: dhikr,
                        onTap: () => _open(context, dhikr.id),
                        onRename: () => _rename(context, dhikr),
                        onDelete: () => _delete(context, dhikr),
                      );
                    },
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'بلا إنترنت، والعدّ محفوظ على هذا الجهاز.',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: arabicStyle(
                      palette,
                      size: 13,
                      weight: FontWeight.w500,
                      color: palette.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  void _open(BuildContext context, String id) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => CounterScreen(id: id)));
  }

  Future<void> _rename(BuildContext context, Dhikr dhikr) async {
    final draft = await showPhraseEditor(
      context,
      initialPhrase: dhikr.phrase,
      initialTarget: dhikr.target,
      includeTarget: false,
    );
    if (draft == null || !context.mounted) return;
    dhikr.rename(draft.phrase);
    await DhikrScope.of(context).save(dhikr);
  }

  Future<void> _delete(BuildContext context, Dhikr dhikr) async {
    final approved = await confirmAction(
      context,
      title: 'حذف الذكر؟',
      message: 'يُحذف «${dhikr.phrase}» وعدّاده من الجهاز، ولا يُسترجع.',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!approved || !context.mounted) return;
    await DhikrScope.of(context).delete(dhikr.id);
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.palette,
    required this.total,
    required this.rounds,
  });

  final AppPalette palette;
  final int total;
  final int rounds;

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final black = settings.black;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/app_logo.jpg',
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'عدّاد الأذكار',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: arabicStyle(
                  palette,
                  size: 14,
                  weight: FontWeight.w600,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'حسنات',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: arabicStyle(palette, size: 34, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
        if (rounds > 0) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: DeltaChip(label: '$rounds حلقة'),
            ),
          ),
        ] else if (total == 0)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: DeltaChip(label: 'ابدأ', neutral: true, showArrow: false),
          ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: CircleIconButton(
            key: const Key('toggle-theme'),
            icon: black ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: black ? 'الوضع الفاتح' : 'الوضع الأسود',
            size: 40,
            onPressed: () {
              settings.toggle();
            },
          ),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.rounds,
    required this.palette,
  });

  final int total;
  final int rounds;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final waiting = total == 0;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مجموع الحسنات',
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
            '$total',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: figureStyle(palette, size: 40),
          ),
          const SizedBox(height: 8),
          Text(
            waiting
                ? 'لم تبدأ بعد، والأجر ينتظر أول ضغطة'
                : rounds == 0
                ? 'بداية جميلة، أكمل الحلقة'
                : 'أحسنت، استمر فالأجر يزداد',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: arabicStyle(
              palette,
              size: 14,
              weight: FontWeight.w600,
              height: 1.35,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({
    required this.dhikr,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final Dhikr dhikr;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final idle = dhikr.total == 0 && !dhikr.roundComplete;
    return SoftCard(
      tapKey: Key('dhikr-${dhikr.id}'),
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(icon, size: 16, color: accent),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dhikr.phrase,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(palette, size: 15),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${dhikr.count}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: figureStyle(palette, size: 32),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'من ${dhikr.target}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(
                    palette,
                    size: 12,
                    weight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: DeltaChip(
                  label: paceLabel(dhikr),
                  neutral: idle,
                  showArrow: !dhikr.roundComplete && !idle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomTile extends StatelessWidget {
  const _CustomTile({
    required this.dhikr,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final Dhikr dhikr;
  final VoidCallback onTap;
  final Future<void> Function() onRename;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final idle = dhikr.total == 0 && !dhikr.roundComplete;
    return SoftCard(
      tapKey: Key('dhikr-${dhikr.id}'),
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      radius: 22,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.blue,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${dhikr.count}',
                    maxLines: 1,
                    style: figureStyle(palette, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dhikr.phrase,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(palette, size: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'من ${dhikr.target}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(
                    palette,
                    size: 13,
                    weight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: DeltaChip(
              label: paceLabel(dhikr),
              neutral: idle,
              showArrow: !dhikr.roundComplete && !idle,
            ),
          ),
          PopupMenuButton<_TileAction>(
            tooltip: 'المزيد',
            padding: EdgeInsets.zero,
            onSelected: (action) {
              switch (action) {
                case _TileAction.rename:
                  unawaited(onRename());
                case _TileAction.delete:
                  unawaited(onDelete());
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _TileAction.rename,
                child: Text('تعديل النص'),
              ),
              PopupMenuItem(
                value: _TileAction.delete,
                child: Text('حذف', style: TextStyle(color: palette.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TileAction { rename, delete }

class _EmptyCustom extends StatelessWidget {
  const _EmptyCustom();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SoftCard(
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.blueSoft,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.add_rounded, color: palette.blue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أضف ذكرك الأول',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(palette, size: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'أي كلمة تريد عدّها، وتبقى هنا.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(
                    palette,
                    size: 13,
                    weight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
