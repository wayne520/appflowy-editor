import 'dart:io';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:path/path.dart' as p;
import 'package:appflowy_editor/src/infra/path_utils.dart' as path_utils;

/// 事件实例图片路径获取回调
typedef EventInstanceImagePathsCallback = Future<List<String>> Function(
    String eventInstanceId);

/// Utilities to cleanup media files from file system when corresponding nodes are deleted.
class MediaCleanup {
  /// 事件实例图片路径获取回调
  static EventInstanceImagePathsCallback? _eventInstanceImagePathsCallback;

  /// 设置事件实例图片路径获取回调
  static void setEventInstanceImagePathsCallback(
      EventInstanceImagePathsCallback callback) {
    _eventInstanceImagePathsCallback = callback;
  }

  /// Try to delete file(s) associated with the given node (async version).
  static Future<void> deleteNodeFiles(Node node) async {
    final rel = _extractRelativePath(node);
    // ignore: avoid_print
    print('[MediaCleanup] deleteNodeFiles type=${node.type} rel=$rel');
    if (rel == null || rel.isEmpty) return;
    try {
      final abs = await path_utils.PathUtils.resolveRelativePath(rel);
      await _safeDelete(abs);
    } catch (e) {
      // ignore: avoid_print
      print('[MediaCleanup] deleteNodeFiles error: $e');
    }
  }

  /// Try to delete file(s) associated with the given node (sync best-effort).
  /// This uses cached documents directory; if not available, it will no-op.
  static void deleteNodeFilesSync(Node node) {
    final rel = _extractRelativePath(node);
    // ignore: avoid_print
    print('[MediaCleanup] deleteNodeFilesSync type=${node.type} rel=$rel');
    if (rel == null || rel.isEmpty) return;
    try {
      final abs = _resolveRelativePathSync(rel);
      if (abs != null) {
        _safeDeleteSync(abs);
      }
    } catch (e) {
      // ignore: avoid_print
      print('[MediaCleanup] deleteNodeFilesSync error: $e');
    }
  }

  /// Extracts a relative path from node attributes based on node type.
  static String? _extractRelativePath(Node node) {
    final data = node.attributes;
    switch (node.type) {
      case 'image':
        return (data['url'] as String?)?.trim();
      case 'video':
        return (data['url'] as String?)?.trim();
      case 'voice_block':
        return (data['filePath'] as String?)?.trim();
      case 'file_block':
        return (data['filePath'] as String?)?.trim();
      case 'event':
        return _extractEventImagePaths(node);
      default:
        return null;
    }
  }

  /// Extracts image paths from event node's field values.
  static String? _extractEventImagePaths(Node eventNode) {
    final imagePaths = <String>[];

    // 检查新的事件块结构（只存储事件实例ID）
    final eventInstanceId = eventNode.attributes['eventInstanceId'] as String?;
    if (eventInstanceId != null) {
      // 对于新结构，我们无法在同步方法中访问数据库
      // 返回 null，让调用方使用异步方法处理
      return null;
    }

    // 兼容旧的事件块结构（有子节点）
    for (final child in eventNode.children) {
      if (child.type == 'event/field_value') {
        final value = child.attributes['value'];
        if (value is String && value.isNotEmpty) {
          // 检查是否是图片路径
          if (value.contains('/') &&
              (value.endsWith('.jpg') ||
                  value.endsWith('.jpeg') ||
                  value.endsWith('.png') ||
                  value.endsWith('.gif') ||
                  value.endsWith('.webp'))) {
            imagePaths.add(value);
          }
        }
      }
    }

    // 如果有多个图片，返回第一个（MediaCleanup 目前只支持单个路径）
    // 对于多个图片的情况，我们需要在调用处单独处理
    return imagePaths.isNotEmpty ? imagePaths.first : null;
  }

