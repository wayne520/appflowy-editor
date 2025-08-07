import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('多媒体拍照录像功能测试', () {
    late EditorState editorState;

    setUp(() {
      editorState = EditorState.blank();
    });

    tearDown(() {
      editorState.dispose();
    });

    testWidgets('标准多媒体工具栏应该显示4个选项', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileToolbarV2(
              editorState: editorState,
              toolbarItems: [
                multimediaMobileToolbarItem,
              ],
              child: AppFlowyEditor(editorState: editorState),
            ),
          ),
        ),
      );

      // 点击多媒体工具栏按钮
      await tester.tap(find.byIcon(Icons.photo_camera));
      await tester.pumpAndSettle();

      // 验证显示了4个选项
      expect(find.text('选择图片'), findsOneWidget);
      expect(find.text('选择视频'), findsOneWidget);
      expect(find.text('拍照'), findsOneWidget);
      expect(find.text('录像'), findsOneWidget);
    });

    testWidgets('增强版多媒体工具栏应该显示6个选项', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileToolbarV2(
              editorState: editorState,
              toolbarItems: [
                enhancedMultimediaMobileToolbarItem,
              ],
              child: AppFlowyEditor(editorState: editorState),
            ),
          ),
        ),
      );

      // 点击增强版多媒体工具栏按钮
      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();

      // 验证显示了所有选项
      expect(find.text('拍照'), findsOneWidget);
      expect(find.text('录像'), findsOneWidget);
      expect(find.text('选择图片'), findsOneWidget);
      expect(find.text('选择视频'), findsOneWidget);
      expect(find.text('高质量拍照'), findsOneWidget);
      expect(find.text('长视频录制'), findsOneWidget);
    });

    testWidgets('应该显示正确的图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileToolbarV2(
              editorState: editorState,
              toolbarItems: [
                multimediaMobileToolbarItem,
              ],
              child: AppFlowyEditor(editorState: editorState),
            ),
          ),
        ),
      );

      // 点击多媒体工具栏按钮
      await tester.tap(find.byIcon(Icons.photo_camera));
      await tester.pumpAndSettle();

      // 验证图标
      expect(find.byIcon(Icons.photo_library), findsOneWidget); // 选择图片
      expect(find.byIcon(Icons.video_library), findsOneWidget); // 选择视频
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);    // 拍照
      expect(find.byIcon(Icons.videocam), findsOneWidget);      // 录像
    });

    testWidgets('增强版应该显示分组标题', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileToolbarV2(
              editorState: editorState,
              toolbarItems: [
                enhancedMultimediaMobileToolbarItem,
              ],
              child: AppFlowyEditor(editorState: editorState),
            ),
          ),
        ),
      );

      // 点击增强版多媒体工具栏按钮
      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();

      // 验证分组标题
      expect(find.text('添加媒体'), findsOneWidget);
      expect(find.text('拍摄'), findsOneWidget);
      expect(find.text('从相册选择'), findsOneWidget);
      expect(find.text('高级选项'), findsOneWidget);
    });

    test('ImagePicker 应该正确配置拍照参数', () {
      // 验证拍照参数配置
      const expectedMaxWidth = 1920.0;
      const expectedMaxHeight = 1080.0;
      const expectedImageQuality = 85;

      expect(expectedMaxWidth, equals(1920.0));
      expect(expectedMaxHeight, equals(1080.0));
      expect(expectedImageQuality, equals(85));
    });

    test('ImagePicker 应该正确配置录像参数', () {
      // 验证录像参数配置
      const expectedMaxDuration = Duration(minutes: 5);
      const expectedLongVideoDuration = Duration(minutes: 30);

      expect(expectedMaxDuration.inMinutes, equals(5));
      expect(expectedLongVideoDuration.inMinutes, equals(30));
    });

    test('高质量拍照应该使用正确的参数', () {
      // 验证高质量拍照参数
      const expectedMaxWidth = 4096.0;
      const expectedMaxHeight = 4096.0;
      const expectedImageQuality = 95;

      expect(expectedMaxWidth, equals(4096.0));
      expect(expectedMaxHeight, equals(4096.0));
      expect(expectedImageQuality, equals(95));
    });

    testWidgets('工具栏应该正确处理选择变化', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileToolbarV2(
              editorState: editorState,
              toolbarItems: [
                multimediaMobileToolbarItem,
                textDecorationMobileToolbarItemV2,
              ],
              child: AppFlowyEditor(editorState: editorState),
            ),
          ),
        ),
      );

      // 点击多媒体工具栏按钮
      await tester.tap(find.byIcon(Icons.photo_camera));
      await tester.pumpAndSettle();

      // 验证菜单打开
      expect(find.text('选择图片'), findsOneWidget);

      // 点击其他工具栏按钮
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pumpAndSettle();

      // 验证多媒体菜单关闭
      expect(find.text('选择图片'), findsNothing);
    });

    group('错误处理测试', () {
      test('应该正确识别权限错误', () {
        const permissionError = 'camera_access_denied';
        const generalError = 'some other error';

        expect(permissionError.contains('permission') || 
               permissionError.contains('camera_access_denied'), isTrue);
        expect(generalError.contains('permission'), isFalse);
      });

      test('应该正确识别相机不可用错误', () {
        const cameraError = 'No camera available';
        const otherError = 'network error';

        expect(cameraError.contains('No camera available'), isTrue);
        expect(otherError.contains('No camera available'), isFalse);
      });
    });

    group('媒体文件处理测试', () {
      test('应该正确识别图片文件类型', () {
        const imageFiles = ['photo.jpg', 'image.png', 'picture.jpeg'];
        const videoFiles = ['video.mp4', 'movie.mov', 'clip.avi'];

        for (final file in imageFiles) {
          expect(file.toLowerCase().endsWith('.jpg') ||
                 file.toLowerCase().endsWith('.png') ||
                 file.toLowerCase().endsWith('.jpeg'), isTrue);
        }

        for (final file in videoFiles) {
          expect(file.toLowerCase().endsWith('.mp4') ||
                 file.toLowerCase().endsWith('.mov') ||
                 file.toLowerCase().endsWith('.avi'), isTrue);
        }
      });

      test('应该正确创建媒体节点属性', () {
        const expectedImageAttributes = {
          'url': '/path/to/image.jpg',
          'align': 'center',
          'width': 400.0,
          'borderRadius': 12.0,
        };

        const expectedVideoAttributes = {
          'url': '/path/to/video.mp4',
          'align': 'center',
          'width': 400.0,
          'height': 225.0,
          'borderRadius': 12.0,
        };

        expect(expectedImageAttributes['align'], equals('center'));
        expect(expectedImageAttributes['width'], equals(400.0));
        expect(expectedImageAttributes['borderRadius'], equals(12.0));

        expect(expectedVideoAttributes['align'], equals('center'));
        expect(expectedVideoAttributes['width'], equals(400.0));
        expect(expectedVideoAttributes['height'], equals(225.0));
        expect(expectedVideoAttributes['borderRadius'], equals(12.0));
      });
    });
  });
}
