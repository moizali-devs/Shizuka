import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

void main() {
  group('SakuraIcon', () {
    for (final size in [24.0, 60.0, 120.0]) {
      testWidgets('renders at size $size without overflow', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: SakuraIcon(size: size)),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(SakuraIcon), findsOneWidget);
      });
    }
  });
}
