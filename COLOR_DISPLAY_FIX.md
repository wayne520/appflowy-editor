# 颜色显示问题修复

## 问题描述

用户反馈：虽然输入的文字颜色变了，但是工具栏显示的颜色没有更新。具体表现为：
1. 用户选择红色，输入文字确实是红色
2. 但工具栏图标没有显示当前选择的红色状态
3. 用户无法直观地看到当前激活的颜色格式

## 问题根因

原有的工具栏图标是静态的，不会根据当前的 `toggledStyle` 状态变化。虽然我们修复了颜色状态的持久化，但UI没有正确反映这个状态。

## 解决方案

### 1. 创建动态颜色图标组件

#### 文本颜色图标 (`_TextColorIcon`)
```dart
class _TextColorIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: editorState.toggledStyleNotifier,
      builder: (context, toggledStyle, child) {
        final textColorHex = toggledStyle[AppFlowyRichTextKeys.textColor] as String?;
        final hasTextColor = textColorHex != null;
        final textColor = textColorHex?.tryToColor() ?? style.iconColor;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // 文本颜色图标，使用当前选择的颜色
            Icon(
              Icons.format_color_text,
              color: hasTextColor ? textColor : style.iconColor,
            ),
            // 颜色下划线指示器
            if (hasTextColor)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 16,
                  height: 2,
                  decoration: BoxDecoration(
                    color: textColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

#### 背景色图标 (`_HighlightColorIcon`)
```dart
class _HighlightColorIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: editorState.toggledStyleNotifier,
      builder: (context, toggledStyle, child) {
        final backgroundColorHex = toggledStyle[AppFlowyRichTextKeys.backgroundColor] as String?;
        final hasBackgroundColor = backgroundColorHex != null;
        final backgroundColor = backgroundColorHex?.tryToColor() ?? Colors.yellow;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.format_color_fill, color: style.iconColor),
            // 颜色指示器圆点
            if (hasBackgroundColor)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 0.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

### 2. 创建独立的工具栏项

#### 文本颜色工具栏项
```dart
MobileToolbarItem buildTextColorMobileToolbarItem({
  List<ColorOption>? textColorOptions,
}) {
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, editorState, ___) => _TextColorIcon(
      editorState: editorState,
    ),
    itemMenuBuilder: (_, editorState, ___) {
      // 返回文本颜色选择菜单
    },
  );
}
```

#### 背景色工具栏项
```dart
MobileToolbarItem buildHighlightColorMobileToolbarItem({
  List<ColorOption>? backgroundColorOptions,
}) {
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, editorState, ___) => _HighlightColorIcon(
      editorState: editorState,
    ),
    itemMenuBuilder: (_, editorState, ___) {
      // 返回背景色选择菜单
    },
  );
}
```

### 3. 改进组合工具栏项

为原有的组合工具栏项也添加了动态颜色指示器：

```dart
class _ColorToolbarIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: editorState.toggledStyleNotifier,
      builder: (context, toggledStyle, child) {
        final textColorHex = toggledStyle[AppFlowyRichTextKeys.textColor] as String?;
        final backgroundColorHex = toggledStyle[AppFlowyRichTextKeys.backgroundColor] as String?;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            AFMobileIcon(afMobileIcons: AFMobileIcons.color),
            // 颜色指示器
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getIndicatorColor(textColorHex, backgroundColorHex),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 0.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
```

## 技术实现要点

### 1. 响应式UI更新
- 使用 `ValueListenableBuilder` 监听 `toggledStyleNotifier`
- 当 `toggledStyle` 变化时，图标自动更新显示

### 2. 视觉设计
- **文本颜色**：图标本身使用选择的颜色 + 底部下划线指示器
- **背景色**：保持图标原色 + 右下角圆点指示器
- **组合图标**：右下角圆点，优先显示文本颜色

### 3. 状态管理
- 图标直接从 `editorState.toggledStyle` 读取当前状态
- 支持颜色清除时的默认状态显示
- 兼容现有的颜色选择和应用逻辑

## 用户体验改进

### 修复前
- ❌ 工具栏图标静态，无法显示当前颜色状态
- ❌ 用户不知道当前激活的格式化选项
- ❌ 需要打开菜单才能看到选择的颜色

### 修复后
- ✅ 工具栏图标动态显示当前选择的颜色
- ✅ 用户可以一眼看到当前的格式化状态
- ✅ 颜色变化时图标实时更新
- ✅ 支持文本颜色和背景色的独立显示
- ✅ 提供了灵活的工具栏配置选项

## 使用方式

### 方案1：使用独立的颜色工具栏项（推荐）
```dart
toolbarItems: [
  buildTextColorMobileToolbarItem(),
  buildHighlightColorMobileToolbarItem(),
  // 其他工具栏项...
]
```

### 方案2：使用组合的颜色工具栏项
```dart
toolbarItems: [
  buildTextAndBackgroundColorMobileToolbarItem(),
  // 其他工具栏项...
]
```

### 方案3：自定义颜色选项
```dart
buildTextColorMobileToolbarItem(
  textColorOptions: [
    ColorOption(colorHex: Colors.red.toHex(), name: '红色'),
    ColorOption(colorHex: Colors.blue.toHex(), name: '蓝色'),
    // 更多自定义颜色...
  ],
)
```

## 总结

通过创建响应式的颜色图标组件，我们彻底解决了"颜色无法切换显示"的问题。现在用户可以：

1. **实时看到**当前选择的颜色状态
2. **直观了解**哪些格式化选项处于激活状态  
3. **快速识别**文本颜色和背景色的不同状态
4. **享受一致的**视觉反馈和用户体验

这个改进与之前的全局格式化持久性修复相结合，为用户提供了完整、直观、符合预期的颜色格式化体验。
