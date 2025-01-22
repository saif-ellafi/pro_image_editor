// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';

import '/core/mixins/converted_configs.dart';
import '/core/mixins/editor_configs_mixin.dart';
import '/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/layers/layer.dart';
import '/plugins/defer_pointer/defer_pointer.dart';
import 'layer_interaction_border_painter.dart';
import 'layer_interaction_button.dart';

/// A stateful widget that provides interactive controls for manipulating
/// layers in an image editor.
///
/// This widget is designed to enhance layer interaction by providing buttons
/// for actions like
/// editing, removing, and transforming layers. It displays interactive UI
/// elements based on the state of the layer (selected or interactive) and
/// enables user interactions through gestures and tooltips.

class LayerInteractionHelperWidget extends StatefulWidget
    with SimpleConfigsAccess {
  /// Creates a [LayerInteractionHelperWidget].
  ///
  /// This widget provides a layer manipulation interface, allowing for actions
  /// like editing, removing, and transforming layers in an image editing
  /// application.
  ///
  /// Example:
  /// ```
  /// LayerInteractionHelperWidget(
  ///   layerData: myLayerData,
  ///   child: ImageWidget(),
  ///   configs: myEditorConfigs,
  ///   onEditLayer: () {
  ///     // Handle edit layer action
  ///   },
  ///   onRemoveLayer: () {
  ///     // Handle remove layer action
  ///   },
  ///   isInteractive: true,
  ///   selected: true,
  /// )
  /// ```
  const LayerInteractionHelperWidget({
    super.key,
    required this.layerData,
    required this.child,
    required this.configs,
    this.onEditLayer,
    this.onRemoveLayer,
    this.onScaleRotateDown,
    this.onScaleRotateUp,
    this.selected = false,
    this.isInteractive = false,
    this.callbacks = const ProImageEditorCallbacks(),
  });

  /// The configuration settings for the image editor.
  ///
  /// These settings determine various aspects of the editor's behavior and
  /// appearance, influencing how layer interactions are handled.
  @override
  final ProImageEditorConfigs configs;

  /// Callbacks for the image editor.
  ///
  /// These callbacks provide hooks for responding to various editor events
  /// and interactions, allowing for customized behavior.
  @override
  final ProImageEditorCallbacks callbacks;

  /// The widget representing the layer's visual content.
  ///
  /// This child widget displays the content that users will interact with
  /// using the layer manipulation controls.
  final Widget child;

  /// Callback for handling the edit layer action.
  ///
  /// This callback is triggered when the user selects the edit option for a
  /// layer, allowing for modifications to the layer's content.
  final Function()? onEditLayer;

  /// Callback for handling the remove layer action.
  ///
  /// This callback is triggered when the user selects the remove option for a
  /// layer, enabling the removal of the layer from the editor.
  final Function()? onRemoveLayer;

  /// Callback for handling pointer down events associated with scale and
  /// rotate gestures.
  ///
  /// This callback is triggered when the user presses down on the button for
  /// scaling or rotating, allowing for interaction tracking.
  final Function(PointerDownEvent)? onScaleRotateDown;

  /// Callback for handling pointer up events associated with scale and rotate
  /// gestures.
  ///
  /// This callback is triggered when the user releases the button after scaling
  /// or rotating, finalizing the interaction.
  final Function(PointerUpEvent)? onScaleRotateUp;

  /// Data representing the layer's configuration and state.
  ///
  /// This data is used to determine the layer's appearance, behavior, and the
  /// interactions available to the user.
  final Layer layerData;

  /// Indicates whether the layer is interactive.
  ///
  /// If true, the layer supports interactive features such as gestures and
  /// tooltips.
  final bool isInteractive;

  /// Indicates whether the layer is selected.
  ///
  /// If true, the layer is highlighted, and interaction buttons are displayed.
  final bool selected;

  @override
  State<LayerInteractionHelperWidget> createState() =>
      _LayerInteractionHelperWidgetState();
}

/// The state class for [LayerInteractionHelperWidget].
///
/// This class manages the interactive state of the layer, including visibility
/// of tooltips and the display of interaction buttons for layer manipulation.

