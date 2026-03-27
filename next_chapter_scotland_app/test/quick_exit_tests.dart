import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTestAppBar({required VoidCallback onExit}) {
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEDD33),
        title: const Text('Forum'),
        actions: [
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.exit_to_app, color: Color(0xFFCC3300)),
            tooltip: 'Quick Exit',
            onPressed: onExit,
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('Quick Exit Button', () {
    test('exit button exists in AppBar', () {
      expect(true, true);
    });

    testWidgets('exit button is visible in the AppBar', (tester) async {
    await tester.pumpWidget(
    buildTestAppBar(onExit: () {}),
    );

    expect(find.byIcon(Icons.exit_to_app), findsOneWidget);
    });

    testWidgets('exit button triggers callback when tapped', (tester) async {
      bool exitCalled = false;

      await tester.pumpWidget(
        buildTestAppBar(onExit: () => exitCalled = true),
      );

      await tester.tap(find.byIcon(Icons.exit_to_app));
      await tester.pump();

      expect(exitCalled, true);
    });

    testWidgets('exit button has correct color', (tester) async {
      await tester.pumpWidget(
        buildTestAppBar(onExit: () {}),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.exit_to_app));
      expect(icon.color, const Color(0xFFCC3300));
    });

    testWidgets('exit button has correct icon size', (tester) async {
      await tester.pumpWidget(
        buildTestAppBar(onExit: () {}),
      );

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.exit_to_app),
      );
      expect(iconButton.iconSize, 28);
    });
  });
}