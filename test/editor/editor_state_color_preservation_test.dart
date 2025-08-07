import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorState global formatting persistence tests', () {
    late EditorState editorState;

    setUp(() {
      editorState = EditorState.blank();
    });

    tearDown(() {
      editorState.dispose();
    });

    test('should persist text color globally until explicitly changed', () async {
      // Set up initial selection at the beginning of the document
      final initialSelection = Selection.collapsed(
        Position(path: [0], offset: 0),
      );
      editorState.selection = initialSelection;

      // Set a text color in toggled style (simulating user selecting a color)
      const testColor = '#FF0000'; // Red color
      editorState.updateToggledStyle(AppFlowyRichTextKeys.textColor, testColor);

      // Verify the color is set
      expect(
        editorState.toggledStyle[AppFlowyRichTextKeys.textColor],
        equals(testColor),
      );

      // Simulate typing a character (this would normally clear the toggled style)
      final newSelection = Selection.collapsed(
        Position(path: [0], offset: 1),
      );
      editorState.selection = newSelection;

      // The toggled style should be preserved globally
      expect(
        editorState.toggledStyle[AppFlowyRichTextKeys.textColor],
        equals(testColor),
        reason: 'Text color should persist globally until explicitly changed',
      );
    });

    test('should persist text color when user moves cursor anywhere', () async {
      // Set up initial selection
      final initialSelection = Selection.collapsed(
        Position(path: [0], offset: 5),
      );
      editorState.selection = initialSelection;

      // Set a text color
      const testColor = '#00FF00'; // Green color
      editorState.updateToggledStyle(AppFlowyRichTextKeys.textColor, testColor);

      // Simulate user clicking elsewhere (jumping to a different position)
      final newSelection = Selection.collapsed(
        Position(path: [0], offset: 0), // Jump back to beginning
      );
      editorState.selection = newSelection;

      // The toggled style should still be preserved
      expect(
        editorState.toggledStyle[AppFlowyRichTextKeys.textColor],
        equals(testColor),
        reason: 'Text color should persist globally even when user moves cursor',
      );
    });

    test('should persist text color even when selecting text', () async {
      // Set up initial selection
      final initialSelection = Selection.collapsed(
        Position(path: [0], offset: 0),
      );
      editorState.selection = initialSelection;

      // Set a text color
      const testColor = '#0000FF'; // Blue color
      editorState.updateToggledStyle(AppFlowyRichTextKeys.textColor, testColor);

      // Simulate user selecting text (non-collapsed selection)
      final textSelection = Selection(
        start: Position(path: [0], offset: 0),
        end: Position(path: [0], offset: 5),
      );
      editorState.selection = textSelection;

      // The toggled style should still be preserved
      expect(
        editorState.toggledStyle[AppFlowyRichTextKeys.textColor],
        equals(testColor),
        reason: 'Text color should persist globally even when selecting text',
      );
    });

    test('should persist text color when moving to different line', () async {
      // Add a second paragraph to the document
      final transaction = editorState.transaction;
      transaction.insertNode([1], paragraphNode());
      await editorState.apply(transaction);

      // Set up initial selection on first line
      final initialSelection = Selection.collapsed(
        Position(path: [0], offset: 0),
      );
      editorState.selection = initialSelection;

      // Set a text color
      const testColor = '#FFFF00'; // Yellow color
      editorState.updateToggledStyle(AppFlowyRichTextKeys.textColor, testColor);

      // Move to second line
      final newSelection = Selection.collapsed(
        Position(path: [1], offset: 0),
      );
      editorState.selection = newSelection;

      // The toggled style should still be preserved
      expect(
        editorState.toggledStyle[AppFlowyRichTextKeys.textColor],
        equals(testColor),
        reason: 'Text color should persist globally even when moving to different line',
      );
    });

    test('should preserve multiple formatting styles during typing', () async {
      // Set up initial selection
      final initialSelection = Selection.collapsed(
        Position(path: [0], offset: 0),
      );
      editorState.selection = initialSelection;

      // Set multiple formatting styles
      const testColor = '#FF00FF'; // Magenta color
      editorState.updateToggledStyle(AppFlowyRichTextKeys.textColor, testColor);
      editorState.updateToggledStyle(AppFlowyRichTextKeys.bold, true);
      editorState.updateToggledStyle(AppFlowyRichTextKeys.italic, true);

      // Simulate typing (cursor moves forward)
      final newSelection = Selection.collapsed(
        Position(path: [0], offset: 3),
      );
      editorState.selection = newSelection;

      // All formatting styles should be preserved
      expect(
        editorState.toggledStyle[AppFlowyRichTextKeys.textColor],
        equals(testColor),
      );
      expect(
        editorState.toggledStyle[AppFlowyRichTextKeys.bold],
        equals(true),
      );
      expect(
        editorState.toggledStyle[AppFlowyRichTextKeys.italic],
        equals(true),
      );
    });

    test('should notify UI when toggled style changes', () async {
      bool notificationReceived = false;
      String? receivedColor;

      // Listen to toggled style changes
      editorState.toggledStyleNotifier.addListener(() {
        notificationReceived = true;
        receivedColor = editorState.toggledStyle[AppFlowyRichTextKeys.textColor] as String?;
      });

      // Update text color
      const testColor = '#00FFFF'; // Cyan color
      editorState.updateToggledStyle(AppFlowyRichTextKeys.textColor, testColor);

      // Verify notification was sent
      expect(notificationReceived, isTrue);
      expect(receivedColor, equals(testColor));
    });

    test('should clear specific formatting while preserving others', () async {
      // Set multiple formatting styles
      const textColor = '#FF0000';
      const backgroundColor = '#FFFF00';
      editorState.updateToggledStyle(AppFlowyRichTextKeys.textColor, textColor);
      editorState.updateToggledStyle(AppFlowyRichTextKeys.backgroundColor, backgroundColor);
      editorState.updateToggledStyle(AppFlowyRichTextKeys.bold, true);

      // Clear only text color
      editorState.updateToggledStyle(AppFlowyRichTextKeys.textColor, null);

      // Text color should be cleared, others preserved
      expect(editorState.toggledStyle[AppFlowyRichTextKeys.textColor], isNull);
      expect(editorState.toggledStyle[AppFlowyRichTextKeys.backgroundColor], equals(backgroundColor));
      expect(editorState.toggledStyle[AppFlowyRichTextKeys.bold], equals(true));
    });
  });
}
