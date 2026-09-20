import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/core/theme/app_theme.dart';
import 'package:hivemind/shared/widgets/card_container.dart';
import 'package:hivemind/shared/widgets/minimal_button.dart';
import 'package:hivemind/shared/widgets/status_pill.dart';

void main() {
  group('UI Components Widget Tests', () {
    testWidgets('MinimalButton displays text and triggers onPressed', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: Scaffold(
            body: MinimalButton(
              text: 'Click Me',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
      await tester.tap(find.text('Click Me'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('StatusPill renders label and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StatusPill(
              label: 'Every Sunday',
              icon: Icons.repeat,
            ),
          ),
        ),
      );

      expect(find.text('Every Sunday'), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsOneWidget);
    });

    testWidgets('CardContainer renders child with padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CardContainer(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });
  });
}
