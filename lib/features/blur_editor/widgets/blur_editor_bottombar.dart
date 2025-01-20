import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/core/models/editor_configs/blur_editor_configs.dart';

import '../blur_editor.dart';

class BlurEditorBottombar extends StatelessWidget {
  const BlurEditorBottombar({
    super.key,
    required this.blurEditorConfigs,
    required this.uiBlurStream,
    required this.blurFactor,
    required this.rebuildController,
    required this.blurEditorState,
    required this.onChanged,
    required this.onChangedEnd,
  });

  final BlurEditorConfigs blurEditorConfigs;
  final StreamController<void> uiBlurStream;
  final Function(double value) onChanged;
  final Function(double value) onChangedEnd;
  final double blurFactor;
  final StreamController<void> rebuildController;
  final BlurEditorState blurEditorState;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: blurEditorConfigs.style.background,
        height: 100,
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: RepaintBoundary(
              child: StreamBuilder(
                  stream: uiBlurStream.stream,
                  builder: (context, snapshot) {
                    return blurEditorConfigs.widgets.slider?.call(
                          blurEditorState,
                          rebuildController.stream,
                          blurFactor,
                          onChanged,
                          onChangedEnd,
                        ) ??
                        Slider(
                          min: 0,
                          max: blurEditorConfigs.maxBlur,
                          divisions: 100,
                          value: blurFactor,
                          onChanged: onChanged,
                          onChangeEnd: onChangedEnd,
                        );
                  }),
            ),
          ),
        ),
      ),
    );
  }
}
