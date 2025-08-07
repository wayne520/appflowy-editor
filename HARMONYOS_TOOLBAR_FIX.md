# HarmonyOS 工具栏修复说明

## 问题描述

在鸿蒙系统上，AppFlowy Editor 的移动端工具栏存在两个主要问题：
1. 工具栏没有正确显示在输入法上方
2. 工具栏与输入法之间的空白区域是白色的，而输入法背景是灰色的，造成明显的视觉断层

## 解决方案

### 1. 平台检测增强

在 `lib/src/editor/util/platform_extension.dart` 中添加了鸿蒙系统检测：

```dart
/// Returns true if the operating system is HarmonyOS/OpenHarmony.
static bool get isHarmonyOS {
  if (kIsWeb) return false;
  try {
    // Check if running on HarmonyOS by examining system properties
    return Platform.operatingSystem.toLowerCase().contains('harmony') ||
           Platform.operatingSystem.toLowerCase().contains('ohos') ||
           Platform.environment.containsKey('OHOS_SDK_HOME') ||
           Platform.environment.containsKey('HARMONY_HOME');
  } catch (e) {
    return false;
  }
}
```

### 2. 工具栏键盘高度处理

在 `lib/src/editor/toolbar/mobile/mobile_toolbar_v2.dart` 中：

#### 键盘高度变化处理
```dart
void _onKeyboardHeightChanged(double height) {
  // ... 现有逻辑 ...
  
  // Special handling for HarmonyOS to ensure toolbar appears above keyboard
  else if (PlatformExtension.isHarmonyOS) {
    if (cachedKeyboardHeight.value != 0) {
      cachedKeyboardHeight.value +=
          MediaQuery.of(context).viewPadding.bottom;
    }
  }
}
```

#### 键盘高度计算方法
添加了专门的键盘高度计算方法：

```dart
double _calculateKeyboardHeight(BuildContext context, double cachedHeight, bool showingMenu) {
  var keyboardHeight = cachedHeight;
  
  if (PlatformExtension.isHarmonyOS) {
    if (!showingMenu) {
      final currentViewInsets = MediaQuery.of(context).viewInsets.bottom;
      keyboardHeight = max(keyboardHeight, currentViewInsets);
      
      // Add additional padding for HarmonyOS to ensure proper positioning
      if (keyboardHeight > 0) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        keyboardHeight = max(keyboardHeight, currentViewInsets + bottomPadding);
      }
    }
  }
  
  return keyboardHeight;
}
```

### 3. 键盘高度观察器优化

在 `lib/src/editor/toolbar/mobile/utils/keyboard_height_observer.dart` 中添加了鸿蒙系统的重复通知过滤：

```dart
void notify(double height) {
  // Similar handling for HarmonyOS to avoid duplicate notifications
  if (PlatformExtension.isHarmonyOS && height == currentKeyboardHeight) {
    return;
  }
  
  for (final listener in _listeners) {
    listener(height);
  }
}
```

## 技术原理

### 问题根因
1. **平台识别问题**：鸿蒙系统可能被错误识别为 Android，导致使用了不适合的键盘处理逻辑
2. **键盘高度计算差异**：鸿蒙系统的键盘高度计算方式与标准 Android 存在差异
3. **视图边距处理**：鸿蒙系统的 `viewInsets` 和 `viewPadding` 行为可能与其他平台不同

### 解决策略
1. **精确平台检测**：通过多种方式检测鸿蒙系统环境
2. **专用键盘处理**：为鸿蒙系统提供专门的键盘高度计算逻辑
3. **动态高度调整**：结合 `viewInsets` 和 `viewPadding` 确保工具栏正确定位

## 使用方法

修改完成后，在鸿蒙系统上运行应用时：

1. 工具栏会自动检测鸿蒙系统环境
2. 当键盘弹出时，工具栏会正确计算高度并显示在键盘上方
3. 工具栏菜单展开时会正确处理高度变化

## 测试验证

运行测试确保平台检测正常工作：

```bash
flutter test test/editor/util/platform_extension_test.dart
```

### 4. 视觉优化

为了解决工具栏与输入法之间的视觉断层问题，添加了专门的间距背景处理：

#### 动态背景色适配
```dart
Color _getHarmonyOSSpacerColor(BuildContext context) {
  final theme = Theme.of(context);
  final brightness = theme.brightness;

  if (brightness == Brightness.dark) {
    return const Color(0xFF2C2C2C); // 深色主题
  } else {
    return const Color(0xFFF5F5F5); // 浅色主题
  }
}
```

#### 间距区域构建
```dart
Widget _buildKeyboardSpacer(BuildContext context, double height) {
  if (PlatformExtension.isHarmonyOS) {
    final spacerColor = _getHarmonyOSSpacerColor(context);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: spacerColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            spacerColor.withOpacity(0.95),
            spacerColor,
          ],
        ),
      ),
    );
  }

  return SizedBox(height: height);
}
```

## 注意事项

1. 这个修复专门针对鸿蒙系统的键盘行为特性和视觉体验
2. 背景色会根据系统主题（深色/浅色）自动适配
3. 如果鸿蒙系统的键盘行为在未来版本中发生变化，可能需要调整相关参数
4. 建议在实际鸿蒙设备上进行充分测试以验证效果
