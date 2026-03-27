import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/navigation.dart';
import 'package:next_chapter_scotland_app/screens/home_screen.dart';
import 'package:next_chapter_scotland_app/screens/forum.dart';
import 'package:next_chapter_scotland_app/screens/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(url: 'https://localhost:8000', anonKey: 'key');
    } catch (_) {}
  });

  group('Navigation tests', () {
    testWidgets('Navigation renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: Navigation(isGuest: true)));
      await tester.pump();

      expect(find.byType(Navigation), findsOneWidget);
    });

    testWidgets('Navigation bar renders with correct tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: Navigation(isGuest: true)));
      await tester.pump();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Forum'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
    });

    testWidgets('Home screen is shown by default', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Navigation(isGuest: true)));
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('Tapping forum tab navigates to forum screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: Navigation(isGuest: true)));
      await tester.pump();

      await tester.tap(find.text('Forum'));
      await tester.pump();

      expect(find.byType(Forum), findsOneWidget);
    });

    testWidgets('Tapping user tab navigates to profile screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: Navigation(isGuest: true)));
      await tester.pump();

      await tester.tap(find.text('User'));
      await tester.pump();

      expect(find.byType(Profile), findsOneWidget);
    });

    testWidgets('Tapping home tab returns to home screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: Navigation(isGuest: true)));
      await tester.pump();

      await tester.tap(find.text('Forum'));
      await tester.pump();

      await tester.tap(find.text('Home'));
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('Guest mode passes isGuest to screens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: Navigation(isGuest: true)));
      await tester.pump();

      await tester.tap(find.text('Forum'));
      await tester.pump();

      expect(find.textContaining("You're browsing as a guest"), findsOneWidget);
    });

    testWidgets('User mode hides guest banner in Forum', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: Navigation(isGuest: false)));
      await tester.pump();

      await tester.tap(find.text('Forum'));
      await tester.pumpAndSettle();

      expect(find.textContaining("You're browsing as a guest"), findsNothing);
    });

    testWidgets('Correct tab highlighted when selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: Navigation(isGuest: true)));
      await tester.pump();

      final BottomNavigationBar navBar = tester.widget(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 0);

      await tester.tap(find.text('Forum'));
      await tester.pump();

      final BottomNavigationBar updatedNavBar = tester.widget(
        find.byType(BottomNavigationBar),
      );
      expect(updatedNavBar.currentIndex, 1);
    });
  });
}
