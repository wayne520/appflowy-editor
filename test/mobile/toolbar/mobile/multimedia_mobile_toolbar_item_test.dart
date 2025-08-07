import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultimediaMobileToolbarItem', () {
    testWidgets('should display multimedia icon', (WidgetTester tester) async {
      final editorState = EditorState.blank();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileToolbarV2(
              editorState: editorState,
              toolbarItems: [multimediaMobileToolbarItem],
              child: const SizedBox(),
            ),
          ),
        ),
      );

      // 验证多媒体图标是否显示
      expect(find.byType(AFMobileIcon), findsOneWidget);
    });

    testWidgets('should show menu when tapped', (WidgetTester tester) async {
      final editorState = EditorState.blank();
      // 设置一个选择区域，这样工具栏才会显示
      editorState.selection = Selection.collapsed(Position(path: [0], offset: 0));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileToolbarV2(
              editorState: editorState,
              toolbarItems: [multimediaMobileToolbarItem],
              child: const SizedBox(),
            ),
          ),
        ),
      );

      // 点击多媒体按钮
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // 验证菜单是否显示
      expect(find.text('照片和视频'), findsOneWidget);
      expect(find.text('拍照和录像'), findsOneWidget);
    });

    test('multimedia toolbar item should have a menu', () {
      expect(multimediaMobileToolbarItem.hasMenu, true);
      expect(multimediaMobileToolbarItem.itemMenuBuilder, isNotNull);
      expect(multimediaMobileToolbarItem.actionHandler, isNull);
    });
  });
}
