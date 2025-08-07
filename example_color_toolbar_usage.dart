// 颜色工具栏使用示例
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class ColorToolbarExample extends StatefulWidget {
  const ColorToolbarExample({super.key});

  @override
  State<ColorToolbarExample> createState() => _ColorToolbarExampleState();
}

class _ColorToolbarExampleState extends State<ColorToolbarExample> {
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
        title: const Text('颜色工具栏示例'),
      ),
      body: MobileToolbarV2(
        editorState: editorState,
        toolbarItems: [
          // 方案1：使用组合的文本和背景色工具栏项
          buildTextAndBackgroundColorMobileToolbarItem(),
          
          // 方案2：使用分离的文本颜色和背景色工具栏项（推荐）
          // buildTextColorMobileToolbarItem(),
          // buildHighlightColorMobileToolbarItem(),
          
          // 其他工具栏项
          textDecorationMobileToolbarItemV2,
          headingMobileToolbarItem,
          todoListMobileToolbarItem,
          listMobileToolbarItem,
          linkMobileToolbarItem,
          quoteMobileToolbarItem,
          dividerMobileToolbarItem,
        ],
        child: AppFlowyEditor(
          editorState: editorState,
          editorStyle: EditorStyle.mobile(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ),
    );
  }
}

// 自定义颜色选项示例
class CustomColorToolbarExample extends StatefulWidget {
  const CustomColorToolbarExample({super.key});

  @override
  State<CustomColorToolbarExample> createState() => _CustomColorToolbarExampleState();
}

class _CustomColorToolbarExampleState extends State<CustomColorToolbarExample> {
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
        title: const Text('自定义颜色工具栏'),
      ),
      body: MobileToolbarV2(
        editorState: editorState,
        toolbarItems: [
          // 使用自定义颜色选项
          buildTextColorMobileToolbarItem(
            textColorOptions: [
              ColorOption(
                colorHex: Colors.red.toHex(),
                name: '红色',
              ),
              ColorOption(
                colorHex: Colors.blue.toHex(),
                name: '蓝色',
              ),
              ColorOption(
                colorHex: Colors.green.toHex(),
                name: '绿色',
              ),
              ColorOption(
                colorHex: Colors.purple.toHex(),
                name: '紫色',
              ),
              ColorOption(
                colorHex: Colors.orange.toHex(),
                name: '橙色',
              ),
              ColorOption(
                colorHex: Colors.teal.toHex(),
                name: '青色',
              ),
            ],
          ),
          buildHighlightColorMobileToolbarItem(
            backgroundColorOptions: [
              ColorOption(
                colorHex: Colors.yellow.toHex(),
                name: '黄色高亮',
              ),
              ColorOption(
                colorHex: Colors.lightBlue.toHex(),
                name: '蓝色高亮',
              ),
              ColorOption(
                colorHex: Colors.lightGreen.toHex(),
                name: '绿色高亮',
              ),
              ColorOption(
                colorHex: Colors.pink.shade100.toHex(),
                name: '粉色高亮',
              ),
            ],
          ),
          textDecorationMobileToolbarItemV2,
        ],
        child: AppFlowyEditor(
          editorState: editorState,
          editorStyle: EditorStyle.mobile(),
        ),
      ),
    );
  }
}

// 使用示例
void main() {
  runApp(
    MaterialApp(
      title: '颜色工具栏演示',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const ColorToolbarExample(),
      routes: {
        '/custom': (context) => const CustomColorToolbarExample(),
      },
    ),
  );
}

// 监听颜色变化的示例
class ColorChangeListenerExample extends StatefulWidget {
  const ColorChangeListenerExample({super.key});

  @override
  State<ColorChangeListenerExample> createState() => _ColorChangeListenerExampleState();
}

class _ColorChangeListenerExampleState extends State<ColorChangeListenerExample> {
  late EditorState editorState;
  String currentTextColor = '无';
  String currentBackgroundColor = '无';

  @override
  void initState() {
    super.initState();
    editorState = EditorState.blank();
    
    // 监听颜色变化
    editorState.toggledStyleNotifier.addListener(_onStyleChanged);
  }

  @override
  void dispose() {
    editorState.toggledStyleNotifier.removeListener(_onStyleChanged);
    editorState.dispose();
    super.dispose();
  }

  void _onStyleChanged() {
    setState(() {
      final textColor = editorState.toggledStyle[AppFlowyRichTextKeys.textColor] as String?;
      final backgroundColor = editorState.toggledStyle[AppFlowyRichTextKeys.backgroundColor] as String?;
      
      currentTextColor = textColor ?? '无';
      currentBackgroundColor = backgroundColor ?? '无';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('颜色变化监听'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Text('当前文本颜色: $currentTextColor'),
                const SizedBox(width: 20),
                Text('当前背景色: $currentBackgroundColor'),
              ],
            ),
          ),
          Expanded(
            child: MobileToolbarV2(
              editorState: editorState,
              toolbarItems: [
                buildTextColorMobileToolbarItem(),
                buildHighlightColorMobileToolbarItem(),
                textDecorationMobileToolbarItemV2,
              ],
              child: AppFlowyEditor(
                editorState: editorState,
                editorStyle: EditorStyle.mobile(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