  /// Specialized cleanup for event nodes that may contain multiple images.
  static Future<void> deleteEventNodeFiles(Node eventNode) async {
    if (eventNode.type != 'event') return;

    final imagePaths = <String>[];

    // 检查新的事件块结构（只存储事件实例ID）
    final eventInstanceId = eventNode.attributes['eventInstanceId'] as String?;
    if (eventInstanceId != null) {
      // 从数据库加载事件实例数据来查找图片
      try {
        final instanceImagePaths =
            await _getEventInstanceImagePaths(eventInstanceId);
        imagePaths.addAll(instanceImagePaths);
      } catch (e) {
        // ignore: avoid_print
        print('[MediaCleanup] 加载事件实例数据失败: $e');
      }
    } else {
      // 兼容旧的事件块结构（有子节点）
      for (final child in eventNode.children) {
        if (child.type == 'event/field_value') {
          final value = child.attributes['value'];
          if (value is String && value.isNotEmpty) {
            // 检查是否是图片路径
            if (value.contains('/') &&
                (value.endsWith('.jpg') ||
                    value.endsWith('.jpeg') ||
                    value.endsWith('.png') ||
                    value.endsWith('.gif') ||
                    value.endsWith('.webp'))) {
              imagePaths.add(value);
            }
          }
        }
      }
    }

    // 删除所有图片文件
    for (final imagePath in imagePaths) {
      try {
        final abs = await path_utils.PathUtils.resolveRelativePath(imagePath);
        await _safeDelete(abs);
        // ignore: avoid_print
        print('[MediaCleanup] 已删除事件图片文件: $imagePath');
      } catch (e) {
        // ignore: avoid_print
        print('[MediaCleanup] 删除事件图片文件失败: $imagePath, 错误: $e');
      }
    }
  }

  /// 从事件实例数据中获取图片路径
  static Future<List<String>> _getEventInstanceImagePaths(
    String eventInstanceId,
  ) async {
    if (_eventInstanceImagePathsCallback == null) {
      // ignore: avoid_print
      print('[MediaCleanup] 事件实例图片路径获取回调未设置');
      return <String>[];
    }

    try {
      return await _eventInstanceImagePathsCallback!(eventInstanceId);
    } catch (e) {
      // ignore: avoid_print
      print('[MediaCleanup] 获取事件实例图片路径失败: $e');
      return <String>[];
    }
  }

  /// Specialized cleanup for event nodes (sync version).
  static void deleteEventNodeFilesSync(Node eventNode) {
    if (eventNode.type != 'event') return;

    final imagePaths = <String>[];

    // 检查新的事件块结构（只存储事件实例ID）
    final eventInstanceId = eventNode.attributes['eventInstanceId'] as String?;
    if (eventInstanceId != null) {
      // 对于新结构，我们无法在同步方法中访问数据库
      // 只能记录日志，实际清理由异步方法处理
      // ignore: avoid_print
      print('[MediaCleanup] 检测到新事件块结构，事件实例ID: $eventInstanceId');
      // ignore: avoid_print
      print('[MediaCleanup] 图片清理将由异步方法处理');
      return;
    }

    // 兼容旧的事件块结构（有子节点）
    for (final child in eventNode.children) {
      if (child.type == 'event/field_value') {
        final value = child.attributes['value'];
        if (value is String && value.isNotEmpty) {
          // 检查是否是图片路径
          if (value.contains('/') &&
              (value.endsWith('.jpg') ||
                  value.endsWith('.jpeg') ||
                  value.endsWith('.png') ||
                  value.endsWith('.gif') ||
                  value.endsWith('.webp'))) {
            imagePaths.add(value);
          }
        }
      }
    }

    // 删除所有图片文件
    for (final imagePath in imagePaths) {
      try {
        final abs = _resolveRelativePathSync(imagePath);
        if (abs != null) {
          _safeDeleteSync(abs);
          // ignore: avoid_print
          print('[MediaCleanup] 已删除事件图片文件: $imagePath');
        }
      } catch (e) {
        // ignore: avoid_print
        print('[MediaCleanup] 删除事件图片文件失败: $imagePath, 错误: $e');
      }
    }
  }

  static Future<void> _safeDelete(String absolutePath) async {
    final docDir = await path_utils.PathUtils.getDocumentsDirectory();
    if (!_isUnder(absolutePath, docDir.path)) return;
    final f = File(absolutePath);
    if (await f.exists()) {
      await f.delete();
    }
  }

  static void _safeDeleteSync(String absolutePath) {
    final docDirPath = path_utils.PathUtils.documentsPathSync;
    if (docDirPath == null) return;
    if (!_isUnder(absolutePath, docDirPath)) return;
    final f = File(absolutePath);
    if (f.existsSync()) {
      f.deleteSync();
    }
  }

  static bool _isUnder(String target, String dir) {
    final normalizedTarget = p.normalize(target);
    final normalizedDir = p.normalize(dir);
    return normalizedTarget.startsWith(normalizedDir);
  }

  static String? _resolveRelativePathSync(String relativePath) {
    if (p.isAbsolute(relativePath)) return relativePath;
    final docDirPath = path_utils.PathUtils.documentsPathSync;
    if (docDirPath == null) return null;
    return p.join(docDirPath, relativePath);
  }
}
