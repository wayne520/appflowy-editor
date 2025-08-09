import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// Default text color options when no option is provided
/// - support
///   - desktop
///   - web
///   - mobile
///
List<ColorOption> generateTextColorOptions() {
  return [
    ColorOption(
      colorHex: Colors.grey.toHex(),
      name: '灰色',
    ),
    ColorOption(
      colorHex: Colors.brown.toHex(),
      name: '棕色',
    ),
    ColorOption(
      colorHex: Colors.yellow.toHex(),
      name: '黄色',
    ),
    ColorOption(
      colorHex: Colors.green.toHex(),
      name: '绿色',
    ),
    ColorOption(
      colorHex: Colors.blue.toHex(),
      name: '蓝色',
    ),
    ColorOption(
      colorHex: Colors.purple.toHex(),
      name: '紫色',
    ),
    ColorOption(
      colorHex: Colors.pink.toHex(),
      name: '粉色',
    ),
    ColorOption(
      colorHex: Colors.red.toHex(),
      name: '红色',
    ),
  ];
}

/// Default background color options when no option is provided
/// - support
///   - desktop
///   - web
///   - mobile
///
List<ColorOption> generateHighlightColorOptions() {
  return [
    ColorOption(
      colorHex: Colors.grey.withValues(alpha: 0.3).toHex(),
      name: '灰色背景',
    ),
    ColorOption(
      colorHex: Colors.brown.withValues(alpha: 0.3).toHex(),
      name: '棕色背景',
    ),
    ColorOption(
      colorHex: Colors.yellow.withValues(alpha: 0.3).toHex(),
      name: '黄色背景',
    ),
    ColorOption(
      colorHex: Colors.green.withValues(alpha: 0.3).toHex(),
      name: '绿色背景',
    ),
    ColorOption(
      colorHex: Colors.blue.withValues(alpha: 0.3).toHex(),
      name: '蓝色背景',
    ),
    ColorOption(
      colorHex: Colors.purple.withValues(alpha: 0.3).toHex(),
      name: '紫色背景',
    ),
    ColorOption(
      colorHex: Colors.pink.withValues(alpha: 0.3).toHex(),
      name: '粉色背景',
    ),
    ColorOption(
      colorHex: Colors.red.withValues(alpha: 0.3).toHex(),
      name: '红色背景',
    ),
  ];
}
