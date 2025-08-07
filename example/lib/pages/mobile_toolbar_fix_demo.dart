import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class MobileToolbarFixDemo extends StatefulWidget {
  const MobileToolbarFixDemo({super.key});

  @override
  State<MobileToolbarFixDemo> createState() => _MobileToolbarFixDemoState();
}

class _MobileToolbarFixDemoState extends State<MobileToolbarFixDemo> {
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
        title: const Text('Mobile Toolbar Fix Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Text(
              '修复说明：点击工具栏中的 "aa" 按钮（块类型选择），现在菜单下方不会再有多余的空白区域。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
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
