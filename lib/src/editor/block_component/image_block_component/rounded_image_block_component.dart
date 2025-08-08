import 'dart:convert';
import 'dart:io';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

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

    // 获取圆角半径
    final borderRadius = attributes['borderRadius']?.toDouble() ?? 0.0;

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

  // 显示图片上下文菜单
  void _showImageContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _ImageContextMenu(
          onViewImage: () {
            Navigator.pop(context);
            _viewImageFullscreen(context);
          },
          onResizeSmall: () {
            Navigator.pop(context);
            _resizeImage(ImageSize.small);
          },
          onResizeMedium: () {
            Navigator.pop(context);
            _resizeImage(ImageSize.medium);
          },
          onResizeLarge: () {
            Navigator.pop(context);
            _resizeImage(ImageSize.large);
          },
          onDelete: () {
            Navigator.pop(context);
            _deleteImage();
          },
        );
      },
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

/// 自定义图片上下文菜单
class _ImageContextMenu extends StatelessWidget {
  const _ImageContextMenu({
    required this.onViewImage,
    required this.onResizeSmall,
    required this.onResizeMedium,
    required this.onResizeLarge,
    required this.onDelete,
  });

  final VoidCallback onViewImage;
  final VoidCallback onResizeSmall;
  final VoidCallback onResizeMedium;
  final VoidCallback onResizeLarge;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.photo_size_select_actual_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '图片操作',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 查看图片选项
          _buildMenuItem(
            context,
            icon: Icons.fullscreen_rounded,
            title: '查看图片',
            subtitle: '全屏查看原图',
            onTap: onViewImage,
          ),

          const Divider(height: 1),

          // 调整大小选项
          _buildMenuSection(
            context,
            title: '调整大小',
            icon: Icons.photo_size_select_large_rounded,
            children: [
              _buildMenuItem(
                context,
                icon: Icons.photo_size_select_small,
                title: '小图',
                subtitle: '30% 屏幕宽度',
                onTap: onResizeSmall,
              ),
              _buildMenuItem(
                context,
                icon: Icons.photo_size_select_actual,
                title: '中图',
                subtitle: '60% 屏幕宽度',
                onTap: onResizeMedium,
              ),
              _buildMenuItem(
                context,
                icon: Icons.photo_size_select_large,
                title: '大图',
                subtitle: '90% 屏幕宽度',
                onTap: onResizeLarge,
              ),
            ],
          ),

          const Divider(height: 1),

          // 删除选项
          _buildMenuItem(
            context,
            icon: Icons.delete_rounded,
            title: '删除图片',
            subtitle: '此操作不可撤销',
            onTap: onDelete,
            isDestructive: true,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDestructive
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
          return Image.asset(
            imageUrl,
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
