import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

void main() {
  group('ShizukaPrimaryButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShizukaPrimaryButton(
              onPressed: () => called = true,
              child: const Text('Tap'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ShizukaPrimaryButton));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('does not call onPressed when isDisabled is true',
        (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShizukaPrimaryButton(
              onPressed: () => called = true,
              isDisabled: true,
              child: const Text('Tap'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ShizukaPrimaryButton));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('stretches to full width when isFullWidth is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShizukaPrimaryButton(
              onPressed: () {},
              isFullWidth: true,
              child: const Text('Full'),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ShizukaPrimaryButton), findsOneWidget);
    });
  });
}
