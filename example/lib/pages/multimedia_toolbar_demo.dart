import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class MultimediaToolbarDemo extends StatefulWidget {
  const MultimediaToolbarDemo({super.key});

  @override
  State<MultimediaToolbarDemo> createState() => _MultimediaToolbarDemoState();
}

class _MultimediaToolbarDemoState extends State<MultimediaToolbarDemo> {
  late EditorState editorState;

  @override
  void initState() {
    super.initState();
    editorState = EditorState.blank();
  }

  @override
  void dispose() {
    editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('多媒体工具栏演示'),
        backgroundColor: Colors.purple.shade100,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: const Text(
              '功能演示：\n'
              '1. 点击工具栏中的多媒体按钮（📷图标）\n'
              '2. 选择"照片和视频"或"拍照和录像"\n'
              '3. 这是一个基础实现，您可以根据需要集成相机和相册功能',
              style: TextStyle(
                fontSize: 14,
                color: Colors.purple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: MobileToolbarV2(
              editorState: editorState,
              toolbarItems: [
                textDecorationMobileToolbarItemV2,
                buildTextAndBackgroundColorMobileToolbarItem(),
                blocksMobileToolbarItem,
                multimediaMobileToolbarItem, // 新的多媒体工具栏项
                linkMobileToolbarItem,
                dividerMobileToolbarItem,
              ],
              child: AppFlowyEditor(
                editorState: editorState,
                editorStyle: EditorStyle.mobile(
                  padding: const EdgeInsets.all(16),
                  textStyleConfiguration: const TextStyleConfiguration(
                    text: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
