import 'dart:convert';
import 'dart:io';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
      imageWidget = Image.file(
        File(src),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorWidget(width, height),
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
            icon: CupertinoIcons.fullscreen,
            title: '查看图片',
            subtitle: '全屏查看原图',
            color: CupertinoColors.systemBlue,
            onTap: () {
              Navigator.of(context).pop();
              _viewImageFullscreen(context);
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

  // 全屏查看图片
  void _viewImageFullscreen(BuildContext context) {
    final src = widget.node.attributes[ImageBlockKeys.url] as String?;
    if (src == null || src.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullscreenImageViewer(imageUrl: src);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
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

  // 删除图片
  void _deleteImage() {
    final transaction = editorState.transaction;
    transaction.deleteNode(node);
    editorState.apply(transaction);
  }
}

// 图片大小枚举
enum ImageSize {
  small,
  medium,
  large,
}

/// 全屏图片查看器
class _FullscreenImageViewer extends StatelessWidget {
  const _FullscreenImageViewer({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // 图片
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: _buildImage(),
                ),
              ),
              // 关闭按钮
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // 网络图片
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else {
      // 本地图片或 base64
      try {
        if (imageUrl.startsWith('data:image')) {
          // base64 图片
          final base64String = imageUrl.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget();
            },
          );
        } else {
          // 本地文件
          return Image.file(
            File(imageUrl),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget();
            },
          );
        }
      } catch (e) {
        return _buildErrorWidget();
      }
    }
  }

  Widget _buildErrorWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.white54,
          ),
          SizedBox(height: 16),
          Text(
            '图片加载失败',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
