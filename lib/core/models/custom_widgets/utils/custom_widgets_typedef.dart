// Flutter imports:
import 'package:flutter/widgets.dart';
import 'package:pro_image_editor/core/models/layers/layer.dart';

import '/features/main_editor/main_editor.dart';
import '/shared/widgets/layer/models/layer_item_interaction.dart';
import '/shared/widgets/reactive_widgets/reactive_custom_widget.dart';

/// {@template removeLayerArea}
/// A function that returns a [Widget] used as a remove area in the
/// editor interface. It provides access to the [removeAreaKey] for
/// positioning or targeting the remove area, the [editor] state for
/// managing editor-related actions, and a [rebuildStream] to handle
/// updates for interactive elements.
///
/// The [removeAreaKey] parameter is a [GlobalKey] that points to the
/// specific area where elements should be removed or targeted. The
/// [editor] parameter allows access to the current editor state, and
/// the [rebuildStream] stream enables dynamic rebuilding of the widget.
///
/// **Example Usage:**
/// ```dart
/// removeLayerArea: (removeAreaKey, editor, rebuildStream) {
///   return Positioned(
///     key: removeAreaKey,
///     top: 0,
///     left: 0,
///     child: SafeArea(
///       bottom: false,
///       child: StreamBuilder(
///         stream: rebuildStream,
///         builder: (context, snapshot) {
///           return Container(
///             height: kToolbarHeight,
///             width: kToolbarHeight,
///             decoration: BoxDecoration(
///               color: editor.layerInteractionManager.hoverRemoveBtn
///                   ? editor.imageEditorTheme.layerInteraction
///                       .removeAreaBackgroundActive
///                   : editor.imageEditorTheme.layerInteraction
///                       .removeAreaBackgroundInactive,
///               borderRadius: const BorderRadius.only(
///                 bottomRight: Radius.circular(100),
///               ),
///             ),
///             padding: const EdgeInsets.only(right: 12, bottom: 7),
///             child: Center(
///               child: Icon(
///                 editor.icons.removeElementZone,
///                 size: 28,
///               ),
///             ),
///           );
///         },
///       ),
///     ),
///   );
/// },
/// ```
/// {@endtemplate}
typedef RemoveLayerArea = Widget Function(
  GlobalKey removeAreaKey,
  ProImageEditorState editor,
  Stream<void> rebuildStream,
);

/// A typedef for creating a [ReactiveWidget] that manages crop editor
/// aspect ratio options.
///
/// - [T] - The type representing the editor state.
/// - [editorState] - The current state of the editor.
/// - [rebuildStream] - A [Stream] that triggers the widget to rebuild.
/// - [aspectRatio] - The aspect ratio to be set.
/// - [originalAspectRatio] - The original aspect ratio.
///
/// Returns a [ReactiveWidget] that provides options for crop editor
/// aspect ratios.
typedef CropEditorAspectRatioOptions<T> = ReactiveWidget Function(
  T editorState,
  Stream<void> rebuildStream,
  double aspectRatio,
  double originalAspectRatio,
);

/// A typedef for creating a [ReactiveWidget] that includes a custom
/// color picker.
///
/// - [T] - The type representing the editor state.
///
/// {@template colorPickerWidget}
/// - [editorState] - The current state of the editor.
/// - [rebuildStream] - A [Stream] that triggers the widget to rebuild.
/// - [currentColor] - The currently selected color.
/// - [setColor] - A function to update the selected color.
///
/// Returns an optional [ReactiveWidget] that provides a custom color
/// picker.
///
/// **Example:**
/// ```dart
/// colorPicker: (editor, rebuildStream, currentColor, setColor) =>
///    ReactiveWidget(
///      stream: rebuildStream,
///      builder: (_) => BarColorPicker(
///        configs: editor.configs,
///        length: 200,
///        horizontal: false,
///        initialColor: currentColor,
///        colorListener: (int value) {
///          setColor(Color(value));
///        },
///      ),
/// ),
/// ```
/// {@endtemplate}
typedef CustomColorPicker<T> = ReactiveWidget? Function(
  T editorState,
  Stream<void> rebuildStream,
  Color currentColor,
  void Function(Color color) setColor,
);

/// A typedef for creating a [ReactiveWidget] that includes a custom
/// slider.
///
/// - [T] - The type representing the editor state.
///
/// {@template customSliderWidget}
/// - [editorState] - The current state of the editor.
/// - [rebuildStream] - A [Stream] that triggers the widget to rebuild.
/// - [value] - The current value of the slider.
/// - [onChanged] - A function to handle changes to the slider's value.
/// - [onChangeEnd] - A function to handle the end of slider value changes.
///
/// Returns a [ReactiveWidget] that provides a custom slider.
///
/// **Example:**
/// ```dart
/// slider: (editorState, rebuildStream, value, onChanged, onChangeEnd) {
///   return ReactiveWidget(
///     stream: rebuildStream,
///     builder: (_) => Slider(
///       onChanged: onChanged,
///       onChangeEnd: onChangeEnd,
///       value: value,
///       activeColor: Colors.blue.shade200,
///     ),
///   );
/// },
/// ```
/// {@endtemplate}
typedef CustomSlider<T> = ReactiveWidget Function(
  T editorState,
  Stream<void> rebuildStream,
  double value,
  Function(double value) onChanged,
  Function(double value) onChangeEnd,
);

