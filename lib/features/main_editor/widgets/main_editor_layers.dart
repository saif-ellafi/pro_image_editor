import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/layers/layer.dart';
import '/features/main_editor/controllers/main_editor_controllers.dart';
import '/features/main_editor/services/layer_interaction_manager.dart';
import '/features/main_editor/services/sizes_manager.dart';
import '/plugins/defer_pointer/defer_pointer.dart';
import '/shared/widgets/extended/extended_mouse_cursor.dart';
import '/shared/widgets/layer/layer_widget.dart';
import '../main_editor.dart';

/// A widget that manages and displays layers in the main editor, handling
/// interactions, configurations, and callbacks for user actions.
class MainEditorLayers extends StatelessWidget {
  /// Creates a `MainEditorLayers` widget with the necessary configurations,
  /// managers, and callbacks.
  ///
  /// - [state]: Represents the current state of the editor.
  /// - [configs]: Configuration settings for the editor.
  /// - [callbacks]: Provides callbacks for editor interactions.
  /// - [sizesManager]: Manages size-related settings and adjustments.
  /// - [controllers]: Manages the main editor's controllers.
  /// - [layerInteraction]: Configurations for layer interactions.
  /// - [layerInteractionManager]: Handles interactions with editor layers.
  /// - [mouseCursorsKey]: Key for managing mouse cursor regions.
  /// - [activeLayers]: List of active layers in the editor.
  /// - [selectedLayerIndex]: The index of the currently selected layer.
  /// - [isSubEditorOpen]: Indicates whether a sub-editor is currently open.
  /// - [checkInteractiveViewer]: Callback to check the state of the
  ///   interactive viewer.
  /// - [onTextLayerTap]: Callback triggered when a text layer is tapped.
  /// - [setTempLayer]: Callback to temporarily set a layer for interaction.
  /// - [onContextMenuToggled]: Callback triggered when the context menu is
  ///   toggled.
  const MainEditorLayers({
    super.key,
    required this.controllers,
    required this.layerInteraction,
    required this.layerInteractionManager,
    required this.configs,
    required this.callbacks,
    required this.sizesManager,
    required this.mouseCursorsKey,
    required this.selectedLayerIndex,
    required this.activeLayers,
    required this.isSubEditorOpen,
    required this.checkInteractiveViewer,
    required this.onTextLayerTap,
    required this.state,
    required this.setTempLayer,
    required this.onContextMenuToggled,
  });

  /// Represents the current state of the editor.
  final ProImageEditorState state;

  /// Configuration settings for the editor.
  final ProImageEditorConfigs configs;

  /// Provides callbacks for editor interactions.
  final ProImageEditorCallbacks callbacks;

  /// Manages size-related settings and adjustments.
  final SizesManager sizesManager;

  /// Manages the main editor's controllers.
  final MainEditorControllers controllers;

  /// Configurations for layer interactions.
  final LayerInteractionConfigs layerInteraction;

  /// Handles interactions with editor layers.
  final LayerInteractionManager layerInteractionManager;

  /// Key for managing mouse cursor regions.
  final GlobalKey<ExtendedMouseRegionState> mouseCursorsKey;

  /// List of active layers in the editor.
  final List<Layer> activeLayers;

  /// The index of the currently selected layer.
  final int selectedLayerIndex;

  /// Indicates whether a sub-editor is currently open.
  final bool isSubEditorOpen;

  /// Callback to check the state of the interactive viewer.
  final Function() checkInteractiveViewer;

  /// Callback triggered when a text layer is tapped.
  final Function(TextLayer layer) onTextLayerTap;

  /// Callback to temporarily set a layer for interaction.
  final Function(Layer layer) setTempLayer;

  /// Callback triggered when the context menu is toggled.
  final Function(bool isOpen)? onContextMenuToggled;

  // Helper methods for handling layer interactions
  void _handleEditTap(int index, Layer layer) {
    if (layer is TextLayer) {
      onTextLayerTap(layer);
    } else if (layer is WidgetLayer) {
      callbacks.stickerEditorCallbacks?.onTapEditSticker
          ?.call(state, layer, index);
    }
  }

  void _handleLayerTap(Layer layer) {
    if (layerInteractionManager.layersAreSelectable(configs) &&
        layer.interaction.enableSelection) {
      layerInteractionManager.selectedLayerId =
          layer.id == layerInteractionManager.selectedLayerId ? '' : layer.id;
      checkInteractiveViewer();
    } else if (layer is TextLayer && layer.interaction.enableEdit) {
      onTextLayerTap(layer);
    }
  }

