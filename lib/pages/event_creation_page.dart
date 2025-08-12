import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/event_data.dart';
import '../models/event_category.dart';
import '../components/event_creation/event_basic_info_section.dart';
import '../components/event_creation/event_fields_section.dart';

/// 事件创建/编辑页面
class EventCreationPage extends StatefulWidget {
  const EventCreationPage({
    super.key,
    this.initialEventType,
    this.isEditing = false,
    this.existingEventData,
  });

  /// 初始事件类型（用于从模板创建）
  final String? initialEventType;
  
  /// 是否为编辑模式
  final bool isEditing;
  
  /// 现有事件数据（编辑模式时使用）
  final EventData? existingEventData;

  @override
  State<EventCreationPage> createState() => _EventCreationPageState();
}

class _EventCreationPageState extends State<EventCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // 基本信息
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _selectedIcon = '📝';
  String _selectedCategory = 'personal';
  String? _selectedColor;
  
  // 字段列表
  List<EventField> _fields = [];
  
  // 是否有未保存的更改
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    
    // 监听文本变化
    _nameController.addListener(_onDataChanged);
    _descriptionController.addListener(_onDataChanged);
  }

  void _loadInitialData() {
    if (widget.isEditing && widget.existingEventData != null) {
      // 编辑模式：加载现有数据
      final eventData = widget.existingEventData!;
      _nameController.text = eventData.template.name;
      _descriptionController.text = eventData.template.description;
      _selectedIcon = eventData.template.icon;
      _selectedCategory = eventData.category;
      _selectedColor = eventData.template.color;
      _fields = List.from(eventData.template.fields);
    } else if (widget.initialEventType != null) {
      // 从模板创建：加载模板数据
      final eventType = EventCategories.getEventTypeByFullType(widget.initialEventType!);
      if (eventType != null) {
        _nameController.text = eventType.name;
        _descriptionController.text = eventType.description;
        _selectedIcon = eventType.icon;
        _selectedCategory = eventType.getFullType('').split('.')[0];
        _fields = List.from(eventType.template.fields);
      }
    } else {
      // 全新创建：使用默认值
      _nameController.text = '新事件';
      _descriptionController.text = '';
      _fields = [
        const EventField(
          id: 'title',
          name: '标题',
          type: EventFieldType.text,
          required: false,
          description: '事件标题',
        ),
      ];
    }
  }

  void _onDataChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _onFieldsChanged(List<EventField> newFields) {
    setState(() {
      _fields = newFields;
      _hasUnsavedChanges = true;
    });
  }

  void _onBasicInfoChanged() {
    _onDataChanged();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('您有未保存的更改，确定要离开吗？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('离开'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 创建事件模板
    final template = EventTemplate(
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      description: _descriptionController.text.trim(),
      fields: _fields,
      color: _selectedColor,
    );

    // 创建事件数据
    final eventData = EventData(
      id: widget.existingEventData?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      eventType: '$_selectedCategory.custom_${DateTime.now().millisecondsSinceEpoch}',
      displayStyle: 'card',
      template: template,
      fieldValues: {},
      createdAt: widget.existingEventData?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 返回结果
    Navigator.of(context).pop(eventData);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.isEditing ? '编辑事件' : '创建事件'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _hasUnsavedChanges ? _saveEvent : null,
            child: Text(
              '保存',
              style: TextStyle(
                color: _hasUnsavedChanges
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.inactiveGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 基本信息部分
              SliverToBoxAdapter(
                child: EventBasicInfoSection(
                  nameController: _nameController,
                  descriptionController: _descriptionController,
                  selectedIcon: _selectedIcon,
                  selectedCategory: _selectedCategory,
                  selectedColor: _selectedColor,
                  onIconChanged: (icon) {
                    setState(() {
                      _selectedIcon = icon;
                    });
                    _onBasicInfoChanged();
                  },
                  onCategoryChanged: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                    _onBasicInfoChanged();
                  },
                  onColorChanged: (color) {
                    setState(() {
                      _selectedColor = color;
                    });
                    _onBasicInfoChanged();
                  },
                ),
              ),
              
              // 分隔线
              const SliverToBoxAdapter(
                child: Divider(height: 32),
              ),
              
              // 字段配置部分
              SliverToBoxAdapter(
                child: EventFieldsSection(
                  fields: _fields,
                  onFieldsChanged: _onFieldsChanged,
                ),
              ),
              
              // 底部间距
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
