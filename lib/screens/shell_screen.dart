import 'package:flutter/material.dart';
import 'package:hasanat/screens/analytics_screen.dart';
import 'package:hasanat/screens/home_screen.dart';
import 'package:hasanat/theme/app_theme.dart';
import 'package:hasanat/widgets/hasanat_page.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return HasanatPage(
      navigationBarColor: palette.card,
      bottom: _BottomBar(
        index: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
      child: IndexedStack(
        index: _index,
        children: const [HomeScreen(), AnalyticsScreen()],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _BarItem(
                key: const Key('nav-home'),
                icon: Icons.home_rounded,
                label: 'الأذكار',
                selected: index == 0,
                onTap: () => onSelected(0),
              ),
              _BarItem(
                key: const Key('nav-analytics'),
                icon: Icons.show_chart_rounded,
                label: 'التحليلات',
                selected: index == 1,
                onTap: () => onSelected(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = selected ? palette.blue : palette.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: arabicStyle(
                palette,
                size: 12,
                weight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
