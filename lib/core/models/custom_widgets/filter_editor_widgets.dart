// Flutter imports:
import 'package:flutter/widgets.dart';

// Project imports:
import '/features/filter_editor/filter_editor.dart';
import '/shared/widgets/reactive_widgets/reactive_custom_appbar.dart';
import '/shared/widgets/reactive_widgets/reactive_custom_widget.dart';
import 'utils/custom_widgets_standalone_editor.dart';
import 'utils/custom_widgets_typedef.dart';

/// A custom widget for editing filter effects in an image editor.
///
/// This widget extends the standalone editor for the filter editor state,
/// providing a customizable interface for applying and adjusting image filters.

class FilterEditorWidgets
    extends CustomWidgetsStandaloneEditor<FilterEditorState> {
  /// Creates a [FilterEditorWidgets] widget.
  ///
  /// This widget allows customization of the app bar, bottom bar, body items,
  /// and additional widgets specific to filter functionality, enabling a
  /// flexible design tailored to specific needs.
  const FilterEditorWidgets({
    super.appBar,
    super.bottomBar,
    super.bodyItems,
    super.bodyItemsRecorded,
    this.slider,
    this.filterButton,
  });

  /// A custom slider widget for the filter editor.
  ///
  /// This widget allows users to adjust values using a slider in the filter
  /// editor.
  ///
  /// {@macro customSliderWidget}
  final CustomSlider<FilterEditorState>? slider;

  /// Creating a widget that represents a filter button in an editor.
  ///
  /// [filter] - The [FilterModel] representing the filter applied by the
  /// button.
  /// [isSelected] - A boolean indicating whether the filter is currently
  /// selected.
  /// [scaleFactor] - An optional double representing the scale factor for the
  /// button.
  /// [onSelectFilter] - A callback function to handle the filter selection.
  /// [editorImage] - A widget representing the image being edited.
  /// [filterKey] - A [Key] to uniquely identify the filter button.
  ///
  /// Returns a [Widget] representing the filter button in the editor.
  final Widget Function(
    FilterModel filter,
    bool isSelected,
    double? scaleFactor,
    Function() onSelectFilter,
    Widget editorImage,
    Key filterKey,
  )? filterButton;

  @override
  FilterEditorWidgets copyWith({
    ReactiveAppbar? Function(
            FilterEditorState editorState, Stream<void> rebuildStream)?
        appBar,
    ReactiveWidget? Function(
            FilterEditorState editorState, Stream<void> rebuildStream)?
        bottomBar,
    CustomBodyItems<FilterEditorState>? bodyItems,
    CustomBodyItems<FilterEditorState>? bodyItemsRecorded,
    CustomSlider<FilterEditorState>? slider,
    Widget Function(
      FilterModel filter,
      bool isSelected,
      double? scaleFactor,
      Function() onSelectFilter,
      Widget editorImage,
      Key filterKey,
    )? filterButton,
  }) {
    return FilterEditorWidgets(
      appBar: appBar ?? this.appBar,
      bottomBar: bottomBar ?? this.bottomBar,
      bodyItems: bodyItems ?? this.bodyItems,
      bodyItemsRecorded: bodyItemsRecorded ?? this.bodyItemsRecorded,
      slider: slider ?? this.slider,
      filterButton: filterButton ?? this.filterButton,
    );
  }
}
