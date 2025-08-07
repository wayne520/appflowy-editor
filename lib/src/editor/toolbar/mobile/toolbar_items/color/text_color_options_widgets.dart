import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class TextColorOptionsWidgets extends StatefulWidget {
  const TextColorOptionsWidgets(
    this.editorState,
    this.selection, {
    this.textColorOptions,
    super.key,
  });

  final Selection selection;
  final EditorState editorState;
  final List<ColorOption>? textColorOptions;

  @override
  State<TextColorOptionsWidgets> createState() =>
      _TextColorOptionsWidgetsState();
}

class _TextColorOptionsWidgetsState extends State<TextColorOptionsWidgets> {
  @override
  Widget build(BuildContext context) {
    // Listen to toggledStyle changes to update UI when styles change
    return ValueListenableBuilder(
      valueListenable: widget.editorState.toggledStyleNotifier,
      builder: (context, toggledStyle, child) {
        final style = MobileToolbarTheme.of(context);

        final selection = widget.selection;
        final nodes = widget.editorState.getNodesInSelection(selection);
        final hasTextColor = nodes.allSatisfyInSelection(selection, (delta) {
          return delta.everyAttributes(
            (attributes) => attributes[AppFlowyRichTextKeys.textColor] != null,
          );
        });

        final colorOptions =
            widget.textColorOptions ?? generateTextColorOptions();

        return Scrollbar(
          child: GridView(
            shrinkWrap: true,
            gridDelegate: buildMobileToolbarMenuGridDelegate(
              mobileToolbarStyle: style,
              crossAxisCount: 3,
            ),
            padding: EdgeInsets.all(style.buttonSpacing),
            children: [
              ClearColorButton(
                onPressed: () {
                  setState(() {
                    // Always clear the global toggled style
                    widget.editorState.updateToggledStyle(
                      AppFlowyRichTextKeys.textColor,
                      null,
                    );

                    // If text is selected, also clear the color from selected text
                    if (!selection.isCollapsed) {
                      widget.editorState.formatDelta(
                        selection,
                        {AppFlowyRichTextKeys.textColor: null},
                      );
                    }
                  });
                },
                isSelected: selection.isCollapsed
                    ? widget.editorState
                            .toggledStyle[AppFlowyRichTextKeys.textColor] ==
                        null
                    : !hasTextColor,
              ),
              // color option buttons
              ...colorOptions.map((e) {
                final bool isSelected;
                if (selection.isCollapsed) {
                  // When no text is selected, check the toggled style
                  isSelected = widget.editorState
                          .toggledStyle[AppFlowyRichTextKeys.textColor] ==
                      e.colorHex;
                } else {
                  // When text is selected, check the selected text attributes
                  isSelected = nodes.allSatisfyInSelection(selection, (delta) {
                    return delta.everyAttributes(
                      (attributes) =>
                          attributes[AppFlowyRichTextKeys.textColor] ==
                          e.colorHex,
                    );
                  });
                }

                return ColorButton(
                  colorOption: e,
                  onPressed: () {
                    setState(() {
                      final newColor = isSelected ? null : e.colorHex;

                      // Always update the global toggled style for persistent formatting
                      widget.editorState.updateToggledStyle(
                        AppFlowyRichTextKeys.textColor,
                        newColor,
                      );

                      // If text is selected, also apply the formatting to the selected text
                      if (!selection.isCollapsed) {
                        formatFontColor(
                          widget.editorState,
                          widget.editorState.selection,
                          newColor,
                        );
                      }
                    });
                  },
                  isSelected: isSelected,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