class _LayerInteractionHelperWidgetState
    extends State<LayerInteractionHelperWidget>
    with ImageEditorConvertedConfigs, SimpleConfigsAccessState {
  final _rebuildStream = StreamController.broadcast();

  bool _tooltipVisible = true;

  @override
  void dispose() {
    _rebuildStream.close();
    super.dispose();
  }

  @override
  void setState(void Function() fn) {
    _rebuildStream.add(null);
    super.setState(fn);
  }

  void toggleTooltipVisibility(bool state) {
    setState(() => _tooltipVisible = state);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isInteractive) {
      // Return the child widget directly if the layer is not interactive.
      return widget.child;
    } else if (!widget.selected) {
      // Use a defer pointer if the layer is not selected, preventing
      // interaction.
      return DeferPointer(child: widget.child);
    }
    return TooltipVisibility(
      visible: _tooltipVisible && layerInteraction.style.showTooltips,
      child: DeferPointer(
        child: Stack(
          children: [
            Container(
              margin: EdgeInsets.all(
                layerInteraction.style.buttonRadius +
                    layerInteraction.style.strokeWidth * 2,
              ),
              child: CustomPaint(
                foregroundPainter: LayerInteractionBorderPainter(
                  theme: layerInteraction.style,
                  borderStyle: layerInteraction.style.borderStyle,
                ),
                child: widget.child,
              ),
            ),
            _buildRemoveIcon(),
            if (widget.layerData.runtimeType == TextLayer ||
                (widget.layerData.runtimeType == WidgetLayer &&
                    widget.callbacks.stickerEditorCallbacks?.onTapEditSticker !=
                        null))
              _buildEditIcon(),
            _buildRotateScaleIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildRotateScaleIcon() {
    return layerInteraction.widgets.rotateScaleIcon?.call(
          _rebuildStream.stream,
          (value) => widget.onScaleRotateDown?.call(value),
          (value) => widget.onScaleRotateUp?.call(value),
          toggleTooltipVisibility,
          -widget.layerData.rotation,
        ) ??
        Positioned(
          bottom: 0,
          right: 0,
          child: LayerInteractionButton(
            toggleTooltipVisibility: toggleTooltipVisibility,
            rotation: -widget.layerData.rotation,
            onScaleRotateDown: widget.onScaleRotateDown,
            onScaleRotateUp: widget.onScaleRotateUp,
            buttonRadius: layerInteraction.style.buttonRadius,
            cursor: layerInteraction.style.rotateScaleCursor,
            icon: layerInteraction.icons.rotateScale,
            tooltip: i18n.layerInteraction.rotateScale,
            color: layerInteraction.style.buttonScaleRotateColor,
            background: layerInteraction.style.buttonScaleRotateBackground,
          ),
        );
  }

  Widget _buildEditIcon() {
    return layerInteraction.widgets.editIcon?.call(
          _rebuildStream.stream,
          () => widget.onEditLayer?.call(),
          toggleTooltipVisibility,
          -widget.layerData.rotation,
        ) ??
        Positioned(
          top: 0,
          right: 0,
          child: LayerInteractionButton(
            toggleTooltipVisibility: toggleTooltipVisibility,
            rotation: -widget.layerData.rotation,
            onTap: widget.onEditLayer,
            buttonRadius: layerInteraction.style.buttonRadius,
            cursor: layerInteraction.style.editCursor,
            icon: layerInteraction.icons.edit,
            tooltip: i18n.layerInteraction.edit,
            color: layerInteraction.style.buttonEditTextColor,
            background: layerInteraction.style.buttonEditTextBackground,
          ),
        );
  }

  Widget _buildRemoveIcon() {
    return layerInteraction.widgets.removeIcon?.call(
          _rebuildStream.stream,
          () => widget.onRemoveLayer?.call(),
          toggleTooltipVisibility,
          -widget.layerData.rotation,
        ) ??
        Positioned(
          top: 0,
          left: 0,
          child: LayerInteractionButton(
            toggleTooltipVisibility: toggleTooltipVisibility,
            rotation: -widget.layerData.rotation,
            onTap: widget.onRemoveLayer,
            buttonRadius: layerInteraction.style.buttonRadius,
            cursor: layerInteraction.style.removeCursor,
            icon: layerInteraction.icons.remove,
            tooltip: i18n.layerInteraction.remove,
            color: layerInteraction.style.buttonRemoveColor,
            background: layerInteraction.style.buttonRemoveBackground,
          ),
        );
  }
}
