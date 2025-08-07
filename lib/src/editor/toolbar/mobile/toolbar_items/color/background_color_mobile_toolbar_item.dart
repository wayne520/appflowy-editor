import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

MobileToolbarItem buildHighlightColorMobileToolbarItem({
  List<ColorOption>? backgroundColorOptions,
}) {
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, editorState, ___) => _HighlightColorIcon(
      editorState: editorState,
    ),
    itemMenuBuilder: (_, editorState, ___) {
      final selection = editorState.selection;
      if (selection == null) {
        return const SizedBox.shrink();
      }
      return BackgroundColorOptionsWidgets(
        editorState,
        selection,
        backgroundColorOptions: backgroundColorOptions,
      );
    },
  );
}

class _HighlightColorIcon extends StatelessWidget {
  const _HighlightColorIcon({
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: editorState.toggledStyleNotifier,
      builder: (context, toggledStyle, child) {
        final style = MobileToolbarTheme.of(context);
        
        // Get current background color from toggled style
        final backgroundColorHex = toggledStyle[AppFlowyRichTextKeys.backgroundColor] as String?;
        final hasBackgroundColor = backgroundColorHex != null;
        final backgroundColor = backgroundColorHex?.tryToColor() ?? Colors.yellow;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Background highlight icon
            Icon(
              Icons.format_color_fill,
              color: style.iconColor,
              size: 20,
            ),
            // Color indicator overlay
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
                    border: Border.all(
                      color: Colors.white,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
