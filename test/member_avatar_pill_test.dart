import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/features/hiveminds/domain/hivemind_member_model.dart';
import 'package:hivemind/features/hiveminds/domain/hivemind_model.dart';
import 'package:hivemind/features/hiveminds/presentation/widgets/member_avatar_pill.dart';
import 'package:hivemind/features/hiveminds/providers/hivemind_provider.dart';
import 'package:hivemind/l10n/app_localizations.dart';

Widget _buildTestableWidget({
  required Widget child,
  List<Override> overrides = const [],
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
      locale: const Locale('de'),
      home: Scaffold(body: Center(child: child)),
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

  group('MemberAvatarPill Widget Tests', () {
    testWidgets('renders empty placeholder when members stream is empty', (tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            activeHivemindMembersProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MemberAvatarPill(hivemind: testHivemind),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
    });

    testWidgets('renders member initials for 2 members', (tester) async {
      final members = [
        HivemindMember(
          userId: 'u1',
          hivemindId: 'hive-1',
          role: 'owner',
          displayName: 'Moritz',
          joinedAt: DateTime(2026, 1, 1),
        ),
        HivemindMember(
          userId: 'u2',
          hivemindId: 'hive-1',
          role: 'member',
          displayName: 'Lisa',
          joinedAt: DateTime(2026, 1, 2),
        ),
      ];

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            activeHivemindMembersProvider.overrideWith((ref) => Stream.value(members)),
          ],
          child: MemberAvatarPill(hivemind: testHivemind),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('M'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('renders +2 overflow badge when 4 members are present', (tester) async {
      final members = [
        HivemindMember(userId: 'u1', hivemindId: 'hive-1', role: 'owner', displayName: 'Moritz', joinedAt: DateTime.now()),
        HivemindMember(userId: 'u2', hivemindId: 'hive-1', role: 'member', displayName: 'Lisa', joinedAt: DateTime.now()),
        HivemindMember(userId: 'u3', hivemindId: 'hive-1', role: 'member', displayName: 'Florian', joinedAt: DateTime.now()),
        HivemindMember(userId: 'u4', hivemindId: 'hive-1', role: 'member', displayName: 'Anna', joinedAt: DateTime.now()),
      ];

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            activeHivemindMembersProvider.overrideWith((ref) => Stream.value(members)),
          ],
          child: MemberAvatarPill(hivemind: testHivemind),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+2'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('invokes onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _buildTestableWidget(
          overrides: [
            activeHivemindMembersProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MemberAvatarPill(
            hivemind: testHivemind,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(MemberAvatarPill));
      expect(tapped, isTrue);
    });
  });
}
