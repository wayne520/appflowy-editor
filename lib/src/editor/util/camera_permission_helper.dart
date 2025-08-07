import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 相机权限处理工具类
class CameraPermissionHelper {
  static const MethodChannel _channel = MethodChannel('camera_permission_helper');

  /// 检查相机权限
  static Future<bool> checkCameraPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkCameraPermission');
      return hasPermission;
    } catch (e) {
      debugPrint('检查相机权限失败: $e');
      return false;
    }
  }

  /// 请求相机权限
  static Future<bool> requestCameraPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestCameraPermission');
      return granted;
    } catch (e) {
      debugPrint('请求相机权限失败: $e');
      return false;
    }
  }

  /// 检查存储权限
  static Future<bool> checkStoragePermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkStoragePermission');
      return hasPermission;
    } catch (e) {
      debugPrint('检查存储权限失败: $e');
      return false;
    }
  }

  /// 请求存储权限
  static Future<bool> requestStoragePermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestStoragePermission');
      return granted;
    } catch (e) {
      debugPrint('请求存储权限失败: $e');
      return false;
    }
  }

  /// 打开应用设置页面
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('打开应用设置失败: $e');
    }
  }

  /// 显示权限说明对话框
  static Future<bool> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '去设置',
    String cancelText = '取消',
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// 检查并请求相机权限（带UI提示）
  static Future<bool> ensureCameraPermission(BuildContext context) async {
    // 首先检查权限
    bool hasPermission = await checkCameraPermission();
    
    if (hasPermission) {
      return true;
    }

    // 请求权限
    hasPermission = await requestCameraPermission();
    
    if (hasPermission) {
      return true;
    }

    // 权限被拒绝，显示说明对话框
    if (context.mounted) {
      final shouldOpenSettings = await showPermissionDialog(
        context,
        title: '需要相机权限',
        message: '为了拍照和录像，需要访问您的相机。请在设置中允许相机权限。',
      );

      if (shouldOpenSettings) {
        await openAppSettings();
      }
    }

    return false;
  }

  /// 检查并请求存储权限（带UI提示）
  static Future<bool> ensureStoragePermission(BuildContext context) async {
    // 首先检查权限
    bool hasPermission = await checkStoragePermission();
    
    if (hasPermission) {
      return true;
    }

    // 请求权限
    hasPermission = await requestStoragePermission();
    
    if (hasPermission) {
      return true;
    }

    // 权限被拒绝，显示说明对话框
    if (context.mounted) {
      final shouldOpenSettings = await showPermissionDialog(
        context,
        title: '需要存储权限',
        message: '为了保存照片和视频，需要访问您的存储空间。请在设置中允许存储权限。',
      );

      if (shouldOpenSettings) {
        await openAppSettings();
      }
    }

    return false;
  }

  /// 一次性检查所有必要权限
  static Future<bool> ensureAllPermissions(BuildContext context) async {
    final cameraPermission = await ensureCameraPermission(context);
    if (!cameraPermission) return false;

    final storagePermission = await ensureStoragePermission(context);
    return storagePermission;
  }

  /// 显示权限状态信息
  static Future<void> showPermissionStatus(BuildContext context) async {
    final cameraPermission = await checkCameraPermission();
    final storagePermission = await checkStoragePermission();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('权限状态'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPermissionStatusRow('相机权限', cameraPermission),
                const SizedBox(height: 8),
                _buildPermissionStatusRow('存储权限', storagePermission),
                const SizedBox(height: 16),
                const Text(
                  '如果权限被拒绝，您可以在系统设置中手动开启。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
              if (!cameraPermission || !storagePermission)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                  child: const Text('去设置'),
                ),
            ],
          );
        },
      );
    }
  }

  static Widget _buildPermissionStatusRow(String name, bool granted) {
    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.cancel,
          color: granted ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(name),
        const Spacer(),
        Text(
          granted ? '已授权' : '未授权',
          style: TextStyle(
            color: granted ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 获取权限状态描述
  static Future<Map<String, dynamic>> getPermissionStatus() async {
    final cameraPermission = await checkCameraPermission();
    final storagePermission = await checkStoragePermission();

    return {
      'camera': {
        'granted': cameraPermission,
        'description': cameraPermission ? '相机权限已授权' : '相机权限未授权',
      },
      'storage': {
        'granted': storagePermission,
        'description': storagePermission ? '存储权限已授权' : '存储权限未授权',
      },
      'allGranted': cameraPermission && storagePermission,
    };
  }

  /// 显示权限使用说明
  static void showPermissionGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('权限说明'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '为了提供完整的多媒体功能，应用需要以下权限：',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                
                Text('📷 相机权限', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('• 用于拍照和录像功能'),
                Text('• 直接在编辑器中捕获新内容'),
                SizedBox(height: 8),
                
                Text('💾 存储权限', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('• 用于保存拍摄的照片和视频'),
                Text('• 从相册中选择现有媒体文件'),
                SizedBox(height: 12),
                
                Text(
                  '您可以随时在系统设置中管理这些权限。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('了解'),
            ),
          ],
        );
      },
    );
  }
}
