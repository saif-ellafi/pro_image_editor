import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/shared/widgets/color_picker/bar_color_picker.dart';
import '../paint_editor.dart';

class PaintEditorColorPicker extends StatelessWidget {
  const PaintEditorColorPicker({
    super.key,
    required this.state,
    required this.configs,
    required this.rebuildController,
  });

  final PaintEditorState state;
  final ProImageEditorConfigs configs;
  final StreamController<void> rebuildController;

  @override
  Widget build(BuildContext context) {
    if (configs.paintEditor.widgets.colorPicker != null) {
      return configs.paintEditor.widgets.colorPicker!.call(
            state,
            rebuildController.stream,
            state.paintCtrl.color,
            state.colorChanged,
          ) ??
          const SizedBox.shrink();
    }

    return Positioned(
      top: 10,
      right: 0,
      child: StreamBuilder(
        stream: state.uiPickerStream.stream,
        builder: (context, snapshot) {
          return BarColorPicker(
            configs: configs,
            length: min(
              350,
              MediaQuery.of(context).size.height -
                  MediaQuery.of(context).viewInsets.bottom -
                  kToolbarHeight -
                  kBottomNavigationBarHeight -
                  MediaQuery.of(context).padding.top -
                  30,
            ),
            horizontal: false,
            thumbColor: Colors.white,
            cornerRadius: 10,
            pickMode: PickMode.color,
            initialColor: configs.paintEditor.style.initialColor,
            colorListener: (int value) {
              state.colorChanged(Color(value));
            },
          );
        },
      ),
    );
  }
}
