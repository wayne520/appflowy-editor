# 全局格式化持久性改进

## 问题描述

在之前的实现中，AppFlowy Editor 的格式化选项（如文本颜色、背景色、加粗、斜体等）存在以下问题：

1. **样式丢失**：用户选择某个颜色并输入文字后，切换到新颜色时，新输入的文字仍然保持旧颜色
2. **不一致的行为**：与传统文字处理器（如 Microsoft Word）的行为不一致
3. **用户体验差**：用户需要反复选择格式化选项

## 解决方案

### 核心改进：全局持久化格式状态

实现了类似传统文字处理器的格式化行为：
- 用户选择的格式化选项（颜色、加粗、斜体等）成为**全局持久状态**
- 格式化选项保持活跃状态，直到用户**主动取消或更改**
- 所有后续输入的文字都自动应用当前的格式化状态

### 1. EditorState 修改

#### 移除自动清空逻辑
```dart
// 之前的实现 - 选择变化时自动清空样式
set selection(Selection? value) {
  if (selectionNotifier.value != value) {
    _toggledStyle.clear(); // ❌ 这会导致样式丢失
  }
  selectionNotifier.value = value;
}

// 新的实现 - 保持样式持久化
set selection(Selection? value) {
  // 保持 toggledStyle 持久化，不自动清空
  // 只有用户明确操作时才改变格式状态
  selectionNotifier.value = value;
}
```

### 2. 颜色选择器改进

#### 文本颜色选择器
```dart
onPressed: () {
  final newColor = isSelected ? null : e.colorHex;
  
  // 总是更新全局格式状态
  widget.editorState.updateToggledStyle(
    AppFlowyRichTextKeys.textColor,
    newColor,
  );
  
  // 如果有选中文本，同时应用到选中文本
  if (!selection.isCollapsed) {
    formatFontColor(
      widget.editorState,
      widget.editorState.selection,
      newColor,
    );
  }
}
```

#### 背景色选择器
```dart
onPressed: () {
  final newColor = isSelected ? null : e.colorHex;
  
  // 总是更新全局格式状态
  widget.editorState.updateToggledStyle(
    AppFlowyRichTextKeys.backgroundColor,
    newColor,
  );
  
  // 如果有选中文本，同时应用到选中文本
  if (!selection.isCollapsed) {
    formatHighlightColor(
      widget.editorState,
      widget.editorState.selection,
      newColor,
    );
  }
}
```

### 3. 文本装饰改进

#### 加粗、斜体等格式化选项
```dart
// 在 toggleAttribute 方法中
else {
  final isHighlight = nodes.allSatisfyInSelection(selection, (delta) {
    return delta.everyAttributes((attributes) => attributes[key] == true);
  });
  
  final newValue = !isHighlight;
  
  // 更新全局格式状态
  updateToggledStyle(key, newValue);
  
  // 应用到选中文本
  await formatDelta(selection, {key: newValue});
}
```

## 用户体验改进

### 使用场景示例

1. **连续输入相同格式**：
   - 用户选择红色文字
   - 输入 "Hello"
   - 继续输入 " World" - 自动保持红色
   - 移动光标到其他位置继续输入 - 仍然是红色

2. **格式化选中文本**：
   - 用户选择一段文字
   - 点击红色 - 选中文字变红色，同时设置全局格式为红色
   - 在其他位置输入新文字 - 自动使用红色

3. **更改格式**：
   - 用户点击蓝色 - 全局格式变为蓝色
   - 所有后续输入自动使用蓝色

4. **清除格式**：
   - 用户点击清除颜色按钮 - 全局格式清除
   - 后续输入使用默认颜色

## 技术实现细节

### 关键变更

1. **EditorState.selection setter**：移除了自动清空 `_toggledStyle` 的逻辑
2. **颜色选择器**：始终更新全局 `toggledStyle`，同时处理选中文本
3. **文本装饰**：在 `toggleAttribute` 中同时更新全局状态和选中文本
4. **清除按钮**：同时清除全局状态和选中文本的格式

### 兼容性

- ✅ 保持与现有 API 的兼容性
- ✅ 不影响现有的文本格式化功能
- ✅ 向后兼容所有现有的工具栏组件

## 测试验证

创建了全面的测试用例验证：
- 格式状态的全局持久性
- 光标移动时的格式保持
- 文本选择时的格式保持
- 跨行移动时的格式保持
- 多种格式同时应用的场景

## 总结

这个改进使 AppFlowy Editor 的格式化行为更加符合用户期望，提供了与主流文字处理器一致的用户体验。用户现在可以：

- 设置一次格式，持续使用
- 专注于内容创作，而不是反复设置格式
- 享受更流畅、更直观的编辑体验
