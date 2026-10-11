import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasanat/app.dart';
import 'package:hasanat/data/dhikr_store.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late DhikrStore store;

  setUp(() async {
    store = await DhikrStore.openInMemory();
  });

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('counts a tap and undoes it', (tester) async {
    await tester.pumpWidget(HasanatApp(store: store));
    await tester.tap(find.byKey(const Key('dhikr-istighfar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('استغفر الله'), findsWidgets);
    expect(tester.widget<Text>(find.byKey(const Key('count-value'))).data, '0');

    await tester.tap(find.byKey(const Key('count-ring')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('count-value'))).data, '1');

    await tester.tap(find.byKey(const Key('undo-count')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('count-value'))).data, '0');
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('completes a round when the target is reached', (tester) async {
    await tester.pumpWidget(HasanatApp(store: store));
    await tester.tap(find.byKey(const Key('dhikr-subhan')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('edit-target')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('target-custom')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('target-field')), '2');
    await tester.tap(find.byKey(const Key('target-apply')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('count-ring')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('count-ring')));
    await tester.pump();

    expect(find.text('اكتملت الحلقة'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('count-value'))).data, '2');

    await tester.tap(find.byKey(const Key('count-ring')));
    await tester.pump();
    expect(find.text('اكتملت الحلقة'), findsNothing);
    expect(tester.widget<Text>(find.byKey(const Key('count-value'))).data, '1');
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('adds a custom phrase and counts it', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(HasanatApp(store: store));
    await tester.tap(find.byKey(const Key('add-dhikr')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byKey(const Key('phrase-field')),
      'لا إله إلا الله',
    );
    await tester.tap(find.byKey(const Key('phrase-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('لا إله إلا الله'), findsOneWidget);
    await tester.tap(find.text('لا إله إلا الله'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('count-ring')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('count-value'))).data, '1');
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('iPhone 15 layouts do not overflow', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(
      left: 0,
      top: 59,
      right: 0,
      bottom: 34,
    );
    tester.view.padding = const FakeViewPadding(
      left: 0,
      top: 59,
      right: 0,
      bottom: 34,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(HasanatApp(store: store));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('dhikr-akbar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('count-ring')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('count-ring')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('count-value'))).data, '1');
    expect(tester.takeException(), isNull);
  });
}
