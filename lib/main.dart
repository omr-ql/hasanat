import 'package:flutter/material.dart';
import 'package:hasanat/app.dart';
import 'package:hasanat/data/dhikr_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = await DhikrStore.open();
    runApp(HasanatApp(store: store));
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    runApp(const HasanatBootError());
  }
}
