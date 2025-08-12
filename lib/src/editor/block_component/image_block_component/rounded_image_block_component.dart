import 'dart:convert';
import 'dart:io';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:open_filex/open_filex.dart';
import '../../../infra/path_utils.dart';
import '../../util/media_cleanup.dart';

/// 圆角图片块组件
class RoundedImageBlockComponentBuilder extends BlockComponentBuilder {
  RoundedImageBlockComponentBuilder({
    super.configuration,
    this.showMenu = false,
    this.menuBuilder,
  });

  final bool showMenu;
  final ImageBlockComponentMenuBuilder? menuBuilder;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return RoundedImageBlockComponentWidget(
      key: node.key,
      node: node,
      showActions: showActions(node),
      configuration: configuration,
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
      actionTrailingBuilder: (context, state) => actionTrailingBuilder(
        blockComponentContext,
        state,
      ),
      showMenu: showMenu,
      menuBuilder: menuBuilder,
    );
  }

  @override
  BlockComponentValidate get validate =>
      (node) => node.delta == null && node.children.isEmpty;
}

class RoundedImageBlockComponentWidget extends BlockComponentStatefulWidget {
  const RoundedImageBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.showMenu = false,
    this.menuBuilder,
  });

  final bool showMenu;
  final ImageBlockComponentMenuBuilder? menuBuilder;

  @override
  State<RoundedImageBlockComponentWidget> createState() =>
      _RoundedImageBlockComponentWidgetState();
}

