import 'dart:async';

import 'package:flutter/material.dart';

import '/core/enums/design_mode.dart';
import '/shared/styles/platform_text_styles.dart';
import '/shared/widgets/bottom_sheets_header_row.dart';
import 'reactive_widgets/reactive_custom_widget.dart';

class SliderBottomSheet<T> extends StatefulWidget {
  const SliderBottomSheet({
    super.key,
    required this.title,
    required this.headerTextStyle,
    required this.min,
    required this.max,
    required this.divisions,
    required this.closeButton,
    required this.customSlider,
    required this.state,
    required this.value,
    required this.designMode,
    required this.theme,
    required this.rebuildController,
    required this.onValueChanged,
    this.resetIcon,
    this.showFactorInTitle = false,
  });

  final String title;
  final TextStyle? headerTextStyle;
  final IconData? resetIcon;
  final Widget Function(T, dynamic Function())? closeButton;
  final ReactiveWidget<Widget> Function(
    T,
    Stream<void>,
    double,
    dynamic Function(double),
    dynamic Function(double),
  )? customSlider;

  final bool showFactorInTitle;
  final double min;
  final double max;
  final int? divisions;

  final StreamController<void> rebuildController;

  final T state;

  final ImageEditorDesignMode designMode;
  final ThemeData theme;
  final double value;

  final Function(double value) onValueChanged;

  @override
  State<SliderBottomSheet<T>> createState() => _SliderBottomSheetState<T>();
}

class _SliderBottomSheetState<T> extends State<SliderBottomSheet<T>> {
  late double _value = widget.value;
  late final double _presetValue = widget.value;

  void updateFontScaleScale(double value) {
    widget.onValueChanged(value);
    _value = value;
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
    String factorText =
        widget.showFactorInTitle ? ' ${_value.toStringAsFixed(1)}x' : '';

    return BottomSheetHeaderRow(
      title: '${widget.title}$factorText',
      theme: widget.theme,
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 4),
      textStyle: widget.headerTextStyle,
      closeButton: widget.closeButton != null
          ? (fn) => widget.closeButton!(widget.state, fn)
          : null,
    );
  }

  Widget _buildBody() {
    return widget.customSlider?.call(
          widget.state,
          widget.rebuildController.stream,
          _value,
          updateFontScaleScale,
          (onChangedEnd) {},
        ) ??
        Row(
          children: [
            Expanded(
              child: Slider.adaptive(
                max: widget.max,
                min: widget.min,
                divisions: widget.divisions,
                value: _value,
                onChanged: updateFontScaleScale,
              ),
            ),
            if (widget.resetIcon != null) ...[
              const SizedBox(width: 8),
              _buildResetButton(),
              const SizedBox(width: 2),
            ],
          ],
        );
  }

  Widget _buildResetButton() {
    return IconTheme(
      data: Theme.of(context).primaryIconTheme,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _value != _presetValue
            ? IconButton(
                key: const ValueKey('ResetFontScaleButtonActive'),
                onPressed: () {
                  updateFontScaleScale(_presetValue);
                },
                icon: Icon(widget.resetIcon),
              )
            : IconButton(
                key: const ValueKey('ResetFontScaleButtonInactive'),
                color: Colors.transparent,
                onPressed: null,
                icon: Icon(widget.resetIcon),
              ),
      ),
    );
  }
}
