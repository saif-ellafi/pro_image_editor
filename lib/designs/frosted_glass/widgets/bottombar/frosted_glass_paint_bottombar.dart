// Flutter imports:
import 'package:flutter/material.dart';

import '/core/ui/pro_image_editor_icons.dart';
import '/designs/frosted_glass/frosted_glass.dart';
import '/designs/whatsapp/whatsapp_color_picker.dart';
import '/pro_image_editor.dart';

/// A stateful widget that represents a bottom bar with a frosted glass effect.
///
/// This bottom bar is designed for use in a paint editor interface,
/// providing controls and options for paint operations in a stylish manner.
class FrostedGlassPaintBottomBar extends StatefulWidget {
  /// Creates a [FrostedGlassPaintBottomBar].
  ///
  /// This bottom bar utilizes a frosted glass effect to enhance the visual
  /// design of a paint editor, offering controls relevant to paint.
  ///
  /// Example:
  /// ```
  /// FrostedGlassPaintBottomBar(
  ///   paintEditor: myPaintEditorState,
  /// )
  /// ```
  const FrostedGlassPaintBottomBar({
    super.key,
    required this.paintEditor,
  });

  /// The state of the paint editor associated with this bottom bar.
  ///
  /// This state allows the bottom bar to interact with the paint editor,
  /// providing necessary controls and options to manage paint activities.
  final PaintEditorState paintEditor;

  @override
  State<FrostedGlassPaintBottomBar> createState() =>
      _FrostedGlassPaintBottomBarState();
}

class _FrostedGlassPaintBottomBarState
    extends State<FrostedGlassPaintBottomBar> {
  _Mode _mode = _Mode.color;

  late ButtonStyle _buttonStyle;

  @override
  void initState() {
    _buttonStyle = IconButton.styleFrom(
      backgroundColor: Colors.black38,
      foregroundColor: widget
          .paintEditor.paintEditorConfigs.style.bottomBarInactiveItemColor,
      padding: const EdgeInsets.all(10),
      iconSize: 22,
      minimumSize: const Size.fromRadius(10),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.paintEditor.isActive
        ? const SizedBox.shrink()
        : Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 48,
            child: FrostedGlassEffect(
              radius: BorderRadius.zero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _mode = _mode == _Mode.color
                            ? _Mode.lineWidth
                            : _mode == _Mode.lineWidth
                                ? _Mode.mode
                                : _Mode.color;
                      });
                    },
                    icon: Icon(
                      _mode == _Mode.color
                          ? Icons.draw
                          : _mode == _Mode.lineWidth
                              ? Icons.category
                              : Icons.color_lens,
                    ),
                    style:
                        IconButton.styleFrom(backgroundColor: Colors.black38),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 2, 0, 2),
                    width: 1.5,
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _mode == _Mode.color
                      ? Expanded(
                          child: WhatsAppColorPicker(
                            onColorChanged: (color) {
                              widget.paintEditor.paintCtrl.setColor(color);
                              widget.paintEditor.uiPickerStream.add(null);
                            },
                            initColor: widget.paintEditor.paintCtrl.color,
                          ),
                        )
                      : _mode == _Mode.lineWidth
                          ? _buildLineWidth()
                          : _buildModes(),
                ],
              ),
            ),
          );
  }

  Widget _buildLineWidth() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.center,
          spacing: 10,
          children: [
            IconButton(
              onPressed: () {
                widget.paintEditor.setStrokeWidth(2);
              },
              icon: const Icon(ProImageEditorIcons.penSize1),
              style: _buttonStyle.copyWith(
                backgroundColor: widget.paintEditor.strokeWidth != 2
                    ? null
                    : const WidgetStatePropertyAll(Colors.white),
                foregroundColor: widget.paintEditor.strokeWidth != 2
                    ? null
                    : const WidgetStatePropertyAll(Colors.black),
              ),
            ),
            IconButton(
              onPressed: () {
                widget.paintEditor.setStrokeWidth(5);
              },
              icon: const Icon(ProImageEditorIcons.penSize2),
              style: _buttonStyle.copyWith(
                backgroundColor: widget.paintEditor.strokeWidth != 5
                    ? null
                    : const WidgetStatePropertyAll(Colors.white),
                foregroundColor: widget.paintEditor.strokeWidth != 5
                    ? null
                    : const WidgetStatePropertyAll(Colors.black),
              ),
            ),
            IconButton(
              onPressed: () {
                widget.paintEditor.setStrokeWidth(10);
              },
              icon: const Icon(ProImageEditorIcons.penSize3),
              style: _buttonStyle.copyWith(
                backgroundColor: widget.paintEditor.strokeWidth != 10
                    ? null
                    : const WidgetStatePropertyAll(Colors.white),
                foregroundColor: widget.paintEditor.strokeWidth != 10
                    ? null
                    : const WidgetStatePropertyAll(Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModes() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.center,
          spacing: 10,
          children: List.generate(widget.paintEditor.paintModes.length, (i) {
            PaintModeBottomBarItem item = widget.paintEditor.paintModes[i];
            bool isSelected = widget.paintEditor.paintMode == item.mode;
            return IconButton(
              onPressed: () {
                widget.paintEditor.setMode(item.mode);
              },
              tooltip: item.label,
              icon: Icon(item.icon),
              style: _buttonStyle.copyWith(
                  backgroundColor: !isSelected
                      ? null
                      : const WidgetStatePropertyAll(Colors.white),
                  foregroundColor: !isSelected
                      ? null
                      : const WidgetStatePropertyAll(Colors.black)),
            );
          }),
        ),
      ),
    );
  }
}

enum _Mode { color, lineWidth, mode }