class _RoundedImageBlockComponentWidgetState
    extends State<RoundedImageBlockComponentWidget>
    with
        SelectableMixin,
        DefaultSelectableMixin,
        BlockComponentConfigurable,
        BlockComponentBackgroundColorMixin,
        NestedBlockComponentStatefulWidgetMixin {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  final imageKey = GlobalKey();

  // 实现 DefaultSelectableMixin 需要的 keys
  @override
  GlobalKey get blockComponentKey => imageKey;

  @override
  GlobalKey get containerKey => imageKey;

  @override
  GlobalKey get forwardKey => imageKey;

  // 实现 NestedBlockComponentStatefulWidgetMixin 需要的方法
  @override
  Widget buildComponent(
    BuildContext context, {
    bool withBackgroundColor = true,
  }) =>
      build(context);

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final attributes = node.attributes;
    final src = attributes[ImageBlockKeys.url];

    final alignment = AlignmentExtension.fromString(
      attributes[ImageBlockKeys.align] ?? 'center',
    );
    final width = attributes[ImageBlockKeys.width]?.toDouble() ??
        MediaQuery.of(context).size.width;
    final height = attributes[ImageBlockKeys.height]?.toDouble();

    // 获取圆角半径，默认12.0像素
    final borderRadius = attributes['borderRadius']?.toDouble() ?? 12.0;

    Widget child = _buildRoundedImage(
      src: src,
      width: width,
      height: height,
      borderRadius: borderRadius,
      alignment: alignment,
    );

    child = Padding(
      key: imageKey,
      padding: padding,
      child: child,
    );

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [
        BlockSelectionType.block,
      ],
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        actionTrailingBuilder: widget.actionTrailingBuilder,
        child: child,
      );
    }

    return child;
  }

  Widget _buildRoundedImage({
    required String src,
    required double width,
    double? height,
    required double borderRadius,
    required Alignment alignment,
  }) {
    Widget imageWidget;

    // 根据源类型加载图片
    if (src.startsWith('http')) {
      imageWidget = Image.network(
        src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorWidget(width, height),
      );
    } else {
      // 处理本地文件（支持相对路径）
      imageWidget = FutureBuilder<String>(
        future: PathUtils.resolveRelativePath(src),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.file(
              File(snapshot.data!),
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildErrorWidget(width, height),
            );
          } else if (snapshot.hasError) {
            print('🖼️ 图片路径解析失败: ${snapshot.error}');
            return _buildErrorWidget(width, height);
          } else {
            return Container(
              width: width,
              height: height ?? 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      );
    }

    // 如果有圆角，应用圆角效果
    if (borderRadius > 0) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    // 应用对齐方式并添加点击功能（避免与拖拽冲突）
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: () => _showImageContextMenu(context),
        child: imageWidget,
      ),
    );
  }

  Widget _buildErrorWidget(double width, double? height) {
    return Container(
      width: width,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text('图片加载失败', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // 实现 SelectableMixin 的抽象方法
  @override
  Position start() => Position(path: widget.node.path);

  @override
  Position end() => Position(path: widget.node.path);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
    return getRectsInSelection(Selection.collapsed(end())).first;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    final size = _renderBox.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox.hasSize) {
      final parentBox = context.findRenderObject();
      final imageBox = imageKey.currentContext?.findRenderObject();
      if (parentBox is RenderBox && imageBox is RenderBox) {
        return [
          imageBox.localToGlobal(Offset.zero, ancestor: parentBox) &
              imageBox.size,
        ];
      }
    }
    return [Rect.zero];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) {
    return Selection.collapsed(Position(path: widget.node.path));
  }

  @override
  Offset localToGlobal(
    Offset parentOffset, {
    bool shiftWithBaseOffset = false,
  }) =>
      _renderBox.localToGlobal(parentOffset);

  // 显示精美的图片上下文菜单
  void _showImageContextMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 图片信息头部
              _buildImageHeader(),

              // 菜单选项
              _buildImageMenuOptions(context),

              // 底部安全区域
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建图片信息头部
  Widget _buildImageHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 图片图标
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CupertinoColors.systemPurple,
                  CupertinoColors.systemPurple.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemPurple.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.photo_fill,
              color: CupertinoColors.white,
              size: 28,
            ),
          ),

          const SizedBox(height: 16),

          // 标题
          const Text(
            '图片操作',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // 副标题
          const Text(
            '选择要执行的操作',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建菜单选项
  Widget _buildImageMenuOptions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildImageMenuOption(
            icon: CupertinoIcons.square_arrow_up,
            title: '用系统程序打开',
            subtitle: '使用默认图片查看器',
            color: CupertinoColors.systemPurple,
            onTap: () {
              Navigator.of(context).pop();
              _openImageWithSystemApp(context);
            },
          ),
          _buildImageMenuDivider(),
          _buildImageMenuOption(
            icon: CupertinoIcons.resize,
            title: '小图',
            subtitle: '30% 屏幕宽度',
            color: CupertinoColors.systemGreen,
            onTap: () {
              Navigator.of(context).pop();
              _resizeImage(ImageSize.small);
            },
          ),
          _buildImageMenuDivider(),
          _buildImageMenuOption(
            icon: CupertinoIcons.resize,
            title: '中图',
            subtitle: '60% 屏幕宽度',
            color: CupertinoColors.systemOrange,
            onTap: () {
              Navigator.of(context).pop();
              _resizeImage(ImageSize.medium);
            },
          ),
          _buildImageMenuDivider(),
          _buildImageMenuOption(
            icon: CupertinoIcons.resize,
            title: '大图',
            subtitle: '90% 屏幕宽度',
            color: CupertinoColors.systemYellow,
            onTap: () {
              Navigator.of(context).pop();
              _resizeImage(ImageSize.large);
            },
          ),
          _buildImageMenuDivider(),
          _buildImageMenuOption(
            icon: CupertinoIcons.trash_fill,
            title: '删除图片',
            subtitle: '此操作不可撤销',
            color: CupertinoColors.systemRed,
            isDestructive: true,
            onTap: () {
              Navigator.of(context).pop();
              _deleteImage();
            },
          ),
        ],
      ),
    );
  }

  /// 构建菜单选项
  Widget _buildImageMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 图标容器
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // 文本信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? CupertinoColors.systemRed
                          : CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),

            // 箭头图标
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey3,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建菜单分割线
  Widget _buildImageMenuDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 68),
      height: 0.5,
      color: CupertinoColors.systemGrey4.withValues(alpha: 0.6),
    );
  }

  // 用系统程序打开图片
  void _openImageWithSystemApp(BuildContext context) async {
    final src = widget.node.attributes[ImageBlockKeys.url] as String?;
    if (src == null || src.isEmpty) return;

    // 只支持本地文件
    if (src.startsWith('http')) {
      _showMessage(context, '网络图片无法用系统程序打开');
      return;
    }

    try {
      // 解析相对路径为绝对路径
      final absolutePath = await PathUtils.resolveRelativePath(src);
      final file = File(absolutePath);
      if (!await file.exists()) {
        _showMessage(context, '图片文件不存在');
        return;
      }

      print('🖼️ [ImageOpener] 尝试打开图片: $absolutePath');

      // 根据平台处理
      if (Platform.operatingSystem == 'ohos') {
        // 鸿蒙平台处理
        String filePath = "file://com.mrjguet.dream$absolutePath";
        print('🖼️ [OpenFilex-OHOS] 鸿蒙路径: $filePath');
        await OpenFilex.open(filePath);
        _showMessage(context, '图片已打开');
      } else if (Platform.isIOS) {
        // iOS平台处理
        print('🖼️ [OpenFilex-iOS] iOS路径: $absolutePath');
        await OpenFilex.open(absolutePath);
        _showMessage(context, '图片已打开');
      } else {
        // 其他平台暂不支持
        _showMessage(context, '当前平台暂不支持打开图片');
      }
    } catch (e) {
      // 静默处理异常
    }
  }

  // 调整图片大小
  void _resizeImage(ImageSize size) {
    final screenWidth = MediaQuery.of(context).size.width;
    double newWidth;

    switch (size) {
      case ImageSize.small:
        newWidth = screenWidth * 0.3; // 30% 屏幕宽度
        break;
      case ImageSize.medium:
        newWidth = screenWidth * 0.6; // 60% 屏幕宽度
        break;
      case ImageSize.large:
        newWidth = screenWidth * 0.9; // 90% 屏幕宽度
        break;
    }

    final transaction = editorState.transaction;
    transaction.updateNode(node, {
      ...node.attributes,
      ImageBlockKeys.width: newWidth,
    });
    editorState.apply(transaction);
  }

  // 删除图片（同时删除物理文件）
  Future<void> _deleteImage() async {
    // 先清理物理文件
    await MediaCleanup.deleteNodeFiles(node);
    final transaction = editorState.transaction;
    transaction.deleteNode(node);
    await editorState.apply(transaction);
  }

  // 显示消息
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// 图片大小枚举
enum ImageSize {
  small,
  medium,
  large,
}
