import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

void main() {
  group('BrushDivider', () {
    for (final width in [200.0, 375.0, 600.0]) {
      testWidgets('renders at parent width $width without overflow',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                child: const BrushDivider(),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(BrushDivider), findsOneWidget);
      });
    }

    testWidgets('respects widthFraction parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrushDivider(widthFraction: 0.5),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
