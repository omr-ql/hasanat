import 'package:flutter/material.dart';
import 'package:hasanat/models/dhikr.dart';
import 'package:hasanat/theme/app_theme.dart';

String cheerFor(Dhikr dhikr) {
  if (dhikr.roundComplete) return 'اكتملت الحلقة';
  if (dhikr.total == 0) return 'أول ضغطة تبدأ الأجر';
  if (dhikr.progress >= 0.75) return 'اقتربت، ثبّت همتك';
  if (dhikr.rounds >= 3) return 'همة عالية، واصل';
  if (dhikr.rounds > 0) return 'ما شاء الله، حلقة وراء حلقة';
  return 'استمر، كل ضغطة تُحسب';
}

String paceLabel(Dhikr dhikr) {
  if (dhikr.roundComplete) return 'تمت';
  return '${(dhikr.progress * 100).round()}%';
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.tapKey,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Key? tapKey;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final radius = BorderRadius.circular(this.radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: radius,
        boxShadow: cardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: tapKey,
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class DeltaChip extends StatelessWidget {
  const DeltaChip({
    super.key,
    required this.label,
    this.positive = true,
    this.neutral = false,
    this.showArrow = true,
  });

  final String label;
  final bool positive;
  final bool neutral;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final background = neutral
        ? palette.canvas
        : positive
        ? palette.goodSoft
        : palette.dangerSoft;
    final foreground = neutral
        ? palette.muted
        : positive
        ? palette.good
        : palette.danger;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          showArrow && positive && !neutral ? '▲ $label' : label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: arabicStyle(
            palette,
            size: 12,
            weight: FontWeight.w700,
            height: 1.2,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
    this.size = 48,
    this.matchTextDirection = false,
    this.mutedWhenDisabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;
  final double size;
  final bool matchTextDirection;
  final bool mutedWhenDisabled;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? palette.blue : palette.card,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? palette.blue : palette.card,
              boxShadow: filled ? const [] : cardShadow(context),
            ),
            child: Transform.flip(
              flipX:
                  matchTextDirection &&
                  Directionality.of(context) == TextDirection.rtl,
              child: Icon(
                icon,
                size: 22,
                color: onPressed == null && mutedWhenDisabled
                    ? palette.muted
                    : filled
                    ? Colors.white
                    : palette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BlueChoiceChip extends StatelessWidget {
  const BlueChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: palette.blue,
      backgroundColor: palette.canvas,
      labelStyle: arabicStyle(
        palette,
        size: 14,
        color: selected ? Colors.white : palette.ink,
      ),
      side: BorderSide(color: selected ? palette.blue : palette.line),
      shape: const StadiumBorder(),
    );
  }
}

class ScreenWash extends StatelessWidget {
  const ScreenWash({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.wash, palette.canvas, palette.canvas],
          stops: const [0, 0.32, 1],
        ),
      ),
      child: child,
    );
  }
}
