import 'dart:io';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:path/path.dart' as p;
import 'package:appflowy_editor/src/infra/path_utils.dart' as path_utils;

/// Utilities to cleanup media files from file system when corresponding nodes are deleted.
class MediaCleanup {
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
      default:
        return null;
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
