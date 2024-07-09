import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertagger/fluttertagger.dart';

void main() {
  group('FlutterTagger', () {
    late FlutterTaggerController controller;
    late Widget testWidget;
    late Function(String query, String triggerCharacter) onSearch;

    setUp(() {
      controller = FlutterTaggerController();
      onSearch = (query, triggerCharacter) {};
      testWidget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: FlutterTagger(
              overlay: Container(
                height: 100,
                color: Colors.grey,
                child: const Center(child: Text('Overlay')),
              ),
              controller: controller,
              onSearch: onSearch,
              builder: (context, key) {
                return TextField(
                  key: key,
                  controller: controller,
                );
              },
              triggerCharacterAndStyles: const {
                '@': TextStyle(color: Colors.blue),
                '#': TextStyle(color: Colors.green),
              },
            ),
          ),
        ),
      );
    });

    testWidgets('initializes without errors', (tester) async {
      await tester.pumpWidget(testWidget);
      expect(find.byType(FlutterTagger), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('triggers search callback with correct query', (tester) async {
      String searchQuery = '';
      String triggerChar = '';
      onSearch = (query, triggerCharacter) {
        searchQuery = query;
        triggerChar = triggerCharacter;
      };

      testWidget = MaterialApp(
        home: Scaffold(
          body: Center(
            child: FlutterTagger(
              overlay: Container(
                height: 100,
                color: Colors.grey,
                child: const Center(child: Text('Overlay')),
              ),
              controller: controller,
              onSearch: onSearch,
              builder: (context, key) {
                return TextField(
                  key: key,
                  controller: controller,
                  onChanged: (value) {},
                );
              },
              triggerCharacterAndStyles: const {
                '@': TextStyle(color: Colors.blue),
                '#': TextStyle(color: Colors.green),
              },
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.pump();

      // Incrementally enter each character to simulate typing
      await tester.enterText(textField, '@');
      await tester.pump();
      await tester.enterText(textField, '@t');
      await tester.pump();
      await tester.enterText(textField, '@te');
      await tester.pump();
      await tester.enterText(textField, '@tes');
      await tester.pump();
      await tester.enterText(textField, '@test');
      await tester.pumpAndSettle();

      expect(searchQuery, 'test');
      expect(triggerChar, '@');
    });

    testWidgets('displays overlay when typing a trigger character',
        (tester) async {
      await tester.pumpWidget(testWidget);

      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.pump();

      // Incrementally enter each character to simulate typing
      await tester.enterText(textField, '@');
      await tester.pump();
      await tester.enterText(textField, '@t');
      await tester.pump();
      await tester.enterText(textField, '@te');
      await tester.pump();
      await tester.enterText(textField, '@tes');
      await tester.pump();
      await tester.enterText(textField, '@test');
      await tester.pumpAndSettle();

      expect(find.text('Overlay'), findsOneWidget);
    });

    testWidgets(
        'formats and displays tagged text correctly, selecting tag without space in name',
        (tester) async {
      await tester.pumpWidget(testWidget);

      // Simulate typing the trigger character and the tag text
      final textField = find.byType(TextField);
      await tester.enterText(textField, '@');
      await tester.pump();
      await tester.enterText(textField, '@Lucky');
      await tester.pump();

      // Simulate the user selecting a tag from the overlay
      controller.addTag(id: '6zo22531b866ce0016f9e5tt', name: 'Lucky');
      await tester.pump();

      // Verify the formatted text
      expect(controller.text, '@Lucky ');
      expect(controller.formattedText, '@6zo22531b866ce0016f9e5tt#Lucky# ');
    });

    testWidgets('hides overlay when exiting search context', (tester) async {
      await tester.pumpWidget(testWidget);

      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.pump();

      // Incrementally enter each character to simulate typing
      await tester.enterText(textField, '@');
      await tester.pump();
      await tester.enterText(textField, '@t');
      await tester.pump();
      await tester.enterText(textField, '@te');
      await tester.pump();
      await tester.enterText(textField, '@tes');
      await tester.pump();
      await tester.enterText(textField, '@test');
      await tester.pumpAndSettle();

      // Verify overlay is shown
      expect(find.text('Overlay'), findsOneWidget);

      // Enter a space to exit the search context
      await tester.enterText(textField, '@test ');
      await tester.pumpAndSettle();

      // Verify overlay is hidden
      expect(find.text('Overlay'), findsNothing);
    });

    testWidgets('handles nested tags correctly', (tester) async {
      await tester.pumpWidget(testWidget);

      // Simulate typing tag
      final textField = find.byType(TextField);
      await tester.enterText(textField, '@');
      await tester.enterText(textField, '@Lucky');
      await tester.pump();

      // Simulate the user selecting tag from the overlay
      controller.addTag(id: '6zo22531b866ce0016f9e5tt', name: 'Lucky');
      await tester.pump();

      // Simulate typing a second tag
      await tester.enterText(textField, '@Lucky #');
      await tester.enterText(textField, '@Lucky #nestedTag');
      await tester.pump();

      // Simulate the user selecting tag from the overlay
      controller.addTag(id: 'anotherId', name: 'nestedTag');
      await tester.pump();

      // Verify the formatted text
      expect(controller.text, '@Lucky #nestedTag ');
      expect(controller.formattedText,
          '@6zo22531b866ce0016f9e5tt#Lucky# @anotherId#nestedTag# ');
    });

    testWidgets('handles overlay positioning correctly', (tester) async {
      // Overlay content
      final overlayContent = Container(
        height: 100,
        color: Colors.grey,
        child: const Center(child: Text('Overlay Position Test')),
      );

      testWidget = MaterialApp(
        home: Scaffold(
          body: FlutterTagger(
            overlay: overlayContent,
            controller: controller,
            onSearch: onSearch,
            builder: (context, key) {
              return TextField(
                key: key,
                controller: controller,
              );
            },
            triggerCharacterAndStyles: const {
              '@': TextStyle(color: Colors.blue),
              '#': TextStyle(color: Colors.green),
            },
            overlayPosition: OverlayPosition.bottom,
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.pump();

      // Incrementally enter each character to simulate typing
      await tester.enterText(textField, '@');
      await tester.pump();
      await tester.enterText(textField, '@t');
      await tester.pump();
      await tester.enterText(textField, '@te');
      await tester.pump();
      await tester.enterText(textField, '@tes');
      await tester.pump();
      await tester.enterText(textField, '@test');
      await tester.pumpAndSettle();

      // Verify the overlay is shown
      expect(find.text('Overlay Position Test'), findsOneWidget);

      // Verify the position of the overlay
      final overlayFinder = find.byWidget(overlayContent);
      final overlayPosition = tester.getTopLeft(overlayFinder);
      final textFieldPosition = tester.getBottomLeft(textField);

      // Check if the overlay is positioned below the TextField
      expect(overlayPosition.dy, greaterThanOrEqualTo(textFieldPosition.dy));
    });

    testWidgets('formats text with specific pattern and parser',
        (tester) async {
      await tester.pumpWidget(testWidget);

      controller.text =
          "Hey @11a27531b866ce0016f9e582#brad#. It's time to #11a27531b866ce0016f9e582#Flutter#!";
      controller.formatTags();

      await tester.pump();

      expect(controller.formattedText,
          "Hey @11a27531b866ce0016f9e582#brad#. It's time to #11a27531b866ce0016f9e582#Flutter#!");
      expect(controller.text, "Hey @brad. It's time to #Flutter!");
    });

    testWidgets('adds tags correctly', (tester) async {
      await tester.pumpWidget(testWidget);

      // Simulate typing the trigger character and the tag text
      final textField = find.byType(TextField);
      await tester.enterText(textField, '@');
      await tester.pump();
      await tester.enterText(textField, '@testUser');
      await tester.pump();

      // Simulate the user selecting a tag from the overlay
      controller.addTag(id: '123', name: 'testUser');
      await tester.pump();

      // Verify the formatted text
      expect(controller.formattedText, '@123#testUser# ');
    });

    testWidgets('removes tags correctly', (tester) async {
      await tester.pumpWidget(testWidget);

      // Simulate typing the trigger character and the tag text
      final textField = find.byType(TextField);
      await tester.enterText(textField, '@');
      await tester.pump();
      await tester.enterText(textField, '@testUser');
      await tester.pump();

      // Simulate the user selecting a tag from the overlay
      controller.addTag(id: '123', name: 'testUser');
      await tester.pump();

      // Simulate the user deleting the tag text
      // From actual interactions, 3 backspaces are required to clear
      // Text and FormattedText remains unchanged until the last delete event
      await tester.tap(textField);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.text, '@testUser');
      expect(controller.formattedText, '@123#testUser#');

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.text, '@testUser');
      expect(controller.formattedText, '@123#testUser#');

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      // Verify the formatted text is now empty
      expect(controller.text, '');
      expect(controller.formattedText, '');
    });

    testWidgets('clears text correctly', (tester) async {
      await tester.pumpWidget(testWidget);

      controller.text = '@testUser#123#';
      controller.clear();
      await tester.pump();

      expect(controller.text, '');
      expect(controller.formattedText, '');
    });
  });
}
