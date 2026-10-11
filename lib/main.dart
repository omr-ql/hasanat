import 'package:flutter/material.dart';
import 'package:hasanat/app.dart';
import 'package:hasanat/data/app_settings.dart';
import 'package:hasanat/data/dhikr_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = await DhikrStore.open();
    final settings = await AppSettings.open();
    runApp(HasanatApp(store: store, settings: settings));
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    runApp(const HasanatBootError());
  }
}
