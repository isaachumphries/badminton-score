import 'package:badminton_score/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('setup -> score -> undo', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const BadmintonApp());
    expect(find.text('Badminton'), findsOneWidget);

    // Start is disabled until the user picks a ruleset.
    FilledButton start() =>
        tester.widget<FilledButton>(find.byKey(const Key('start')));
    expect(start().onPressed, isNull);
    await tester.tap(find.byKey(const Key('ruleset-bwf21')));
    await tester.pump();
    expect(start().onPressed, isNotNull);

    await tester.ensureVisible(find.byKey(const Key('start')));
    await tester.tap(find.byKey(const Key('start')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('court')), findsOneWidget);
    expect(find.text('serves'), findsOneWidget);
    expect(find.text('receives'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('panel-a')));
    await tester.pump();
    expect(find.descendant(of: find.byKey(const Key('panel-a')), matching: find.text('1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('undo')));
    await tester.pump();
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('game win shows next-game card', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BadmintonApp());
    await tester.tap(find.byKey(const Key('ruleset-bwf15')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('start')));
    await tester.tap(find.byKey(const Key('start')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 15; i++) {
      await tester.tap(find.byKey(const Key('panel-a')));
      await tester.pump();
    }
    expect(find.byKey(const Key('next-game')), findsOneWidget);
  });
}
