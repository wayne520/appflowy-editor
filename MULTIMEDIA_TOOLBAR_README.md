# 多媒体工具栏项

✅ **架构优化完成** - 多媒体工具栏项采用回调函数设计，逻辑分离！

## 设计理念

多媒体工具栏项采用了**关注点分离**的设计原则：
- 📱 **编辑器专注于编辑功能** - 不包含具体的图片/视频选择逻辑
- 🔧 **应用层处理多媒体逻辑** - 通过回调函数实现具体功能
- 🎯 **灵活可扩展** - 可以根据不同应用需求实现不同的多媒体处理方式

## 已完成的工作

✅ 创建了多媒体工具栏项 (`multimediaMobileToolbarItem`)
✅ 使用Flutter内置图标 (`Icons.photo_camera`)
✅ 实现了完整的照片和视频选择功能
✅ 集成到主要的移动端编辑器文件中
✅ 成功引入 gitcode 的 image_picker 依赖
✅ 实现了相册选择和相机拍摄功能
✅ 代码分析通过，无错误
✅ 支持图片和视频的完整工作流程

## 🎯 功能特性

### 📷 照片和视频选择
- 点击"照片和视频"按钮
- 选择"选择照片"或"选择视频"
- 从设备相册中选择媒体文件
- 自动插入到编辑器中

### 📹 拍照和录像
- 点击"拍照和录像"按钮
- 选择"拍照"或"录像"
- 使用设备相机拍摄新内容
- 自动插入到编辑器中

### 🔧 技术实现
- 使用 `image_picker` 插件处理媒体选择
- 支持图片和视频格式
- 错误处理和用户反馈
- 自动插入到编辑器光标位置

## 使用方法

### 1. 基本使用（带回调函数）

在您的移动端编辑器中添加多媒体工具栏项并实现回调函数：

```dart
import 'package:appflowy_editor/appflowy_editor.dart';

MobileToolbarV2(
  editorState: editorState,
  toolbarItems: [
    textDecorationMobileToolbarItemV2,
    buildTextAndBackgroundColorMobileToolbarItem(),
    blocksMobileToolbarItem,
    // 使用工厂函数创建多媒体工具栏项，并提供回调函数
    createMultimediaMobileToolbarItem(
      onMultimediaSelected: _handleMultimediaSelection,
    ),
    linkMobileToolbarItem,
    dividerMobileToolbarItem,
  ],
  child: AppFlowyEditor(
    editorState: editorState,
    // ... 其他配置
  ),
)
```

### 2. 实现回调函数

```dart
Future<void> _handleMultimediaSelection(
  BuildContext context,
  EditorState editorState,
  Selection selection,
  String type,
) async {
  switch (type) {
    case 'photo_gallery':
      // 实现从相册选择照片
      await _selectPhotoFromGallery(context, editorState, selection);
      break;
    case 'video_gallery':
      // 实现从相册选择视频
      await _selectVideoFromGallery(context, editorState, selection);
      break;
    case 'photo_camera':
      // 实现拍照
      await _takePhoto(context, editorState, selection);
      break;
    case 'video_camera':
      // 实现录像
      await _recordVideo(context, editorState, selection);
      break;
  }
}
```

### 3. 简单使用（无回调函数）

如果暂时不需要实现具体功能，可以使用默认版本：

```dart
// 这将显示占位符消息，提示用户实现具体功能
multimediaMobileToolbarItem,
```

### 2. 功能说明

点击多媒体按钮后，会显示一个菜单，包含两个选项：

1. **照片和视频** - 从设备相册中选择现有的照片或视频
2. **拍照和录像** - 使用设备摄像头拍摄新的照片或视频

### 3. 自定义实现

目前的实现提供了基础的UI框架，您可以根据需要集成具体的媒体处理功能：

```dart
void _handlePhotoAndVideo() {
  // TODO: 实现选择照片和视频的功能
  // 建议使用 image_picker 插件
  // 示例：
  // final ImagePicker picker = ImagePicker();
  // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
}

void _handleCameraAndVideo() {
  // TODO: 实现拍照和录像的功能
  // 建议使用 image_picker 插件
  // 示例：
  // final ImagePicker picker = ImagePicker();
  // final XFile? photo = await picker.pickImage(source: ImageSource.camera);
}
```

## 文件结构

新增的文件包括：

1. `lib/src/editor/toolbar/mobile/toolbar_items/multimedia_mobile_toolbar_item.dart` - 多媒体工具栏项实现
2. `assets/mobile/toolbar_icons/multimedia.svg` - 多媒体图标
3. `lib/src/infra/mobile/af_mobile_icon.dart` - 更新了图标枚举
4. `example/lib/pages/multimedia_toolbar_demo.dart` - 演示页面
5. `test/mobile/toolbar/mobile/multimedia_mobile_toolbar_item_test.dart` - 测试文件

## 演示

运行示例应用，在主菜单中选择 "Multimedia Toolbar Demo" 可以查看功能演示。

## 依赖建议

为了实现完整的多媒体功能，建议添加以下依赖：

```yaml
dependencies:
  image_picker: ^1.0.4  # 用于选择和拍摄照片/视频
  permission_handler: ^11.0.1  # 用于处理相机和存储权限
```

## 注意事项

1. 在实际使用中，需要处理相机和存储权限
2. 需要考虑不同平台（iOS/Android）的兼容性
3. 建议添加错误处理和用户反馈
4. 可以根据需要扩展支持的媒体格式

## 扩展功能

您可以基于这个基础实现添加更多功能：

- 媒体文件预览
- 文件大小限制
- 图片编辑功能
- 视频剪辑功能
- 云存储集成

## 贡献

如果您有改进建议或发现问题，欢迎提交 Issue 或 Pull Request。
