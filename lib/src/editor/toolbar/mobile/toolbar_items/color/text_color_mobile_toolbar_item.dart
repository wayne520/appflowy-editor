import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

MobileToolbarItem buildTextColorMobileToolbarItem({
  List<ColorOption>? textColorOptions,
}) {
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, editorState, ___) => _TextColorIcon(
      editorState: editorState,
    ),
    itemMenuBuilder: (_, editorState, ___) {
      final selection = editorState.selection;
      if (selection == null) {
        return const SizedBox.shrink();
      }
      return TextColorOptionsWidgets(
        editorState,
        selection,
        textColorOptions: textColorOptions,
      );
    },
  );
}

class _TextColorIcon extends StatelessWidget {
  const _TextColorIcon({
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: editorState.toggledStyleNotifier,
      builder: (context, toggledStyle, child) {
        final style = MobileToolbarTheme.of(context);
        
        // Get current text color from toggled style
        final textColorHex = toggledStyle[AppFlowyRichTextKeys.textColor] as String?;
        final hasTextColor = textColorHex != null;
        final textColor = textColorHex?.tryToColor() ?? style.iconColor;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Text color icon with current color
            Icon(
              Icons.format_color_text,
              color: hasTextColor ? textColor : style.iconColor,
              size: 20,
            ),
            // Color underline indicator
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
