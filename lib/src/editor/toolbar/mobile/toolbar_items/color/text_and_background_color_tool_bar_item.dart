import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

MobileToolbarItem buildTextAndBackgroundColorMobileToolbarItem({
  List<ColorOption>? textColorOptions,
  List<ColorOption>? backgroundColorOptions,
}) {
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, editorState, ___) => _ColorToolbarIcon(
      editorState: editorState,
    ),
    itemMenuBuilder: (_, editorState, ___) {
      final selection = editorState.selection;
      if (selection == null) {
        return const SizedBox.shrink();
      }
      return _TextAndBackgroundColorMenu(
        editorState,
        selection,
        textColorOptions: textColorOptions,
        backgroundColorOptions: backgroundColorOptions,
      );
    },
  );
}

class _TextAndBackgroundColorMenu extends StatefulWidget {
  const _TextAndBackgroundColorMenu(
    this.editorState,
    this.selection, {
    this.textColorOptions,
    this.backgroundColorOptions,
  });

  final EditorState editorState;
  final Selection selection;
  final List<ColorOption>? textColorOptions;
  final List<ColorOption>? backgroundColorOptions;

  @override
  State<_TextAndBackgroundColorMenu> createState() =>
      _TextAndBackgroundColorMenuState();
}

class _TextAndBackgroundColorMenuState
    extends State<_TextAndBackgroundColorMenu> {
  @override
  Widget build(BuildContext context) {
    final style = MobileToolbarTheme.of(context);
    List<Tab> myTabs = <Tab>[
      Tab(
        text: '文字颜色',
      ),
      Tab(text: '背景颜色'),
    ];

    return DefaultTabController(
      length: myTabs.length,
      child: Column(
        children: [
          SizedBox(
            height: style.buttonHeight,
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: myTabs,
              labelColor: style.tabBarSelectedBackgroundColor,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(style.borderRadius),
                color: style.tabBarSelectedForegroundColor,
              ),
              // remove the bottom line of TabBar
              dividerColor: Colors.transparent,
            ),
          ),
          SizedBox(
            // 3 lines of buttons
            height: 3 * style.buttonHeight + 4 * style.buttonSpacing,
            child: TabBarView(
              children: [
                TextColorOptionsWidgets(
                  widget.editorState,
                  widget.selection,
                  textColorOptions: widget.textColorOptions,
                ),
                BackgroundColorOptionsWidgets(
                  widget.editorState,
                  widget.selection,
                  backgroundColorOptions: widget.backgroundColorOptions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorToolbarIcon extends StatelessWidget {
  const _ColorToolbarIcon({
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
        final backgroundColorHex = toggledStyle[AppFlowyRichTextKeys.backgroundColor] as String?;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Base icon
            AFMobileIcon(
              afMobileIcons: AFMobileIcons.color,
              color: style.iconColor,
            ),
            // Color indicator overlay
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getIndicatorColor(textColorHex, backgroundColorHex),
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

  Color _getIndicatorColor(String? textColorHex, String? backgroundColorHex) {
    // Priority: text color > background color > default
    if (textColorHex != null) {
      return textColorHex.tryToColor() ?? Colors.black;
    }
    if (backgroundColorHex != null) {
      return backgroundColorHex.tryToColor() ?? Colors.yellow;
    }
    return Colors.grey; // Default when no color is selected
  }
}
