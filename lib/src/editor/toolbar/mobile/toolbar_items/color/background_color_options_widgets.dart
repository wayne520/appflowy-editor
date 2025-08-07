import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class BackgroundColorOptionsWidgets extends StatefulWidget {
  const BackgroundColorOptionsWidgets(
    this.editorState,
    this.selection, {
    this.backgroundColorOptions,
    super.key,
  });

  final Selection selection;
  final EditorState editorState;
  final List<ColorOption>? backgroundColorOptions;

  @override
  State<BackgroundColorOptionsWidgets> createState() =>
      _BackgroundColorOptionsWidgetsState();
}

class _BackgroundColorOptionsWidgetsState
    extends State<BackgroundColorOptionsWidgets> {
  @override
  Widget build(BuildContext context) {
    // Listen to toggledStyle changes to update UI when styles change
    return ValueListenableBuilder(
      valueListenable: widget.editorState.toggledStyleNotifier,
      builder: (context, toggledStyle, child) {
        final style = MobileToolbarTheme.of(context);
        final colorOptions =
            widget.backgroundColorOptions ?? generateHighlightColorOptions();
        final selection = widget.selection;
        final nodes = widget.editorState.getNodesInSelection(selection);
        final hasTextColor = nodes.allSatisfyInSelection(selection, (delta) {
          return delta.everyAttributes(
            (attributes) =>
                attributes[AppFlowyRichTextKeys.backgroundColor] != null,
          );
        });

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
                    if (selection.isCollapsed) {
                      // When no text is selected, clear the toggled style
                      widget.editorState.updateToggledStyle(
                        AppFlowyRichTextKeys.backgroundColor,
                        null,
                      );
                    } else {
                      // When text is selected, clear the background color
                      widget.editorState.formatDelta(
                        selection,
                        {AppFlowyRichTextKeys.backgroundColor: null},
                      );
                    }
                  });
                },
                isSelected: selection.isCollapsed
                    ? widget.editorState.toggledStyle[
                            AppFlowyRichTextKeys.backgroundColor] ==
                        null
                    : !hasTextColor,
              ),
              // color option buttons
              ...colorOptions.map((e) {
                final bool isSelected;
                if (selection.isCollapsed) {
                  // When no text is selected, check the toggled style
                  isSelected = widget.editorState
                          .toggledStyle[AppFlowyRichTextKeys.backgroundColor] ==
                      e.colorHex;
                } else {
                  // When text is selected, check the selected text attributes
                  isSelected = nodes.allSatisfyInSelection(selection, (delta) {
                    return delta.everyAttributes(
                      (attributes) =>
                          attributes[AppFlowyRichTextKeys.backgroundColor] ==
                          e.colorHex,
                    );
                  });
                }

                return ColorButton(
                  isBackgroundColor: true,
                  colorOption: e,
                  onPressed: () {
                    setState(() {
                      if (selection.isCollapsed) {
                        // When no text is selected, update the toggled style for future text input
                        widget.editorState.updateToggledStyle(
                          AppFlowyRichTextKeys.backgroundColor,
                          isSelected ? null : e.colorHex,
                        );
                      } else {
                        // When text is selected, format the selected text
                        formatHighlightColor(
                          widget.editorState,
                          widget.editorState.selection,
                          isSelected ? null : e.colorHex,
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
