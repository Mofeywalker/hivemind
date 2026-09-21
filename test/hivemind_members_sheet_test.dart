import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/features/hiveminds/domain/hivemind_member_model.dart';
import 'package:hivemind/features/hiveminds/domain/hivemind_model.dart';
import 'package:hivemind/features/hiveminds/presentation/hivemind_members_sheet.dart';
import 'package:hivemind/features/hiveminds/providers/hivemind_provider.dart';
import 'package:hivemind/l10n/app_localizations.dart';

Widget _buildTestableSheet({
  required Widget child,
  List<Override> overrides = const [],
  Locale locale = const Locale('de'),
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('de')],
      locale: locale,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  final testHivemind = Hivemind(
    id: 'hive-1',
    name: 'Familie & Heim',
    icon: '🐝',
    inviteCode: 'ABC123',
    createdAt: DateTime.now(),
  );

  group('HivemindMembersSheet Widget Tests', () {
    testWidgets('renders empty state when no members present', (tester) async {
      await tester.pumpWidget(
        _buildTestableSheet(
          overrides: [
            activeHivemindMembersProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: HivemindMembersSheet(hivemind: testHivemind),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Familie & Heim'), findsOneWidget);
      expect(find.text('Keine Mitglieder gefunden'), findsOneWidget);
      expect(find.text('Person einladen'), findsOneWidget);
    });

    testWidgets('renders member list with roles and Du badge in German', (tester) async {
      final members = [
        HivemindMember(
          userId: 'user-self',
          hivemindId: 'hive-1',
          role: 'owner',
          displayName: 'Moritz',
          joinedAt: DateTime(2026, 1, 1),
        ),
        HivemindMember(
          userId: 'user-other',
          hivemindId: 'hive-1',
          role: 'member',
          displayName: 'Lisa',
          joinedAt: DateTime(2026, 2, 1),
        ),
      ];

      await tester.pumpWidget(
        _buildTestableSheet(
          locale: const Locale('de'),
          overrides: [
            activeHivemindMembersProvider.overrideWith((ref) => Stream.value(members)),
          ],
          child: HivemindMembersSheet(
            hivemind: testHivemind,
            currentUserId: 'user-self',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Familie & Heim'), findsOneWidget);
      expect(find.text('2 Mitglieder'), findsOneWidget);
      expect(find.text('Moritz'), findsOneWidget);
      expect(find.text('Du'), findsOneWidget);
      expect(find.text('Lisa'), findsOneWidget);
      expect(find.textContaining('Eigentümer •'), findsOneWidget);
      expect(find.textContaining('Mitglied •'), findsOneWidget);
      expect(find.text('Person einladen'), findsOneWidget);
    });

    testWidgets('renders English localization correctly', (tester) async {
      final members = [
        HivemindMember(
          userId: 'user-self',
          hivemindId: 'hive-1',
          role: 'owner',
          displayName: 'Moritz',
          joinedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        _buildTestableSheet(
          locale: const Locale('en'),
          overrides: [
            activeHivemindMembersProvider.overrideWith((ref) => Stream.value(members)),
          ],
          child: HivemindMembersSheet(
            hivemind: testHivemind,
            currentUserId: 'user-self',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 member'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.textContaining('Owner'), findsOneWidget);
      expect(find.text('Invite person'), findsOneWidget);
    });
  });
}
