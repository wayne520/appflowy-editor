// 拍照和录像功能使用示例
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class CameraMultimediaExample extends StatefulWidget {
  const CameraMultimediaExample({super.key});

  @override
  State<CameraMultimediaExample> createState() => _CameraMultimediaExampleState();
}

class _CameraMultimediaExampleState extends State<CameraMultimediaExample> {
  late EditorState editorState;

  @override
  void initState() {
    super.initState();
    editorState = EditorState.blank();
    _initializeWithContent();
  }

  @override
  void dispose() {
    editorState.dispose();
    super.dispose();
  }

  void _initializeWithContent() {
    final transaction = editorState.transaction;
    
    transaction.insertNode([0], headingNode(
      level: 1,
      text: '📸 拍照和录像功能演示',
    ));
    
    transaction.insertNode([1], paragraphNode(
      text: '点击下方工具栏中的相机图标，体验全新的拍照和录像功能：',
    ));
    
    transaction.insertNode([2], bulletedListNode(
      text: '📷 拍照 - 使用设备相机拍摄照片',
    ));
    transaction.insertNode([3], bulletedListNode(
      text: '🎥 录像 - 录制视频内容',
    ));
    transaction.insertNode([4], bulletedListNode(
      text: '🖼️ 选择图片 - 从相册选择现有照片',
    ));
    transaction.insertNode([5], bulletedListNode(
      text: '📹 选择视频 - 从相册选择现有视频',
    ));
    transaction.insertNode([6], bulletedListNode(
      text: '⚡ 高质量拍照 - 拍摄高分辨率照片',
    ));
    transaction.insertNode([7], bulletedListNode(
      text: '🎬 长视频录制 - 录制长时间视频',
    ));
    
    editorState.apply(transaction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照录像功能'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showFeatureGuide,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showPermissionSettings,
          ),
        ],
      ),
      body: MobileToolbarV2(
        editorState: editorState,
        toolbarItems: [
          // 使用增强版多媒体工具栏项
          enhancedMultimediaMobileToolbarItem,
          
          // 或者使用标准版多媒体工具栏项
          // multimediaMobileToolbarItem,
          
          // 其他工具栏项
          textDecorationMobileToolbarItemV2,
          buildTextColorMobileToolbarItem(),
          buildHighlightColorMobileToolbarItem(),
          headingMobileToolbarItem,
          listMobileToolbarItem,
          linkMobileToolbarItem,
          dividerMobileToolbarItem,
        ],
        child: AppFlowyEditor(
          editorState: editorState,
          editorStyle: EditorStyle.mobile(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ),
    );
  }

  void _showFeatureGuide() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('📸 多媒体功能指南'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '拍摄功能',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                
                _FeatureItem(
                  icon: Icons.camera_alt,
                  title: '拍照',
                  description: '使用设备相机拍摄照片，自动插入到编辑器中',
                ),
                
                _FeatureItem(
                  icon: Icons.videocam,
                  title: '录像',
                  description: '录制视频内容，支持最长5分钟录制',
                ),
                
                _FeatureItem(
                  icon: Icons.camera_enhance,
                  title: '高质量拍照',
                  description: '拍摄高分辨率照片，适合需要高质量图像的场景',
                ),
                
                _FeatureItem(
                  icon: Icons.slow_motion_video,
                  title: '长视频录制',
                  description: '录制长达30分钟的视频内容',
                ),
                
                SizedBox(height: 16),
                Text(
                  '选择功能',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                
                _FeatureItem(
                  icon: Icons.photo_library,
                  title: '选择图片',
                  description: '从设备相册中选择现有照片，支持多选',
                ),
                
                _FeatureItem(
                  icon: Icons.video_library,
                  title: '选择视频',
                  description: '从设备相册中选择现有视频文件',
                ),
                
                SizedBox(height: 16),
                Text(
                  '💡 提示',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                SizedBox(height: 4),
                Text(
                  '• 首次使用需要授权相机和存储权限\n'
                  '• 拍摄的内容会自动保存到设备\n'
                  '• 支持各种常见的图片和视频格式\n'
                  '• 可以通过长按媒体内容进行编辑',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔐 权限设置'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '为了使用拍照和录像功能，需要以下权限：',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              
              _PermissionItem(
                icon: Icons.camera_alt,
                title: '相机权限',
                description: '用于拍照和录像功能',
                required: true,
              ),
              
              _PermissionItem(
                icon: Icons.storage,
                title: '存储权限',
                description: '用于保存和访问媒体文件',
                required: true,
              ),
              
              SizedBox(height: 16),
              Text(
                '如果权限被拒绝，您可以：',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text('1. 点击"去设置"按钮打开应用设置'),
              Text('2. 在权限管理中开启相应权限'),
              Text('3. 返回应用重新尝试功能'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('了解'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 这里可以调用权限检查
                // CameraPermissionHelper.showPermissionStatus(context);
              },
              child: const Text('检查权限'),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool required;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: required ? Colors.red : Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (required) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 使用示例
void main() {
  runApp(
    MaterialApp(
      title: '拍照录像功能演示',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const CameraMultimediaExample(),
    ),
  );
}

// 自定义多媒体工具栏配置示例
class CustomMultimediaToolbarExample extends StatefulWidget {
  const CustomMultimediaToolbarExample({super.key});

  @override
  State<CustomMultimediaToolbarExample> createState() => _CustomMultimediaToolbarExampleState();
}

class _CustomMultimediaToolbarExampleState extends State<CustomMultimediaToolbarExample> {
  late EditorState editorState;

  @override
  void initState() {
    super.initState();
    editorState = EditorState.blank();
  }

  @override
  void dispose() {
    editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义多媒体工具栏'),
      ),
      body: MobileToolbarV2(
        editorState: editorState,
        toolbarItems: [
          // 可以选择使用标准版或增强版
          multimediaMobileToolbarItem, // 标准版：4个选项
          // enhancedMultimediaMobileToolbarItem, // 增强版：6个选项
          
          // 其他工具栏项
          textDecorationMobileToolbarItemV2,
          headingMobileToolbarItem,
          listMobileToolbarItem,
        ],
        child: AppFlowyEditor(
          editorState: editorState,
          editorStyle: EditorStyle.mobile(),
        ),
      ),
    );
  }
}
