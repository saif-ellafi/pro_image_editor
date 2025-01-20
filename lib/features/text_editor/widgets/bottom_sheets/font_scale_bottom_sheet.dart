import 'dart:async';

import 'package:flutter/material.dart';

import '/core/enums/design_mode.dart';
import '/core/models/editor_configs/text_editor_configs.dart';
import '/core/models/i18n/i18n_text_editor.dart';
import '/features/text_editor/text_editor.dart';
import '/shared/styles/platform_text_styles.dart';
import '/shared/widgets/bottom_sheets_header_row.dart';

class FontScaleBottomSheet extends StatefulWidget {
  const FontScaleBottomSheet({
    super.key,
    required this.configs,
    required this.i18n,
    required this.state,
    required this.fontScale,
    required this.designMode,
    required this.theme,
    required this.rebuildController,
    required this.onFontScaleChanged,
  });

  final StreamController<void> rebuildController;

  final TextEditorConfigs configs;
  final I18nTextEditor i18n;
  final TextEditorState state;

  final ImageEditorDesignMode designMode;
  final ThemeData theme;
  final double fontScale;

  final Function(double value) onFontScaleChanged;

  @override
  State<FontScaleBottomSheet> createState() => _FontScaleBottomSheetState();
}

class _FontScaleBottomSheetState extends State<FontScaleBottomSheet> {
  late double _fontScale = widget.fontScale;
  late final double _presetFontScale = widget.fontScale;

  void updateFontScaleScale(double value) {
    widget.onFontScaleChanged(value);
    _fontScale = value;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      textStyle: platformTextStyle(context, widget.designMode),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BottomSheetHeaderRow(
      title: '${widget.i18n.fontScale} ${_fontScale.toStringAsFixed(1)}x',
      theme: widget.theme,
      textStyle: widget.configs.style.fontSizeBottomSheetTitle,
      closeButton: widget.configs.widgets.fontSizeCloseButton != null
          ? (fn) =>
              widget.configs.widgets.fontSizeCloseButton!(widget.state, fn)
          : null,
    );
  }

  Widget _buildBody() {
    return widget.configs.widgets.sliderFontSize?.call(
          widget.state,
          widget.rebuildController.stream,
          _fontScale,
          updateFontScaleScale,
          (onChangedEnd) {},
        ) ??
        Row(
          children: [
            Expanded(
              child: Slider.adaptive(
                max: widget.configs.maxFontScale,
                min: widget.configs.minFontScale,
                divisions: (widget.configs.maxFontScale -
                        widget.configs.minFontScale) ~/
                    0.1,
                value: _fontScale,
                onChanged: updateFontScaleScale,
              ),
            ),
            const SizedBox(width: 8),
            _buildResetButton(),
            const SizedBox(width: 2),
          ],
        );
  }

  Widget _buildResetButton() {
    return IconTheme(
      data: Theme.of(context).primaryIconTheme,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _fontScale != _presetFontScale
            ? IconButton(
                key: const ValueKey('ResetFontScaleButtonActive'),
                onPressed: () {
                  updateFontScaleScale(_presetFontScale);
                },
                icon: Icon(widget.configs.icons.resetFontScale),
              )
            : IconButton(
                key: const ValueKey('ResetFontScaleButtonInactive'),
                color: Colors.transparent,
                onPressed: null,
                icon: Icon(widget.configs.icons.resetFontScale),
              ),
      ),
    );
  }
}
