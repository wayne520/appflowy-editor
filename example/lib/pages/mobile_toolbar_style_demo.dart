import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class MobileToolbarStyleDemo extends StatefulWidget {
  const MobileToolbarStyleDemo({super.key});

  @override
  State<MobileToolbarStyleDemo> createState() => _MobileToolbarStyleDemoState();
}

class _MobileToolbarStyleDemoState extends State<MobileToolbarStyleDemo> {
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
        title: const Text('Mobile Toolbar Style Demo'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: const Text(
              '功能演示：\n'
              '1. 点击工具栏中的 "Aa" 按钮（文本装饰）可以设置粗体、斜体等样式\n'
              '2. 点击颜色按钮可以设置文字颜色和背景颜色\n'
              '3. 现在支持在没有选中文字时设置样式，接下来输入的文字会带上这些样式！',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
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