/// A typedef for a function that creates a [ReactiveWidget] for a tap
/// interaction.
///
/// The function takes the following parameters:
///
/// * [rebuildStream]: A stream that triggers the widget to rebuild.
/// * [onTap]: A callback function that is invoked when the widget is tapped.
/// * [toggleTooltipVisibility]: A function that toggles the visibility of a
/// tooltip based on the boolean value passed.
/// * [rotation]: A double value representing the current rotation of the
/// widget.
///
/// Returns a nullable [ReactiveWidget].
typedef LayerInteractionTapButton = ReactiveWidget? Function(
  Stream<void> rebuildStream,
  Function() onTap,
  double rotation,
);

/// A typedef for a function that creates a [ReactiveWidget] for scale
/// and rotate interactions.
///
/// The function takes the following parameters:
///
/// * [rebuildStream]: A stream that triggers the widget to rebuild.
/// * [onScaleRotateDown]: A callback function that is invoked when the
/// scale/rotate action starts (on pointer down event).
/// * [onScaleRotateUp]: A callback function that is invoked when the
/// scale/rotate action ends (on pointer up event).
/// * [toggleTooltipVisibility]: A function that toggles the visibility of a
/// tooltip based on the boolean value passed.
/// * [rotation]: A double value representing the current rotation of the
/// widget.
///
/// Returns a nullable [ReactiveWidget].
typedef LayerInteractionScaleRotateButton = ReactiveWidget? Function(
  Stream<void> rebuildStream,
  Function(PointerDownEvent) onScaleRotateDown,
  Function(PointerUpEvent) onScaleRotateUp,
  double rotation,
);

/// A typedef for a function that builds a reactive widget for a layer item.
///
/// This function receives a stream of rebuild signals, the layer data,
/// and the interactions available for the layer item.
/// It is responsible for building a reactive widget that responds to
/// changes in the rebuild stream and updates accordingly.
typedef LayerInteractionItem = ReactiveWidget Function(
  Stream<void> rebuildStream,
  Layer layer,
  LayerItemInteractions interactions,
);

/// A typedef for a function that builds a widget for the layer border.
///
/// This function receives the layer widget and the layer data as
/// parameters. It is responsible for building a widget that
/// represents the border around the layer.
typedef LayerInteractionBorder = Widget Function(
    Widget layerWidget, Layer layerData);

/// {@template customBodyItem}
/// Add custom widgets at a specific position inside the body, which will not
/// be recorded in the final image. This is useful for interaction buttons or
/// dynamic overlays that should not appear in the exported image.
///
/// **Example:**
/// ```dart
/// bodyItems: (editor, rebuildStream) => [
///   ReactiveWidget(
///     stream: rebuildStream,
///     builder: (_) => Container(
///       width: 100,
///       height: 100,
///       color: Colors.blue,
///     ),
///   ),
/// ],
/// ```
/// {@endtemplate}

/// {@template customBodyItemRecorded}
/// Add custom widgets that will be recorded in the final image generation,
/// making it ideal for frames or other static decorations that should appear
/// in the exported image.
///
/// **Example:**
/// ```dart
/// bodyItemsRecorded: (editor, rebuildStream) => [
///   ReactiveWidget(
///     stream: rebuildStream,
///     builder: (_) => Container(
///       width: 300,
///       height: 300,
///       decoration: BoxDecoration(
///         border: Border.all(color: Colors.black, width: 4),
///       ),
///     ),
///   ),
/// ],
/// ```
/// {@endtemplate}

/// A function that returns a list of [ReactiveWidget]s, allowing
/// customization of body items based on the [editor] state and a
/// [rebuildStream] to trigger updates.
///
/// The [editor] parameter provides access to the current editor state,
/// enabling customization based on the editor's properties. The
/// [rebuildStream] stream allows dynamic updates to the widgets.
///
/// **Example Usage:**
/// ```dart
/// CustomBodyItems<ProImageEditorState> customItems = (editor, rebuildStream)
/// => [
///   ReactiveWidget(
///     stream: rebuildStream,
///     builder: (_) => Container(
///       width: 100,
///       height: 100,
///       color: Colors.red,
///     ),
///   ),
/// ];
/// ```
typedef CustomBodyItems<T> = List<ReactiveWidget> Function(
  T editor,
  Stream<void> rebuildStream,
);
