# 📸 拍照和录像功能

## 功能概述

为AppFlowy Editor的多媒体工具栏添加了完整的拍照和录像功能，用户现在可以：

- 📷 **直接拍照**：使用设备相机拍摄照片并插入编辑器
- 🎥 **录制视频**：录制视频内容并自动添加到文档中
- 🖼️ **选择图片**：从相册中选择现有照片（支持多选）
- 📹 **选择视频**：从相册中选择现有视频文件
- ⚡ **高质量拍照**：拍摄高分辨率照片
- 🎬 **长视频录制**：录制长时间视频内容

## 新增功能

### 1. 标准多媒体工具栏（已更新）

原有的 `multimediaMobileToolbarItem` 现在包含4个选项：

```dart
// 第一行：选择现有媒体
- 选择图片（从相册）
- 选择视频（从相册）

// 第二行：拍摄新媒体  
- 拍照（使用相机）
- 录像（使用相机）
```

### 2. 增强版多媒体工具栏（新增）

新的 `enhancedMultimediaMobileToolbarItem` 提供6个选项：

```dart
// 拍摄功能
- 拍照（标准质量）
- 录像（5分钟限制）

// 选择功能
- 选择图片（多选支持）
- 选择视频（单选）

// 高级功能
- 高质量拍照（4K分辨率）
- 长视频录制（30分钟限制）
```

## 技术实现

### 拍照功能
```dart
Future<void> _handleTakePhoto() async {
  try {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (photo != null) {
      await _insertMediaFile(photo, 'image');
      _showSuccessMessage('照片已添加');
    }
  } catch (e) {
    _handleCameraError(e, '拍照');
  }
}
```

### 录像功能
```dart
Future<void> _handleRecordVideo() async {
  try {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 5),
    );

    if (video != null) {
      await _insertMediaFile(video, 'video');
      _showSuccessMessage('视频已添加');
    }
  } catch (e) {
    _handleCameraError(e, '录像');
  }
}
```

### 高质量拍照
```dart
Future<void> _handleTakeHighQualityPhoto() async {
  final XFile? photo = await _picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 4096,  // 4K分辨率
    maxHeight: 4096,
    imageQuality: 95, // 高质量
  );
}
```

### 长视频录制
```dart
Future<void> _handleRecordLongVideo() async {
  final XFile? video = await _picker.pickVideo(
    source: ImageSource.camera,
    maxDuration: const Duration(minutes: 30), // 30分钟限制
  );
}
```

## 权限处理

### 自动权限检查
- 自动检测相机权限状态
- 智能提示用户授权权限
- 提供权限设置页面跳转

### 错误处理
```dart
void _handleCameraError(dynamic error, String action) {
  String errorMessage = '$action失败';
  if (error.toString().contains('permission')) {
    errorMessage = '相机权限被拒绝，请在设置中允许应用访问相机';
  } else if (error.toString().contains('No camera available')) {
    errorMessage = '设备没有可用的相机';
  }
  
  _showErrorMessage(errorMessage);
}
```

### 权限工具类
新增 `CameraPermissionHelper` 工具类：

```dart
// 检查并请求相机权限
await CameraPermissionHelper.ensureCameraPermission(context);

// 检查并请求存储权限
await CameraPermissionHelper.ensureStoragePermission(context);

// 显示权限状态
await CameraPermissionHelper.showPermissionStatus(context);

// 打开应用设置
await CameraPermissionHelper.openAppSettings();
```

## 用户界面

### 标准版界面
```
┌─────────────────────────────────────┐
│  选择图片    │    选择视频          │
├─────────────────────────────────────┤
│    拍照      │      录像            │
└─────────────────────────────────────┘
```

### 增强版界面
```
┌─────────────────────────────────────┐
│           添加媒体                   │
├─────────────────────────────────────┤
│              拍摄                    │
│    拍照      │      录像            │
├─────────────────────────────────────┤
│            从相册选择                │
│  选择图片    │    选择视频          │
├─────────────────────────────────────┤
│            高级选项                  │
│ 高质量拍照   │   长视频录制         │
└─────────────────────────────────────┘
```

## 使用方法

### 基础使用
```dart
MobileToolbarV2(
  editorState: editorState,
  toolbarItems: [
    multimediaMobileToolbarItem, // 标准版
    // 其他工具栏项...
  ],
  child: AppFlowyEditor(editorState: editorState),
)
```

### 增强版使用
```dart
MobileToolbarV2(
  editorState: editorState,
  toolbarItems: [
    enhancedMultimediaMobileToolbarItem, // 增强版
    // 其他工具栏项...
  ],
  child: AppFlowyEditor(editorState: editorState),
)
```

## 功能特性

### 媒体质量控制
- **标准拍照**：1920x1080，85%质量
- **高质量拍照**：4096x4096，95%质量
- **标准录像**：5分钟限制
- **长视频录制**：30分钟限制

### 多选支持
- 图片选择支持多选
- 批量插入多个图片
- 统一的成功提示

### 错误处理
- 权限被拒绝的友好提示
- 设备无相机的错误处理
- 网络或存储错误的处理

### 用户体验
- 直观的图标设计
- 清晰的功能分类
- 即时的操作反馈
- 权限引导流程

## 依赖要求

确保在 `pubspec.yaml` 中添加必要依赖：

```yaml
dependencies:
  image_picker: ^1.0.4
  
# 可选：用于更好的权限处理
  permission_handler: ^11.0.1
```

## 平台支持

- ✅ **iOS**：完整支持所有功能
- ✅ **Android**：完整支持所有功能
- ❌ **Web**：不支持相机功能
- ❌ **Desktop**：不支持相机功能

## 最佳实践

1. **权限处理**：在使用前检查并请求必要权限
2. **错误处理**：提供友好的错误提示和解决方案
3. **用户引导**：首次使用时提供功能说明
4. **性能优化**：合理设置图片质量和视频时长限制
5. **存储管理**：及时清理临时文件

## 总结

新增的拍照和录像功能为AppFlowy Editor提供了完整的多媒体内容创作能力。用户现在可以：

- 🚀 **快速创作**：直接拍摄内容无需切换应用
- 📱 **移动优化**：专为移动设备设计的交互体验
- 🎯 **精确控制**：多种质量和时长选项
- 🔒 **安全可靠**：完善的权限处理和错误管理
- 🎨 **灵活配置**：标准版和增强版满足不同需求

这些功能使AppFlowy Editor成为真正的移动端内容创作平台，为用户提供了从文字到多媒体的完整编辑体验。
