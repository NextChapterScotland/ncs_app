import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────
// Minimal deleted-comment display widget
// ─────────────────────────────────────────────

Widget buildDeletedCommentCard({required bool deleted, String text = 'Hello'}) {
  return MaterialApp(
    home: Scaffold(
      body: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: deleted
              ? Row(
                  children: [
                    const Icon(Icons.remove_circle_outline,
                        color: Colors.grey, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'This comment has been deleted',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              : Text(text),
        ),
      ),
    ),
  );
}

void main() {
  // ── Soft-delete comment tests ──────────────────────────────────────────

  group('Soft delete comment', () {
    testWidgets(
      '1. Deleted comment shows placeholder text instead of content',
      (tester) async {
        await tester.pumpWidget(
            buildDeletedCommentCard(deleted: true, text: 'Original text'));
        expect(find.text('This comment has been deleted'), findsOneWidget);
        expect(find.text('Original text'), findsNothing);
      },
    );

    testWidgets(
      '2. Non-deleted comment shows its content',
      (tester) async {
        await tester.pumpWidget(
            buildDeletedCommentCard(deleted: false, text: 'Original text'));
        expect(find.text('Original text'), findsOneWidget);
        expect(find.text('This comment has been deleted'), findsNothing);
      },
    );

    testWidgets(
      '3. Deleted comment placeholder uses italic style',
      (tester) async {
        await tester.pumpWidget(buildDeletedCommentCard(deleted: true));
        final text = tester.widget<Text>(
          find.text('This comment has been deleted'),
        );
        expect(text.style?.fontStyle, FontStyle.italic);
      },
    );

    testWidgets(
      '4. Deleted comment shows remove_circle_outline icon',
      (tester) async {
        await tester.pumpWidget(buildDeletedCommentCard(deleted: true));
        expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      },
    );

    testWidgets(
      '5. Non-deleted comment does not show remove icon',
      (tester) async {
        await tester.pumpWidget(
            buildDeletedCommentCard(deleted: false, text: 'Some text'));
        expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
      },
    );
  });

  // ── Delete post UI tests ───────────────────────────────────────────────

  group('Delete post UI', () {
    Widget buildDialogTest({required VoidCallback onDelete}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Post'),
                  content: const Text(
                    'Are you sure you want to delete your post and all its comments?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        onDelete();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets(
      '1. Delete confirmation dialog shows correct title',
      (tester) async {
        await tester.pumpWidget(buildDialogTest(onDelete: () {}));
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
        expect(find.text('Delete Post'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Delete confirmation dialog shows both Cancel and Delete buttons',
      (tester) async {
        await tester.pumpWidget(buildDialogTest(onDelete: () {}));
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Pressing Cancel closes the dialog without calling delete',
      (tester) async {
        bool deleteWasCalled = false;
        await tester
            .pumpWidget(buildDialogTest(onDelete: () => deleteWasCalled = true));
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(deleteWasCalled, false);
        expect(find.text('Delete Post'), findsNothing);
      },
    );

    testWidgets(
      '4. Delete button in dialog has red text colour',
      (tester) async {
        await tester.pumpWidget(buildDialogTest(onDelete: () {}));
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
        final deleteText = tester.widget<Text>(find.text('Delete'));
        expect(deleteText.style?.color, Colors.red);
      },
    );

    testWidgets(
      '5. Pressing Delete calls the delete callback and closes dialog',
      (tester) async {
        bool deleteWasCalled = false;
        await tester
            .pumpWidget(buildDialogTest(onDelete: () => deleteWasCalled = true));
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(deleteWasCalled, true);
        expect(find.text('Delete Post'), findsNothing);
      },
    );
  });
}