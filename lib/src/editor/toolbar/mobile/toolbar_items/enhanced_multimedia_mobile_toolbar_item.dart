import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

/// 增强版多媒体工具栏项，提供更多拍摄选项
final enhancedMultimediaMobileToolbarItem = MobileToolbarItem.withMenu(
  itemIconBuilder: (context, __, ___) => Icon(
    Icons.add_a_photo,
    color: MobileToolbarTheme.of(context).iconColor,
    size: 20,
  ),
  itemMenuBuilder: (_, editorState, __) {
    final selection = editorState.selection;
    if (selection == null) {
      return const SizedBox.shrink();
    }
    return _EnhancedMultimediaMenu(
      editorState: editorState,
      selection: selection,
    );
  },
);

class _EnhancedMultimediaMenu extends StatefulWidget {
  const _EnhancedMultimediaMenu({
    required this.editorState,
    required this.selection,
  });

  final EditorState editorState;
  final Selection selection;

  @override
  State<_EnhancedMultimediaMenu> createState() => _EnhancedMultimediaMenuState();
}

class _EnhancedMultimediaMenuState extends State<_EnhancedMultimediaMenu> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          const Text(
            '添加媒体',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // 拍摄选项
          _buildSectionTitle('拍摄'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.camera_alt,
                  label: '拍照',
                  color: Colors.blue,
                  onPressed: _handleTakePhoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.videocam,
                  label: '录像',
                  color: Colors.red,
                  onPressed: _handleRecordVideo,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 选择选项
          _buildSectionTitle('从相册选择'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.photo_library,
                  label: '选择图片',
                  color: Colors.green,
                  onPressed: _handleSelectImages,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.video_library,
                  label: '选择视频',
                  color: Colors.orange,
                  onPressed: _handleSelectVideo,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 高级选项
          _buildSectionTitle('高级选项'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.camera_enhance,
                  label: '高质量拍照',
                  color: Colors.purple,
                  onPressed: _handleTakeHighQualityPhoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.slow_motion_video,
                  label: '长视频录制',
                  color: Colors.teal,
                  onPressed: _handleRecordLongVideo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 拍照
  Future<void> _handleTakePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        await _insertMediaFile(photo, 'image');
        _showSuccessMessage('照片已添加');
      }
    } catch (e) {
      _handleCameraError(e, '拍照');
    }
  }

  /// 录像
  Future<void> _handleRecordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        await _insertMediaFile(video, 'video');
        _showSuccessMessage('视频已添加');
      }
    } catch (e) {
      _handleCameraError(e, '录像');
    }
  }

  /// 高质量拍照
  Future<void> _handleTakeHighQualityPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 95,
      );

      if (photo != null) {
        await _insertMediaFile(photo, 'image');
        _showSuccessMessage('高质量照片已添加');
      }
    } catch (e) {
      _handleCameraError(e, '高质量拍照');
    }
  }

  /// 长视频录制
  Future<void> _handleRecordLongVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 30),
      );

      if (video != null) {
        await _insertMediaFile(video, 'video');
        _showSuccessMessage('长视频已添加');
      }
    } catch (e) {
      _handleCameraError(e, '长视频录制');
    }
  }

  /// 选择图片
  Future<void> _handleSelectImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        for (final image in images) {
          await _insertMediaFile(image, 'image', showSuccessMessage: false);
        }
        _showSuccessMessage('已添加 ${images.length} 张图片');
      }
    } catch (e) {
      _showErrorMessage('选择图片失败: $e');
    }
  }

  /// 选择视频
  Future<void> _handleSelectVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        await _insertMediaFile(video, 'video');
        _showSuccessMessage('视频已添加');
      }
    } catch (e) {
      _showErrorMessage('选择视频失败: $e');
    }
  }

  /// 处理相机错误
  void _handleCameraError(dynamic error, String action) {
    String errorMessage = '$action失败';
    if (error.toString().contains('permission') || 
        error.toString().contains('Permission')) {
      errorMessage = '相机权限被拒绝，请在设置中允许应用访问相机';
    } else if (error.toString().contains('camera_access_denied')) {
      errorMessage = '相机访问被拒绝';
    } else if (error.toString().contains('No camera available')) {
      errorMessage = '设备没有可用的相机';
    }
    
    _showErrorMessage('$errorMessage: $error');
  }

  /// 插入媒体文件
  Future<void> _insertMediaFile(
    XFile file,
    String type, {
    bool showSuccessMessage = true,
  }) async {
    try {
      final path = file.path;
      Node mediaNode;
      
      if (type == 'image') {
        mediaNode = imageNode(
          url: path,
          align: 'center',
          width: 400.0,
        );
        mediaNode = mediaNode.copyWith(
          attributes: {
            ...mediaNode.attributes,
            'borderRadius': 12.0,
          },
        );
      } else {
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

      final transaction = widget.editorState.transaction;
      transaction.insertNode(widget.selection.end.path.next, mediaNode);
      await widget.editorState.apply(transaction);
    } catch (e) {
      _showErrorMessage('插入媒体文件失败: $e');
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