  void _handleTapUp(Layer layer) {
    if (layerInteractionManager.hoverRemoveBtn) {
      state.removeLayer(layer);
    }
    controllers.uiLayerCtrl.add(null);
    callbacks.mainEditorCallbacks?.handleUpdateUI();
    state.selectedLayerIndex = -1;
    checkInteractiveViewer();
  }

  void _handleTapDown(int index, Layer layer) {
    state.selectedLayerIndex = index;
    setTempLayer(layer);
    checkInteractiveViewer();
  }

  void _handleScaleRotateDown(int index, Size layerOriginalSize, Layer layer) {
    state.selectedLayerIndex = index;
    layerInteractionManager
      ..rotateScaleLayerSizeHelper = layerOriginalSize
      ..rotateScaleLayerScaleHelper = layer.scale;
    checkInteractiveViewer();
  }

  void _handleScaleRotateUp() {
    layerInteractionManager
      ..rotateScaleLayerSizeHelper = null
      ..rotateScaleLayerScaleHelper = null;
    state.setState(() => state.selectedLayerIndex = -1);
    checkInteractiveViewer();
    callbacks.mainEditorCallbacks?.handleUpdateUI();
  }

  void _handleRemoveLayer(Layer layer) {
    state.setState(() => state.removeLayer(layer));
    callbacks.mainEditorCallbacks?.handleUpdateUI();
  }

  /// Handles mouse hover events to change the cursor style
  void _handleMouseHover(PointerHoverEvent event) {
    final bool hasHit = activeLayers
        .any((element) => element is PaintLayer && element.item.hit);

    final activeCursor = mouseCursorsKey.currentState!.currentCursor;
    final moveCursor = layerInteraction.style.hoverCursor;

    if (hasHit && activeCursor != moveCursor) {
      mouseCursorsKey.currentState!.setCursor(moveCursor);
    } else if (!hasHit && activeCursor != SystemMouseCursors.basic) {
      mouseCursorsKey.currentState!.setCursor(SystemMouseCursors.basic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: selectedLayerIndex >= 0,
      child: StreamBuilder<bool>(
        stream: controllers.layerHeroResetCtrl.stream,
        initialData: false,
        builder: (context, resetLayerSnapshot) {
          // Render an empty container when resetting layers
          if (resetLayerSnapshot.data!) return const SizedBox.shrink();

          return _buildLayerRepaintBoundary();
        },
      ),
    );
  }

  /// Builds the layer repaint boundary widget
  Widget _buildLayerRepaintBoundary() {
    return RepaintBoundary(
      child: ExtendedMouseRegion(
        key: mouseCursorsKey,
        onHover: isDesktop ? _handleMouseHover : null,
        child: DeferredPointerHandler(
          child: StreamBuilder(
            stream: controllers.uiLayerCtrl.stream,
            builder: (context, snapshot) {
              return Stack(
                children: activeLayers
                    .asMap()
                    .entries
                    .map(_buildLayerWidget)
                    .toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds a single layer widget
  Widget _buildLayerWidget(MapEntry<int, Layer> entry) {
    int index = entry.key;
    Layer layer = entry.value;
    return LayerWidget(
      key: layer.key,
      configs: configs,
      callbacks: callbacks,
      editorCenterX: sizesManager.editorSize.width / 2,
      editorCenterY: sizesManager.editorCenterY(selectedLayerIndex),
      layerData: layer,
      enableHitDetection: layerInteractionManager.enabledHitDetection,
      selected: layerInteractionManager.selectedLayerId == layer.id,
      isInteractive: !isSubEditorOpen,
      highPerformanceMode: layerInteractionManager.freeStyleHighPerformance,
      onEditTap: () => _handleEditTap(index, layer),
      onTap: _handleLayerTap,
      onTapUp: () => _handleTapUp(layer),
      onTapDown: () => _handleTapDown(index, layer),
      onScaleRotateDown: (details, layerOriginalSize) =>
          _handleScaleRotateDown(index, layerOriginalSize, layer),
      onContextMenuToggled: onContextMenuToggled,
      onScaleRotateUp: (details) => _handleScaleRotateUp(),
      onRemoveTap: () => _handleRemoveLayer(layer),
    );
  }
}
