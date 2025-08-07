import 'dart:io';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// 创建视频节点
Node videoNode({
  required String url,
  String align = 'center',
  double? width,
  double? height,
}) {
  return Node(
    type: VideoBlockKeys.type,
    attributes: {
      VideoBlockKeys.url: url,
      VideoBlockKeys.align: align,
      if (width != null) VideoBlockKeys.width: width,
      if (height != null) VideoBlockKeys.height: height,
    },
  );
}

/// 视频块组件的键
class VideoBlockKeys {
  static const String type = 'video';
  static const String url = 'url';
  static const String width = 'width';
  static const String height = 'height';
  static const String align = 'align';
}

/// 视频块组件构建器
class VideoBlockComponentBuilder extends BlockComponentBuilder {
  VideoBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return VideoBlockComponentWidget(
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
    );
  }

  @override
  BlockComponentValidate get validate =>
      (node) => node.delta == null && node.children.isEmpty;
}

class VideoBlockComponentWidget extends BlockComponentStatefulWidget {
  const VideoBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<VideoBlockComponentWidget> createState() =>
      _VideoBlockComponentWidgetState();
}

class _VideoBlockComponentWidgetState extends State<VideoBlockComponentWidget>
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

  final videoKey = GlobalKey();

  // 实现 DefaultSelectableMixin 需要的 keys
  @override
  GlobalKey get blockComponentKey => videoKey;

  @override
  GlobalKey get containerKey => videoKey;

  @override
  GlobalKey get forwardKey => videoKey;

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
    final src = attributes[VideoBlockKeys.url];

    final alignment = AlignmentExtension.fromString(
      attributes[VideoBlockKeys.align] ?? 'center',
    );
    final width = attributes[VideoBlockKeys.width]?.toDouble() ??
        MediaQuery.of(context).size.width;
    final height = attributes[VideoBlockKeys.height]?.toDouble() ?? 200.0;

    // 获取圆角半径
    final borderRadius = attributes['borderRadius']?.toDouble() ?? 12.0;

    Widget child = _buildVideoPlayer(
      src: src,
      width: width,
      height: height,
      borderRadius: borderRadius,
      alignment: alignment,
    );

    child = Padding(
      key: videoKey,
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

  Widget _buildVideoPlayer({
    required String src,
    required double width,
    required double height,
    required double borderRadius,
    required Alignment alignment,
  }) {
    // 创建视频预览容器
    Widget videoWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 视频缩略图或占位符
          _buildVideoThumbnail(src, width, height, borderRadius),

          // 播放按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          // 视频信息
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getVideoFileName(src),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // 应用对齐方式并添加长按功能
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: () => _playVideo(src),
        onLongPress: () => _showVideoContextMenu(context),
        child: videoWidget,
      ),
    );
  }

  Widget _buildVideoThumbnail(
    String src,
    double width,
    double height,
    double borderRadius,
  ) {
    // 这里可以实现视频缩略图生成
    // 目前使用占位符
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              '视频预览',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVideoFileName(String path) {
    return path.split('/').last;
  }

  void _playVideo(String src) {
    // 这里可以实现视频播放功能
    // 可以使用 video_player 插件或者系统默认播放器
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('播放视频: ${_getVideoFileName(src)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 显示视频上下文菜单
  void _showVideoContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _VideoContextMenu(
          onResizeSmall: () {
            Navigator.pop(context);
            _resizeVideo(VideoSize.small);
          },
          onResizeMedium: () {
            Navigator.pop(context);
            _resizeVideo(VideoSize.medium);
          },
          onResizeLarge: () {
            Navigator.pop(context);
            _resizeVideo(VideoSize.large);
          },
          onDelete: () {
            Navigator.pop(context);
            _deleteVideo();
          },
        );
      },
    );
  }

  // 调整视频大小
  void _resizeVideo(VideoSize size) {
    final screenWidth = MediaQuery.of(context).size.width;
    double newWidth;
    double newHeight;

    switch (size) {
      case VideoSize.small:
        newWidth = screenWidth * 0.3; // 30% 屏幕宽度
        newHeight = newWidth * 9 / 16; // 16:9 比例
        break;
      case VideoSize.medium:
        newWidth = screenWidth * 0.6; // 60% 屏幕宽度
        newHeight = newWidth * 9 / 16;
        break;
      case VideoSize.large:
        newWidth = screenWidth * 0.9; // 90% 屏幕宽度
        newHeight = newWidth * 9 / 16;
        break;
    }

    final transaction = editorState.transaction;
    transaction.updateNode(node, {
      ...node.attributes,
      VideoBlockKeys.width: newWidth,
      VideoBlockKeys.height: newHeight,
    });
    editorState.apply(transaction);
  }

  // 删除视频
  void _deleteVideo() {
    final transaction = editorState.transaction;
    transaction.deleteNode(node);
    editorState.apply(transaction);
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
      final videoBox = videoKey.currentContext?.findRenderObject();
      if (parentBox is RenderBox && videoBox is RenderBox) {
        return [
          videoBox.localToGlobal(Offset.zero, ancestor: parentBox) &
              videoBox.size,
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
}

// 视频大小枚举
enum VideoSize {
  small,
  medium,
  large,
}

/// 自定义视频上下文菜单
class _VideoContextMenu extends StatelessWidget {
  const _VideoContextMenu({
    required this.onResizeSmall,
    required this.onResizeMedium,
    required this.onResizeLarge,
    required this.onDelete,
  });

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
                  Icons.movie_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '视频操作',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 调整大小选项
          _buildMenuSection(
            context,
            title: '调整大小',
            icon: Icons.aspect_ratio_rounded,
            children: [
              _buildMenuItem(
                context,
                icon: Icons.video_library_outlined,
                title: '小视频',
                subtitle: '30% 屏幕宽度 (16:9)',
                onTap: onResizeSmall,
              ),
              _buildMenuItem(
                context,
                icon: Icons.video_library,
                title: '中视频',
                subtitle: '60% 屏幕宽度 (16:9)',
                onTap: onResizeMedium,
              ),
              _buildMenuItem(
                context,
                icon: Icons.video_library_rounded,
                title: '大视频',
                subtitle: '90% 屏幕宽度 (16:9)',
                onTap: onResizeLarge,
              ),
            ],
          ),

          const Divider(height: 1),

          // 删除选项
          _buildMenuItem(
            context,
            icon: Icons.delete_rounded,
            title: '删除视频',
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
