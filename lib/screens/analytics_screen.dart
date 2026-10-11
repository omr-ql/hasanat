import 'package:flutter/material.dart';
import 'package:hasanat/dhikr_scope.dart';
import 'package:hasanat/dhikr_style.dart';
import 'package:hasanat/models/count_history.dart';
import 'package:hasanat/theme/app_theme.dart';
import 'package:hasanat/widgets/dual_line_chart.dart';
import 'package:hasanat/widgets/ui.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  ChartRange _range = ChartRange.year;

  @override
  Widget build(BuildContext context) {
    final store = DhikrScope.of(context);
    final palette = AppPalette.of(context);
    final phrases = [
      for (final dhikr in [...store.presets, ...store.custom])
        PhraseRef(id: dhikr.id, phrase: dhikr.phrase),
    ];
    final chart = buildChart(
      history: store.history,
      range: _range,
      now: DateTime.now(),
      phrases: phrases,
    );
    final change = chart.changeRatio;

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
                  child: Text(
                    'التحليلات',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: arabicStyle(
                      palette,
                      size: 34,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: ChartRange.values.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final range = ChartRange.values[index];
                        return _RangePill(
                          key: Key('range-${range.name}'),
                          label: range.label,
                          selected: range == _range,
                          onTap: () => setState(() => _range = range),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'مجموع الحسنات',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: arabicStyle(
                                  palette,
                                  size: 16,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: Text(
                                      '${chart.total}',
                                      key: const Key('analytics-total'),
                                      maxLines: 1,
                                      style: figureStyle(palette, size: 32),
                                    ),
                                  ),
                                  if (change != null) ...[
                                    const SizedBox(height: 6),
                                    DeltaChip(
                                      key: const Key('analytics-change'),
                                      label: formatChange(change),
                                      positive: change >= 0,
                                    ),
                                  ] else if (chart.total > 0) ...[
                                    const SizedBox(height: 6),
                                    const DeltaChip(
                                      key: Key('analytics-change'),
                                      label: 'جديد',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DualLineChart(
                          key: const Key('analytics-chart'),
                          buckets: chart.buckets,
                          axisMax: chart.axisMax,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'نصيب كل ذكر',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              if (chart.shares.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'عدّ اليوم، فيرتفع الخط معك.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: arabicStyle(
                        palette,
                        size: 14,
                        weight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: chart.shares.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: palette.line,
                    ),
                    itemBuilder: (context, index) {
                      final share = chart.shares[index];
                      return _ShareRow(share: share);
                    },
                  ),
                ),
            ],
          ),
        ),
    );
  }
}

class _RangePill extends StatelessWidget {
  const _RangePill({
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

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.share});

  final ChartShare share;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = accentFor(share.id);
    final high = share.fraction >= 0.5;
    final percent = '${(share.fraction * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(iconFor(share.id), size: 20, color: accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.phrase,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(palette, size: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${share.count}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: figureStyle(palette, size: 13, color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: high ? palette.goodSoft : palette.blueSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                percent,
                maxLines: 1,
                style: figureStyle(
                  palette,
                  size: 13,
                  color: high ? palette.good : palette.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
