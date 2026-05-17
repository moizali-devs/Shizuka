import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shizuka/shared/widgets/widgets.dart';

void main() {
  group('ShizukaTextInput', () {
    testWidgets('onChanged fires with correct value', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShizukaTextInput(
              label: 'Email',
              onChanged: values.add,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      expect(values.last, 'hello');
    });

    testWidgets('shows focused border on focus without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShizukaTextInput(label: 'Email'),
          ),
        ),
      );

      // Tap to focus
      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ShizukaTextInput), findsOneWidget);
    });

    testWidgets('renders with prefixIcon and obscureText', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShizukaTextInput(
              label: 'Password',
              hintText: 'Enter password',
              obscureText: true,
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ShizukaTextInput), findsOneWidget);
    });
  });
}
