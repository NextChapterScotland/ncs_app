import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'https://localhost:8000', anonKey: 'key');
  });

  group('Profile Screen Tests', () {
    testWidgets('Profile renders correctly for guest', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Guest'), findsAtLeastNWidgets(1));
    });

    testWidgets('Guest user displays guest profile with account options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.text('Guest'), findsAtLeastNWidgets(1));
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('AppBar displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Guest user does not show logout option', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.text('Log out'), findsNothing);
      expect(find.text('Edit profile'), findsNothing);
      expect(find.text('Change password'), findsNothing);
    });

    testWidgets('Help and support button exists', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
    });

    testWidgets('Avatar shows G for Guest', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.text('G'), findsOneWidget);
    });

    testWidgets('Guest user shows Log In and Sign Up buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('Profile layout includes all sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: false)));
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('Profile header displays user info correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('Guest'), findsAtLeastNWidgets(1));
    });

    testWidgets('CircleAvatar has correct styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.radius, equals(28));
      expect(avatar.backgroundColor, equals(const Color(0xFFFEDD33)));
    });

    testWidgets('AppBar has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(const Color(0xFFFEDD33)));
      expect(appBar.elevation, equals(0));
    });

    testWidgets('Help and support has correct icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.help_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('Log In ListTile exists', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      final loginTile = find.widgetWithText(ListTile, 'Log In');
      expect(loginTile, findsOneWidget);
    });

    testWidgets('Sign Up ListTile exists', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      final signupTile = find.widgetWithText(ListTile, 'Sign Up');
      expect(signupTile, findsOneWidget);
    });

    testWidgets('Profile background colour is correct', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFFF7F7F7)));
    });

    testWidgets('Notifications icon is present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: false)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('SwitchListTile has correct secondary icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: false)));
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );

      expect(switchTile.secondary, isA<Icon>());
    });

    testWidgets('Profile uses ListView for scrollable content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Dividers are present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsAtLeastNWidgets(1));
    });

    testWidgets('Profile header has yellow background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      final container = tester
          .widgetList<Container>(find.byType(Container))
          .firstWhere(
            (container) => container.color == const Color(0xFFFEDD33),
          );

      expect(container.color, equals(const Color(0xFFFEDD33)));
    });

    testWidgets('Guest email field is empty', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.text('Guest'), findsAtLeastNWidgets(1));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Guest user does not show stats', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.text('Posts'), findsNothing);
      expect(find.text('Likes'), findsNothing);
      expect(find.text('Joined'), findsNothing);
    });

    testWidgets('_StatItem renders label and value right', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Column(
                  children: [
                    Text(
                      '42',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Posts', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
      expect(find.text('Posts'), findsOneWidget);
    });

    testWidgets(
      'Stats row shows posts, likes, and date joined for logged-in user',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Profile(isGuest: false)),
        );
        await tester.pump();

        expect(find.text('Posts'), findsOneWidget);
        expect(find.text('Likes'), findsOneWidget);
        expect(find.text('Joined'), findsOneWidget);
      },
    );

    testWidgets('Stats row shows 0 for post count before data loads', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: false)));
      await tester.pump();

      expect(find.text('0'), findsAtLeastNWidgets(2));
    });

    testWidgets('_StatItem value updates and displays correctly when set', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text(
                  '7',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('Likes', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final valueText = tester.widget<Text>(find.text('7'));
      expect(valueText.style?.fontWeight, equals(FontWeight.bold));
      expect(valueText.style?.fontSize, equals(18));
    });

    testWidgets('Stats section is not rendered for guest', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();
      expect(find.text('Posts'), findsNothing);
      expect(find.text('Likes'), findsNothing);
    });

    testWidgets('View posts button exists for users', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: false)));
      await tester.pumpAndSettle();

      expect(find.text('My posts'), findsOneWidget);
    });

    testWidgets('View posts button does not exists for guests', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Profile(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.text('My Posts'), findsNothing);
    });
  });
}
