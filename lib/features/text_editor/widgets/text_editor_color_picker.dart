import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/shared/widgets/color_picker/bar_color_picker.dart';
import '../text_editor.dart';

class TextEditorColorPicker extends StatelessWidget {
  const TextEditorColorPicker({
    super.key,
    required this.state,
    required this.configs,
    required this.rebuildController,
    required this.colorPosition,
    required this.primaryColor,
    required this.selectedTextStyle,
    required this.onUpdateColor,
    required this.onPositionChange,
  });

  final TextEditorState state;
  final ProImageEditorConfigs configs;
  final StreamController<void> rebuildController;
  final double colorPosition;
  final Color primaryColor;
  final TextStyle selectedTextStyle;

  final Function(Color color) onUpdateColor;
  final Function(double value)? onPositionChange;

  @override
  Widget build(BuildContext context) {
    if (configs.textEditor.widgets.colorPicker != null) {
      return configs.textEditor.widgets.colorPicker!.call(
            state,
            rebuildController.stream,
            selectedTextStyle.color ?? primaryColor,
            onUpdateColor,
          ) ??
          const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: null,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: BarColorPicker(
          configs: configs,
          length: min(
            350,
            MediaQuery.of(context).size.height -
                MediaQuery.of(context).viewInsets.bottom -
                kToolbarHeight -
                kBottomNavigationBarHeight -
                10 * 2 -
                MediaQuery.of(context).padding.top,
          ),
          onPositionChange: onPositionChange,
          initPosition: colorPosition,
          initialColor: primaryColor,
          horizontal: false,
          thumbColor: Colors.white,
          cornerRadius: 10,
          pickMode: PickMode.color,
          colorListener: (int value) => onUpdateColor(Color(value)),
        ),
      ),
    );
  }
}
