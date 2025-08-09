import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final blocksMobileToolbarItem = MobileToolbarItem.withMenu(
  itemIconBuilder: (context, __, ___) => AFMobileIcon(
    afMobileIcons: AFMobileIcons.list,
    color: MobileToolbarTheme.of(context).iconColor,
  ),
  itemMenuBuilder: (_, editorState, __) {
    final selection = editorState.selection;
    if (selection == null) {
      return const SizedBox.shrink();
    }
    return _BlocksMenu(editorState, selection);
  },
);

class _BlocksMenu extends StatefulWidget {
  const _BlocksMenu(
    this.editorState,
    this.selection,
  );

  final Selection selection;
  final EditorState editorState;

  @override
  State<_BlocksMenu> createState() => _BlocksMenuState();
}

class _BlocksMenuState extends State<_BlocksMenu> {
  final lists = [
    // heading
    _ListUnit(
      icon: AFMobileIcons.h1,
      label: '标题1',
      name: HeadingBlockKeys.type,
      level: 1,
    ),
    _ListUnit(
      icon: AFMobileIcons.h2,
      label: '标题2',
      name: HeadingBlockKeys.type,
      level: 2,
    ),
    _ListUnit(
      icon: AFMobileIcons.h3,
      label: '标题3',
      name: HeadingBlockKeys.type,
      level: 3,
    ),
    // list
    _ListUnit(
      icon: AFMobileIcons.bulletedList,
      label: '项目符号',
      name: BulletedListBlockKeys.type,
    ),
    _ListUnit(
      icon: AFMobileIcons.numberedList,
      label: '编号列表',
      name: NumberedListBlockKeys.type,
    ),
    _ListUnit(
      icon: AFMobileIcons.checkbox,
      label: '待办事项',
      name: TodoListBlockKeys.type,
    ),
    _ListUnit(
      icon: AFMobileIcons.quote,
      label: '引用',
      name: QuoteBlockKeys.type,
    ),
  ];

  final alignmentOptions = [
    _AlignmentUnit(
      icon: Icons.format_align_left,
      label: '左对齐',
      align: 'left',
    ),
    _AlignmentUnit(
      icon: Icons.format_align_center,
      label: '居中',
      align: 'center',
    ),
    _AlignmentUnit(
      icon: Icons.format_align_right,
      label: '右对齐',
      align: 'right',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final style = MobileToolbarTheme.of(context);
    final node = widget.editorState.getNodeAtPath(
      widget.selection.start.path,
    )!;

    // 块类型选项
    final blockChildren = lists.map((list) {
      final isSelected = node.type == list.name &&
          (list.level == null ||
              node.attributes[HeadingBlockKeys.level] == list.level);

      return MobileToolbarItemMenuBtn(
        icon: AFMobileIcon(
          afMobileIcons: list.icon,
          color: MobileToolbarTheme.of(context).iconColor,
        ),
        label: Text(list.label),
        isSelected: isSelected,
        onPressed: () {
          setState(() {
            widget.editorState.formatNode(
              widget.selection,
              (node) => node.copyWith(
                type: isSelected ? ParagraphBlockKeys.type : list.name,
                attributes: {
                  ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
                  blockComponentBackgroundColor:
                      node.attributes[blockComponentBackgroundColor],
                  if (!isSelected && list.name == TodoListBlockKeys.type)
                    TodoListBlockKeys.checked: false,
                  if (!isSelected && list.name == HeadingBlockKeys.type)
                    HeadingBlockKeys.level: list.level,
                },
              ),
              selectionExtraInfo: {
                selectionExtraInfoDoNotAttachTextService: true,
              },
            );
          });
        },
      );
    }).toList();

    // 对齐选项
    final alignmentChildren = alignmentOptions.map((alignment) {
      final currentAlign = node.attributes[blockComponentAlign] as String?;
      final isSelected = (alignment.align == 'left' && currentAlign == null) ||
          currentAlign == alignment.align;

      return MobileToolbarItemMenuBtn(
        icon: Icon(
          alignment.icon,
          color: MobileToolbarTheme.of(context).iconColor,
          size: 20,
        ),
        label: Text(
          alignment.label,
          style: TextStyle(
            fontSize: 12,
            color: MobileToolbarTheme.of(context).foregroundColor,
          ),
        ),
        isSelected: isSelected,
        onPressed: () {
          setState(() {
            widget.editorState.updateNode(
              widget.selection,
              (node) => node.copyWith(
                attributes: {
                  ...node.attributes,
                  blockComponentAlign: alignment.align == 'left' ? null : alignment.align,
                },
              ),
            );
          });
        },
      );
    }).toList();

    // 合并所有选项
    final allChildren = [...blockChildren, ...alignmentChildren];

    return GridView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      gridDelegate: buildMobileToolbarMenuGridDelegate(
        mobileToolbarStyle: style,
        crossAxisCount: 2,
      ),
      children: allChildren,
    );
  }
}

class _ListUnit {
  final AFMobileIcons icon;
  final String label;
  final String name;
  final int? level;

  _ListUnit({
    required this.icon,
    required this.label,
    required this.name,
    this.level,
  });
}

class _AlignmentUnit {
  final IconData icon;
  final String label;
  final String align;

  _AlignmentUnit({
    required this.icon,
    required this.label,
    required this.align,
  });
}
