import 'package:flutter/widgets.dart';
import 'package:hasanat/data/dhikr_store.dart';

class DhikrScope extends InheritedNotifier<DhikrStore> {
  const DhikrScope({super.key, required DhikrStore store, required super.child})
    : super(notifier: store);

  static DhikrStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DhikrScope>();
    assert(scope != null, 'DhikrScope is missing above this widget');
    return scope!.notifier!;
  }
}
