import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hasanat/data/dhikr_store.dart';
import 'package:hasanat/dhikr_scope.dart';
import 'package:hasanat/screens/home_screen.dart';
import 'package:hasanat/theme/app_theme.dart';

class HasanatApp extends StatelessWidget {
  const HasanatApp({super.key, required this.store});

  final DhikrStore store;

  @override
  Widget build(BuildContext context) {
    return DhikrScope(
      store: store,
      child: MaterialApp(
        title: 'حسنات',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildHasanatTheme(Brightness.light),
        darkTheme: buildHasanatTheme(Brightness.dark),
        builder: (context, child) {
          final canvas = AppPalette.of(context).canvas;
          return ColoredBox(
            color: canvas,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}

class HasanatBootError extends StatelessWidget {
  const HasanatBootError({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildHasanatTheme(Brightness.light),
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'تعذر فتح العدّاد على هذا الجهاز.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
