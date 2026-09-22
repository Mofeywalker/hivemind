import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('HivemindApp widget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HivemindApp()));

    // Initial load will redirect to login screen
    expect(find.byType(HivemindApp), findsOneWidget);
  });
}
