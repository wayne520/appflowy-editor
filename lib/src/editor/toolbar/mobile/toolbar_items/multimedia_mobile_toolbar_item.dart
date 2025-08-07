import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

final multimediaMobileToolbarItem = MobileToolbarItem.withMenu(
  itemIconBuilder: (context, __, ___) => Icon(
    Icons.photo_camera,
    color: MobileToolbarTheme.of(context).iconColor,
    size: 20,
  ),
  itemMenuBuilder: (_, editorState, __) {
    final selection = editorState.selection;
    if (selection == null) {
      return const SizedBox.shrink();
    }
    return _MultimediaMenu(
      editorState: editorState,
      selection: selection,
    );
  },
);

class _MultimediaMenu extends StatefulWidget {
  const _MultimediaMenu({
    required this.editorState,
    required this.selection,
  });

  final Selection selection;
  final EditorState editorState;

  @override
  State<_MultimediaMenu> createState() => _MultimediaMenuState();
}

class _MultimediaMenuState extends State<_MultimediaMenu> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // 选择图片选项（支持多选）
          Expanded(
            child: MobileToolbarItemMenuBtn(
              icon: const Icon(Icons.photo_library),
              label: const Text('选择图片'),
              isSelected: false,
              onPressed: () {
                _handlePhotoAndVideo();
              },
            ),
          ),
          const SizedBox(width: 8),
          // 选择视频选项
          Expanded(
            child: MobileToolbarItemMenuBtn(
              icon: const Icon(Icons.videocam),
              label: const Text('选择视频'),
              isSelected: false,
              onPressed: () {
                _handleVideoSelection();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePhotoAndVideo() async {
    try {
      // 直接使用 getMedia 方法，支持同时选择照片和视频
      List<XFile> files;

      // 先尝试多选图片，这是最稳定的方法
      final imageFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      files = imageFiles.map((file) => XFile(file.path)).toList();

      // 插入选中的文件
      if (files.isNotEmpty) {
        for (final file in files) {
          final fileName = file.name.toLowerCase();
          String mediaType = 'image'; // 默认为图片

          if (fileName.endsWith('.mp4') ||
              fileName.endsWith('.mov') ||
              fileName.endsWith('.avi') ||
              fileName.endsWith('.mkv') ||
              fileName.endsWith('.webm') ||
              fileName.endsWith('.3gp') ||
              fileName.endsWith('.flv')) {
            mediaType = 'video';
          }

          await _insertMediaFile(file, mediaType, showSuccessMessage: false);
        }

        // 只在所有文件都添加完成后显示一次成功提示
        _showSuccessMessage('已添加 ${files.length} 个媒体文件');
      }
    } catch (e) {
      _showErrorMessage('选择媒体文件失败: $e');
    }
  }

  Future<void> _handleVideoSelection() async {
    try {
      print('开始选择视频...');

      // 尝试选择视频，添加详细的错误处理
      final videoFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 120), // 限制视频长度
      );

      print('视频选择结果: ${videoFile?.path}');

      if (videoFile != null) {
        print('开始插入视频文件...');
        await _insertMediaFile(videoFile, 'video');
        print('视频插入成功');
      } else {
        print('用户取消了视频选择');
      }
    } catch (e, stackTrace) {
      print('视频选择失败: $e');
      print('堆栈跟踪: $stackTrace');

      // 提供更详细的错误信息和解决方案
      String errorMessage = '选择视频失败';
      if (e.toString().contains('permission') ||
          e.toString().contains('Permission')) {
        errorMessage = '权限不足\n\n请在系统设置中允许应用访问：\n• 相机权限\n• 相册权限\n• 存储权限';
      } else {
        errorMessage =
            '选择视频失败\n\n可能的解决方案：\n• 检查应用权限设置\n• 重启应用后重试\n• 确保设备有足够存储空间';
      }

      _showErrorMessage(errorMessage);
    }
  }

  Future<void> _insertMediaFile(
    XFile file,
    String type, {
    bool showSuccessMessage = true,
  }) async {
    try {
      // 获取文件路径
      final path = file.path;

      // 创建图片或视频节点
      Node mediaNode;
      if (type == 'image') {
        // 使用正确的图片块节点，添加圆角支持
        mediaNode = imageNode(
          url: path,
          align: 'center', // 居中对齐
          width: 400.0, // 设置默认宽度
        );

        // 添加圆角属性（拖拽功能已通过 MobileLongPressDragBlockComponentBuilder 实现）
        mediaNode = mediaNode.copyWith(
          attributes: {
            ...mediaNode.attributes,
            'borderRadius': 12.0, // 圆角半径
          },
        );
      } else {
        // 对于视频，使用视频块节点
        mediaNode = Node(
          type: 'video',
          attributes: {
            'url': path,
            'align': 'center',
            'width': 400.0,
            'height': 225.0,
            'borderRadius': 12.0,
          },
        );
      }

      // 插入到编辑器中
      final transaction = widget.editorState.transaction;
      transaction.insertNode(widget.selection.end.path.next, mediaNode);
      await widget.editorState.apply(transaction);

      // 只在需要时显示成功消息
      if (showSuccessMessage) {
        _showSuccessMessage('${type == 'image' ? '图片' : '视频'}已添加');
      }
    } catch (e) {
      _showErrorMessage('插入媒体文件失败: $e');
    }
  }

  void _showSuccessMessage(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _IOSStyleToast(
        message: message,
        icon: CupertinoIcons.checkmark_circle_fill,
        iconColor: CupertinoColors.systemGreen,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // 自动关闭
    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showErrorMessage(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _IOSStyleToast(
        message: message,
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        iconColor: CupertinoColors.systemRed,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // 自动关闭
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

/// iOS 风格的 Toast 提示组件
class _IOSStyleToast extends StatefulWidget {
  const _IOSStyleToast({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.onDismiss,
  });

  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDismiss;

  @override
  State<_IOSStyleToast> createState() => _IOSStyleToastState();
}

class _IOSStyleToastState extends State<_IOSStyleToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.15,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color:
                        CupertinoColors.systemBackground.resolveFrom(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
