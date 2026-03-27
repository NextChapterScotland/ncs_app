import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_chapter_scotland_app/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_chapter_scotland_app/screens/category_page.dart';

void main() {
  group('HomePage Tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await Supabase.initialize(url: '', anonKey: '');
    });

    // Test 1: Page renders without crashing
    testWidgets('renders HomePage without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(HomePage), findsOneWidget);
    });

    // Test 2: Greeting text is displayed
    testWidgets('displays greeting "Hi, Guest"', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('Hi, Guest'), findsOneWidget);
    });

    // Test 3: Welcome message is displayed
    testWidgets('displays welcome message', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('Welcome back!'), findsOneWidget);
    });

    // Test 4: Profile avatar is present
    testWidgets('displays CircleAvatars', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage(isGuest: true)));
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsNWidgets(2));
    });

    // Test 5: Search bar is present
    testWidgets('displays search TextField', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.byType(TextField), findsOneWidget);
    });

    // Test 6: Search bar has correct hint text
    testWidgets('search bar has correct hint text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('Search topics, support, or guides...'), findsOneWidget);
    });

    // Test 7: Search icon is present
    testWidgets('displays search icon', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    // Test 8: "Explore topics" heading is displayed
    testWidgets('displays "Explore topics" heading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('Explore topics'), findsOneWidget);
    });

    // Test 9: GridView is present
    testWidgets('contains GridView for categories', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.byType(GridView), findsOneWidget);
    });

    // Test 10: Work category icon is displayed
    testWidgets('displays work icon on Work card', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.byIcon(Icons.work_outline), findsOneWidget);
    });

    // Test 11: Health category icon is displayed
    testWidgets('displays health icon on Health card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage(isGuest: true)));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(Icons.health_and_safety_outlined),
        200,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.byIcon(Icons.health_and_safety_outlined), findsOneWidget);
    });

    // Test 12: Tapping Work card navigates to WorkPage
    testWidgets('navigates to CategoryPage when Work card is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage(isGuest: true)));
      await tester.pumpAndSettle();

      final workText = find.text('Work');

      await tester.ensureVisible(workText);
      await tester.pumpAndSettle();

      await tester.tap(workText);
      await tester.pumpAndSettle();

      expect(find.byType(CategoryPage), findsOneWidget);
    });

    // Test 14: Background color is correct
    testWidgets('has correct background color', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF7F7F7));
    });
  });
}
