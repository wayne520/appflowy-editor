import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// 增强版链接工具栏项，支持插入链接块
final enhancedLinkMobileToolbarItem = MobileToolbarItem.withMenu(
  itemIconBuilder: (context, __, ___) => AFMobileIcon(
    afMobileIcons: AFMobileIcons.link,
    color: MobileToolbarTheme.of(context).iconColor,
  ),
  itemMenuBuilder: (_, editorState, itemMenuService) {
    final selection = editorState.selection;
    if (selection == null) {
      return const SizedBox.shrink();
    }
    return _EnhancedLinkMenu(
      editorState: editorState,
      selection: selection,
      itemMenuService: itemMenuService,
    );
  },
);

class _EnhancedLinkMenu extends StatefulWidget {
  const _EnhancedLinkMenu({
    required this.editorState,
    required this.selection,
    required this.itemMenuService,
  });

  final EditorState editorState;
  final Selection selection;
  final MobileToolbarWidgetService itemMenuService;

  @override
  State<_EnhancedLinkMenu> createState() => _EnhancedLinkMenuState();
}

class _EnhancedLinkMenuState extends State<_EnhancedLinkMenu> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 如果当前选择的文本已经是链接，则预填充URL
    final String? existingLink =
        widget.editorState.getDeltaAttributeValueInSelection(
      AppFlowyRichTextKeys.href,
      widget.selection,
    );
    if (existingLink != null) {
      _urlController.text = existingLink;
    }

    // 预填充选中的文本作为标题
    if (!widget.selection.isCollapsed) {
      final selectedText =
          widget.editorState.getTextInSelection(widget.selection);
      _titleController.text = selectedText.join();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = MobileToolbarTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          Text(
            '添加链接',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: style.foregroundColor,
            ),
          ),
          const SizedBox(height: 16),

          // URL 输入框
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: '链接地址',
              hintText: 'https://example.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              prefixIcon: const Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),

          // 标题输入框
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '链接标题（可选）',
              hintText: '输入链接显示的文本',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              // 插入链接块按钮
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _insertLinkBlock,
                  icon: const Icon(Icons.add_link),
                  label: const Text('插入链接块'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: style.primaryColor,
                    foregroundColor: style.onPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 应用链接格式按钮（如果有选中文本）
              if (!widget.selection.isCollapsed)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _applyLinkFormat,
                    icon: const Icon(Icons.format_color_text),
                    label: const Text('格式化文本'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 取消按钮
          TextButton(
            onPressed: () => widget.itemMenuService.closeItemMenu(),
            child: Text(
              '取消',
              style: TextStyle(color: style.foregroundColor),
            ),
          ),
        ],
      ),
    );
  }

  /// 插入链接块
  void _insertLinkBlock() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('请输入链接地址');
      return;
    }

    final title = _titleController.text.trim();
    final displayText = title.isNotEmpty ? title : url;

    // 创建链接块
    final linkNode = Node(
      type: ParagraphBlockKeys.type,
      attributes: {
        ParagraphBlockKeys.delta: Delta(
          operations: [
            TextInsert(
              displayText,
              attributes: {
                AppFlowyRichTextKeys.href: url,
              },
            ),
          ],
        ).toJson(),
      },
    );

    // 插入到当前位置
    final transaction = widget.editorState.transaction;
    transaction.insertNode(widget.selection.start.path.next, linkNode);
    widget.editorState.apply(transaction);

    // 关闭菜单
    widget.itemMenuService.closeItemMenu();
    widget.editorState.service.keyboardService?.closeKeyboard();
  }

  /// 应用链接格式到选中文本
  void _applyLinkFormat() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('请输入链接地址');
      return;
    }

    // 应用链接格式
    widget.editorState.formatDelta(widget.selection, {
      AppFlowyRichTextKeys.href: url,
    });

    // 关闭菜单
    widget.itemMenuService.closeItemMenu();
    widget.editorState.service.keyboardService?.closeKeyboard();
  }

  /// 显示错误信息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
