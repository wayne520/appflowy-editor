import 'dart:io';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第一行：选择现有媒体
          Row(
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
                  icon: const Icon(Icons.video_library),
                  label: const Text('选择视频'),
                  isSelected: false,
                  onPressed: () {
                    _handleVideoSelection();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 第二行：拍摄新媒体
          Row(
            children: [
              // 拍照选项
              Expanded(
                child: MobileToolbarItemMenuBtn(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('拍照'),
                  isSelected: false,
                  onPressed: () {
                    _handleTakePhoto();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // 录像选项
              Expanded(
                child: MobileToolbarItemMenuBtn(
                  icon: const Icon(Icons.videocam),
                  label: const Text('录像'),
                  isSelected: false,
                  onPressed: () {
                    _handleRecordVideo();
                  },
                ),
              ),
            ],
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
      print('📁 开始处理媒体文件: ${file.path}');
      print('📁 文件类型: $type');

      // 将文件复制到文档目录
      final permanentPath = await _copyFileToDocuments(file, type);
      print('📁 文件已复制到: $permanentPath');

      // 创建图片或视频节点
      Node mediaNode;
      if (type == 'image') {
        // 使用正确的图片块节点，添加圆角支持
        mediaNode = imageNode(
          url: permanentPath,
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
            'url': permanentPath,
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

  /// 处理拍照功能
  Future<void> _handleTakePhoto() async {
    try {
      // 使用相机拍照
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        await _insertMediaFile(photo, 'image');
      }
    } catch (e) {
      String errorMessage = '拍照失败';
      if (e.toString().contains('permission') ||
          e.toString().contains('Permission')) {
        errorMessage = '相机权限被拒绝，请在设置中允许应用访问相机';
      } else if (e.toString().contains('camera_access_denied')) {
        errorMessage = '相机访问被拒绝';
      } else if (e.toString().contains('No camera available')) {
        errorMessage = '设备没有可用的相机';
      }

      _showErrorMessage('$errorMessage: $e');
    }
  }

  /// 处理录像功能
  Future<void> _handleRecordVideo() async {
    try {
      // 使用相机录像
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10), // 最长10分钟
      );

      if (video != null) {
        await _insertMediaFile(video, 'video');
      }
    } catch (e) {
      String errorMessage = '录像失败';
      if (e.toString().contains('permission') ||
          e.toString().contains('Permission')) {
        errorMessage = '相机权限被拒绝，请在设置中允许应用访问相机';
      } else if (e.toString().contains('camera_access_denied')) {
        errorMessage = '相机访问被拒绝';
      } else if (e.toString().contains('No camera available')) {
        errorMessage = '设备没有可用的相机';
      }

      _showErrorMessage('$errorMessage: $e');
    }
  }

  /// 将文件复制到文档目录
  Future<String> _copyFileToDocuments(XFile file, String type) async {
    try {
      // 获取文档目录（优先 iCloud）
      final documentsDir = await getApplicationDocumentsDirectory();

      // 创建媒体文件夹
      final mediaDir = Directory(path.join(documentsDir.path, 'media'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
        print('📁 创建媒体目录: ${mediaDir.path}');
      }

      // 生成唯一文件名
      final originalFileName = path.basename(file.path);
      final extension = path.extension(originalFileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${type}_${timestamp}$extension';

      // 目标文件路径
      final targetPath = path.join(mediaDir.path, newFileName);

      print('📁 复制文件:');
      print('   源路径: ${file.path}');
      print('   目标路径: $targetPath');

      // 复制文件
      final sourceFile = File(file.path);
      final targetFile = await sourceFile.copy(targetPath);

      // 验证文件是否复制成功
      if (await targetFile.exists()) {
        final sourceSize = await sourceFile.length();
        final targetSize = await targetFile.length();
        print('📁 文件复制成功:');
        print('   源文件大小: $sourceSize bytes');
        print('   目标文件大小: $targetSize bytes');

        if (sourceSize == targetSize) {
          print('📁 ✅ 文件完整性验证通过');
        } else {
          print('📁 ⚠️ 文件大小不匹配，可能复制不完整');
        }

        // 返回相对路径而不是绝对路径
        final relativePath = 'media/$newFileName';
        print('📁 返回相对路径: $relativePath');
        return relativePath;
      } else {
        throw Exception('文件复制失败：目标文件不存在');
      }
    } catch (e) {
      print('📁 ❌ 复制文件到文档目录失败: $e');
      rethrow;
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
