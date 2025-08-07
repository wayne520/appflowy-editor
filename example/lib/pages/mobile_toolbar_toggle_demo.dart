import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class MobileToolbarToggleDemo extends StatefulWidget {
  const MobileToolbarToggleDemo({super.key});

  @override
  State<MobileToolbarToggleDemo> createState() => _MobileToolbarToggleDemoState();
}

class _MobileToolbarToggleDemoState extends State<MobileToolbarToggleDemo> {
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
        title: const Text('Mobile Toolbar Toggle Demo'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: const Text(
              '修复验证：\n'
              '1. 点击 "Aa" 按钮中的粗体、斜体等样式，现在会正确显示选中状态\n'
              '2. 再次点击已选中的样式，会正确取消选中状态\n'
              '3. 颜色选择也会正确显示当前应用的样式状态\n'
              '4. 所有样式的切换都会实时更新UI显示',
              style: TextStyle(
                fontSize: 14,
                color: Colors.purple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 显示当前的 toggledStyle 状态
          ValueListenableBuilder(
            valueListenable: editorState.toggledStyleNotifier,
            builder: (context, toggledStyle, child) {
              return Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '当前待应用样式: ${toggledStyle.isEmpty ? "无" : toggledStyle.toString()}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              );
            },
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
