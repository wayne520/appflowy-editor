import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
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

          await _insertMediaFile(file, mediaType);
        }

        _showSuccessMessage('已添加 ${files.length} 个媒体文件');
      }
    } catch (e) {
      _showErrorMessage('选择媒体文件失败: $e');
    }
  }

  Future<void> _handleVideoSelection() async {
    try {
      // 选择视频文件
      final videoFile = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (videoFile != null) {
        await _insertMediaFile(videoFile, 'video');
        _showSuccessMessage('视频已添加');
      }
    } catch (e) {
      _showErrorMessage('选择视频失败: $e');
    }
  }

  Future<void> _insertMediaFile(XFile file, String type) async {
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
        // 对于视频，创建一个带有视频信息的段落节点
        // 因为 AppFlowy Editor 可能还没有专门的视频块
        mediaNode = paragraphNode(
          text: '🎥 视频文件: ${file.name}\n📁 路径: $path',
        );
      }

      // 插入到编辑器中
      final transaction = widget.editorState.transaction;
      transaction.insertNode(widget.selection.end.path.next, mediaNode);
      await widget.editorState.apply(transaction);

      // 显示成功消息
      _showSuccessMessage('${type == 'image' ? '图片' : '视频'}已添加');
    } catch (e) {
      _showErrorMessage('插入媒体文件失败: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
