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

    // 应用对齐方式
    return Align(
      alignment: alignment,
      child: imageWidget,
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
}
