import 'dart:async';

import 'package:flutter/material.dart';

import '/core/models/editor_configs/tune_editor_configs.dart';
import '/shared/utils/platform_info.dart';
import '/shared/widgets/flat_icon_text_button.dart';
import '../models/tune_adjustment_matrix.dart';
import '../tune_editor.dart';

class TuneEditorBottombar extends StatefulWidget {
  const TuneEditorBottombar({
    super.key,
    required this.tuneEditorConfigs,
    required this.tuneAdjustmentList,
    required this.tuneAdjustmentMatrix,
    required this.rebuildController,
    required this.onChangedStart,
    required this.onChanged,
    required this.onChangedEnd,
    required this.bottomBarScrollCtrl,
    required this.state,
    required this.onSelect,
    required this.selectedIndex,
  });

  final TuneEditorConfigs tuneEditorConfigs;

  /// A list of tune adjustment items available in the editor.
  final List<TuneAdjustmentItem> tuneAdjustmentList;

  /// A list of matrices representing the adjustments applied to the image.
  final List<TuneAdjustmentMatrix> tuneAdjustmentMatrix;

  /// The index of the currently selected tune adjustment item.
  final int selectedIndex;

  final StreamController<void> rebuildController;
  final ScrollController bottomBarScrollCtrl;

  final TuneEditorState state;

  final Function(double value) onChangedStart;
  final Function(double value) onChanged;
  final Function(double value) onChangedEnd;
  final Function(int index) onSelect;

  @override
  State<TuneEditorBottombar> createState() => _TuneEditorBottombarState();
}

class _TuneEditorBottombarState extends State<TuneEditorBottombar> {
  final _textStyle = const TextStyle(fontSize: 10.0);

  final _iconSize = 22.0;

  late ValueNotifier<double> _sliderValue =
      ValueNotifier(widget.tuneAdjustmentMatrix[widget.selectedIndex].value);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: widget.tuneEditorConfigs.style.bottomBarBackground,
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [
            _buildSlider(),
            _buildItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider() {
    var activeOption = widget.tuneAdjustmentList[widget.selectedIndex];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: RepaintBoundary(
        child: SizedBox(
          height: 40,
          child: ValueListenableBuilder(
              valueListenable: _sliderValue,
              builder: (_, value, __) {
                return widget.tuneEditorConfigs.widgets.slider?.call(
                      widget.state,
                      widget.rebuildController.stream,
                      value,
                      widget.onChanged,
                      widget.onChangedEnd,
                    ) ??
                    Slider(
                      min: activeOption.min,
                      max: activeOption.max,
                      divisions: activeOption.divisions,
                      label: (value * activeOption.labelMultiplier)
                          .round()
                          .toString(),
                      value: value,
                      onChangeStart: (val) {
                        _sliderValue.value = val;
                        widget.onChangedStart(val);
                      },
                      onChanged: (val) {
                        _sliderValue.value = val;
                        widget.onChanged(val);
                      },
                      onChangeEnd: widget.onChangedEnd,
                    );
              }),
        ),
      ),
    );
  }

  Widget _buildItems() {
    return SizedBox(
      height: kBottomNavigationBarHeight,
      child: Scrollbar(
        controller: widget.bottomBarScrollCtrl,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        thickness: isDesktop ? null : 0,
        child: SingleChildScrollView(
          controller: widget.bottomBarScrollCtrl,
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children:
                  List.generate(widget.tuneAdjustmentMatrix.length, (index) {
                var item = widget.tuneAdjustmentList[index];
                var color = widget.selectedIndex == index
                    ? widget.tuneEditorConfigs.style.bottomBarActiveItemColor
                    : widget.tuneEditorConfigs.style.bottomBarInactiveItemColor;
                return FlatIconTextButton(
                  label: Text(
                    item.label,
                    style: _textStyle.copyWith(color: color),
                  ),
                  icon: Icon(
                    item.icon,
                    size: _iconSize,
                    color: color,
                  ),
                  onPressed: () => widget.onSelect(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
