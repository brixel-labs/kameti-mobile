import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kameti/design_system/design_system.dart';

import '../../helpers/pump_k.dart';

void main() {
  group('KAvatar', () {
    test('initials', () {
      expect(KAvatar.initialsOf('Usman Tariq'), 'UT');
      expect(KAvatar.initialsOf('  hira  ali  shah '), 'HS');
      expect(KAvatar.initialsOf('Bilal'), 'B');
      expect(KAvatar.initialsOf(''), '?');
    });

    testWidgets('uses the palette colour and wraps the index', (tester) async {
      await pumpK(tester, const KAvatar(name: 'Ali Raza', colorIndex: 9));
      expect(find.text('AR'), findsOneWidget);
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(KAvatar),
          matching: find.byType(Container),
        ),
      );
      final colour = (box.decoration! as BoxDecoration).color;
      expect(colour, KColors.light.avatar(1).background);
      expect(KColors.light.avatars, hasLength(8));
      expect(KColors.dark.avatars, hasLength(8));
    });

    testWidgets('size presets', (tester) async {
      await pumpK(
        tester,
        const KAvatar(name: 'A', colorIndex: 0, size: KAvatarSize.lg),
      );
      expect(tester.getSize(find.byType(KAvatar)), const Size(48, 48));
    });

    testWidgets('decorative unless labelled', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpK(tester, const KAvatar(name: 'Ali Raza', colorIndex: 0));
      expect(find.bySemanticsLabel('AR'), findsNothing);
      await pumpK(
        tester,
        const KAvatar(
          name: 'Ali Raza',
          colorIndex: 0,
          semanticLabel: 'Ali Raza',
        ),
      );
      expect(find.bySemanticsLabel('Ali Raza'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        Wrap(
          children: [
            for (var i = 0; i < 8; i++)
              KAvatar(name: 'Sana Malik', colorIndex: i),
          ],
        ),
      );
    });
  });

  group('KAvatarStack', () {
    const members = [
      KAvatarData(name: 'Ali Raza', colorIndex: 0),
      KAvatarData(name: 'Sara Khan', colorIndex: 2),
      KAvatarData(name: 'Hamza Q', colorIndex: 3),
      KAvatarData(name: 'Nida Iqbal', colorIndex: 4),
      KAvatarData(name: 'Omar F', colorIndex: 5),
    ];

    testWidgets('shows max avatars and a +N bubble', (tester) async {
      await pumpK(tester, const KAvatarStack(members: members));
      expect(find.byType(KAvatar), findsNWidgets(3));
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('reads the names to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpK(tester, const KAvatarStack(members: members, max: 2));
      expect(
        find.bySemanticsLabel('Ali Raza, Sara Khan, 3 more'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('no bubble when everyone fits', (tester) async {
      await pumpK(tester, KAvatarStack(members: members.take(2).toList()));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('renders in light and dark', (tester) async {
      await expectRendersInAllThemes(
        tester,
        const KAvatarStack(members: members),
      );
    });
  });
}
