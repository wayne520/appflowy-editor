// 鸿蒙系统工具栏使用示例
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class HarmonyOSEditorExample extends StatefulWidget {
  const HarmonyOSEditorExample({super.key});

  @override
  State<HarmonyOSEditorExample> createState() => _HarmonyOSEditorExampleState();
}

class _HarmonyOSEditorExampleState extends State<HarmonyOSEditorExample> {
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
        title: const Text('HarmonyOS Editor'),
      ),
      body: MobileToolbarV2(
        editorState: editorState,
        toolbarItems: [
          // 基本格式化工具
          textDecorationMobileToolbarItem,
          buildTextColorMobileToolbarItem(),
          buildHighlightColorMobileToolbarItem(),
          headingMobileToolbarItem,
          todoListMobileToolbarItem,
          listMobileToolbarItem,
          linkMobileToolbarItem,
          quoteMobileToolbarItem,
          dividerMobileToolbarItem,
        ],
        child: AppFlowyEditor(
          editorState: editorState,
          // 针对鸿蒙系统优化的配置
          editorStyle: EditorStyle.mobile(
            // 使用与工具栏匹配的背景色
            backgroundColor: _getEditorBackgroundColor(context),
            // 其他样式配置...
          ),
        ),
      ),
    );
  }

  /// 获取适合鸿蒙系统的编辑器背景色
  Color _getEditorBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    
    // 在鸿蒙系统上使用与工具栏协调的背景色
    if (PlatformExtension.isHarmonyOS) {
      return theme.brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)  // 深色主题
          : const Color(0xFFFAFAFA); // 浅色主题
    }
    
    // 其他平台使用默认背景色
    return theme.scaffoldBackgroundColor;
  }
}

// 使用示例
void main() {
  runApp(
    MaterialApp(
      title: 'HarmonyOS Editor Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // 支持深色主题以适配鸿蒙系统
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const HarmonyOSEditorExample(),
    ),
  );
}

// 自定义工具栏项示例（可选）
MobileToolbarItem customHarmonyOSToolbarItem = MobileToolbarItem.withMenu(
  itemIconBuilder: (context, editorState, service) {
    return const Icon(Icons.format_paint);
  },
  itemMenuBuilder: (context, editorState, service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // 使用与鸿蒙系统协调的颜色
        color: PlatformExtension.isHarmonyOS
            ? const Color(0xFFF5F5F5)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('自定义菜单'),
    );
  },
);
