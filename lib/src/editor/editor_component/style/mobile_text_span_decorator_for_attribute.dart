import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Support mobile platform
///   - customize the href text span
TextSpan mobileTextSpanDecoratorForAttribute(
  BuildContext context,
  Node node,
  int index,
  TextInsert text,
  TextSpan before,
  TextSpan after,
) {
  final attributes = text.attributes;
  if (attributes == null) {
    return before;
  }
  final editorState = context.read<EditorState>();

  final hrefAddress = attributes[AppFlowyRichTextKeys.href] as String?;
  if (hrefAddress != null) {
    Timer? timer;

    final tapGestureRecognizer = TapGestureRecognizer()
      ..onTapUp = (_) async {
        if (timer != null && timer!.isActive) {
          // Implement single tap logic
          safeLaunchUrl(hrefAddress);
          timer!.cancel();
          return;
        }
      };

    tapGestureRecognizer.onTapDown = (_) {
      final selection = Selection.single(
        path: node.path,
        startOffset: index,
        endOffset: index + text.text.length,
      );
      editorState.updateSelectionWithReason(
        selection,
        reason: SelectionUpdateReason.uiEvent,
      );

      timer = Timer(const Duration(milliseconds: 500), () {
        // Implement long tap logic
        showCupertinoDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text(AppFlowyEditorL10n.current.editLink),
              content: LinkEditForm(
                node: node,
                index: index,
                hrefText: text.text,
                hrefAddress: hrefAddress,
                editorState: editorState,
                selection: selection,
              ),
            );
          },
        );
      });
    };
    return TextSpan(
      style: before.style,
      text: text.text,
      recognizer: tapGestureRecognizer,
    );
  }

  return before;
}

class LinkEditForm extends StatefulWidget {
  const LinkEditForm({
    super.key,
    required this.node,
    required this.index,
    required this.hrefText,
    required this.hrefAddress,
    required this.editorState,
    required this.selection,
  });
  final Node node;
  final int index;
  final String hrefText;
  final String hrefAddress;
  final EditorState editorState;
  final Selection selection;

  @override
  State<LinkEditForm> createState() => _LinkEditFormState();
}

class _LinkEditFormState extends State<LinkEditForm> {
  @override
  Widget build(BuildContext context) {
    var hrefAddressTextEditingController =
        TextEditingController(text: widget.hrefAddress);
    var hrefTextTextEditingController =
        TextEditingController(text: widget.hrefText);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        CupertinoTextField(
          key: const Key('Text CupertinoTextField'),
          autofocus: true,
          controller: hrefTextTextEditingController,
          keyboardType: TextInputType.text,
          placeholder: AppFlowyEditorL10n.current.linkText,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8.0),
          ),
          suffix: CupertinoButton(
            padding: const EdgeInsets.all(4),
            minSize: 0,
            onPressed: hrefTextTextEditingController.clear,
            child: const Icon(
              CupertinoIcons.clear_circled_solid,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoTextField(
          key: const Key('Url CupertinoTextField'),
          controller: hrefAddressTextEditingController,
          keyboardType: TextInputType.url,
          placeholder: AppFlowyEditorL10n.current.urlHint,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8.0),
          ),
          suffix: CupertinoButton(
            padding: const EdgeInsets.all(4),
            minSize: 0,
            onPressed: hrefAddressTextEditingController.clear,
            child: const Icon(
              CupertinoIcons.clear_circled_solid,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(AppFlowyEditorL10n.current.removeLink),
              onPressed: () async {
                final transaction = widget.editorState.transaction
                  ..formatText(
                    widget.node,
                    widget.index,
                    widget.hrefText.length,
                    {BuiltInAttributeKey.href: null},
                  );
                await widget.editorState.apply(transaction).whenComplete(() {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                });
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(AppFlowyEditorL10n.current.done),
              onPressed: () async {
                // 简化验证逻辑，因为CupertinoTextField没有内置验证
                if (hrefTextTextEditingController.text.isEmpty) {
                  return; // 可以添加错误提示
                }
                if (hrefAddressTextEditingController.text.isEmpty) {
                  return; // 可以添加错误提示
                }

                final bool textChanged =
                    hrefTextTextEditingController.text != widget.hrefText;
                final bool addressChanged =
                    hrefAddressTextEditingController.text != widget.hrefAddress;

                if (textChanged && addressChanged) {
                  final transaction = widget.editorState.transaction
                    ..replaceText(
                      widget.node,
                      widget.index,
                      widget.hrefText.length,
                      hrefTextTextEditingController.text,
                      attributes: {
                        AppFlowyRichTextKeys.href:
                            hrefAddressTextEditingController.text,
                      },
                    );
                  await widget.editorState.apply(transaction).whenComplete(
                    () {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                } else if (textChanged && !addressChanged) {
                  final transaction = widget.editorState.transaction
                    ..replaceText(
                      widget.node,
                      widget.index,
                      widget.hrefText.length,
                      hrefTextTextEditingController.text,
                    );
                  await widget.editorState.apply(transaction).whenComplete(
                    () {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                } else if (!textChanged && addressChanged) {
                  await widget.editorState.formatDelta(widget.selection, {
                    AppFlowyRichTextKeys.href:
                        hrefAddressTextEditingController.value.text,
                  }).whenComplete(() {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
