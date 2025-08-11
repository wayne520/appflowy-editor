import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 路径工具类 - 处理相对路径和绝对路径的转换
class PathUtils {
  static Directory? _documentsDir;
  
  /// 初始化文档目录
  static Future<void> initialize() async {
    _documentsDir ??= await getApplicationDocumentsDirectory();
  }
  
  /// 获取文档目录
  static Future<Directory> getDocumentsDirectory() async {
    if (_documentsDir == null) {
      await initialize();
    }
    return _documentsDir!;
  }
  
  /// 将相对路径转换为绝对路径
  /// 
  /// 输入: "media/video_123456789.mov"
  /// 输出: "/Documents/media/video_123456789.mov"
  static Future<String> resolveRelativePath(String relativePath) async {
    // 如果已经是绝对路径，直接返回
    if (path.isAbsolute(relativePath)) {
      return relativePath;
    }
    
    final documentsDir = await getDocumentsDirectory();
    final absolutePath = path.join(documentsDir.path, relativePath);
    
    return absolutePath;
  }
  
  /// 将绝对路径转换为相对路径（相对于文档目录）
  /// 
  /// 输入: "/Documents/media/video_123456789.mov"
  /// 输出: "media/video_123456789.mov"
  static Future<String> makeRelativePath(String absolutePath) async {
    final documentsDir = await getDocumentsDirectory();
    final documentsPath = documentsDir.path;
    
    // 如果路径在文档目录下，返回相对路径
    if (absolutePath.startsWith(documentsPath)) {
      final relativePath = path.relative(absolutePath, from: documentsPath);
      return relativePath;
    }
    
    // 如果不在文档目录下，返回原路径
    return absolutePath;
  }
  
  /// 检查文件是否存在（支持相对路径）
  static Future<bool> fileExists(String filePath) async {
    final absolutePath = await resolveRelativePath(filePath);
    final file = File(absolutePath);
    return await file.exists();
  }
  
  /// 获取文件大小（支持相对路径）
  static Future<int> getFileSize(String filePath) async {
    final absolutePath = await resolveRelativePath(filePath);
    final file = File(absolutePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
  
  /// 获取文件的显示名称
  static String getDisplayName(String filePath) {
    return path.basename(filePath);
  }
  
  /// 获取文件扩展名
  static String getExtension(String filePath) {
    return path.extension(filePath);
  }
  
  /// 检查是否为媒体文件
  static bool isMediaFile(String filePath) {
    final extension = getExtension(filePath).toLowerCase();
    return _isImageFile(extension) || _isVideoFile(extension) || _isAudioFile(extension);
  }
  
  /// 检查是否为图片文件
  static bool isImageFile(String filePath) {
    final extension = getExtension(filePath).toLowerCase();
    return _isImageFile(extension);
  }
  
  /// 检查是否为视频文件
  static bool isVideoFile(String filePath) {
    final extension = getExtension(filePath).toLowerCase();
    return _isVideoFile(extension);
  }
  
  /// 检查是否为音频文件
  static bool isAudioFile(String filePath) {
    final extension = getExtension(filePath).toLowerCase();
    return _isAudioFile(extension);
  }
  
  static bool _isImageFile(String extension) {
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }
  
  static bool _isVideoFile(String extension) {
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp', '.flv'].contains(extension);
  }
  
  static bool _isAudioFile(String extension) {
    return ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'].contains(extension);
  }
  
  /// 创建媒体目录（如果不存在）
  static Future<Directory> ensureMediaDirectory() async {
    final documentsDir = await getDocumentsDirectory();
    final mediaDir = Directory(path.join(documentsDir.path, 'media'));
    
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    
    return mediaDir;
  }
  
  /// 生成唯一的媒体文件名
  static String generateMediaFileName(String type, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${type}_$timestamp$extension';
  }
  
  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// 清理路径（移除多余的分隔符等）
  static String cleanPath(String filePath) {
    return path.normalize(filePath);
  }
  
  /// 验证路径安全性（防止路径遍历攻击）
  static bool isPathSafe(String filePath) {
    // 检查是否包含危险的路径组件
    final normalizedPath = path.normalize(filePath);
    
    // 不允许包含 .. 或绝对路径（除非在文档目录下）
    if (normalizedPath.contains('..') || 
        (path.isAbsolute(normalizedPath) && !normalizedPath.contains('Documents'))) {
      return false;
    }
    
    return true;
  }
  
  /// 迁移旧的绝对路径到相对路径
  static Future<String> migrateToRelativePath(String oldPath) async {
    // 如果已经是相对路径，直接返回
    if (!path.isAbsolute(oldPath)) {
      return oldPath;
    }
    
    // 尝试转换为相对路径
    final relativePath = await makeRelativePath(oldPath);
    
    // 验证文件是否存在
    if (await fileExists(relativePath)) {
      return relativePath;
    } else {
      return oldPath; // 返回原路径
    }
  }
}
