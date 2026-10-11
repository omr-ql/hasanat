import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hasanat/theme/app_theme.dart';

class HasanatPage extends StatelessWidget {
  const HasanatPage({
    super.key,
    required this.child,
    this.appBar,
    this.bottom,
    this.navigationBarColor,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottom;
  final Color? navigationBarColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: navigationBarColor ?? palette.canvas,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        appBar: appBar,
        body: child,
        bottomNavigationBar: bottom,
      ),
    );
  }
}
