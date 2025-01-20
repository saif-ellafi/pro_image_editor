import 'dart:async';

import 'package:flutter/material.dart';

import '/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/features/crop_rotate_editor/widgets/crop_layer_painter.dart';
import '/features/main_editor/controllers/main_editor_controllers.dart';
import '/features/main_editor/services/layer_interaction_manager.dart';
import '/shared/services/content_recorder/widgets/content_recorder.dart';
import '/shared/widgets/extended/extended_interactive_viewer.dart';
import '../main_editor.dart';
import '../services/sizes_manager.dart';
import '../services/state_manager.dart';
import 'main_editor_font_preloader.dart';

class MainEditorInteractiveContent extends StatelessWidget {
  const MainEditorInteractiveContent({
    super.key,
    required this.buildImage,
    required this.buildLayers,
    required this.buildHelperLines,
    required this.buildRemoveIcon,
    required this.callbacks,
    required this.sizesManager,
    required this.configs,
    required this.layerInteractionManager,
    required this.controllers,
    required this.selectedLayerIndex,
    required this.processFinalImage,
    required this.rebuildController,
    required this.stateManager,
    required this.interactiveViewerKey,
    required this.state,
  });

  final Widget Function() buildImage;
  final Widget Function() buildLayers;
  final Widget Function() buildHelperLines;
  final Widget Function() buildRemoveIcon;

  final SizesManager sizesManager;
  final ProImageEditorState state;
  final ProImageEditorConfigs configs;
  final ProImageEditorCallbacks callbacks;
  final LayerInteractionManager layerInteractionManager;
  final MainEditorControllers controllers;
  final int selectedLayerIndex;
  final bool processFinalImage;
  final StreamController<void> rebuildController;
  final StateManager stateManager;
  final GlobalKey<ExtendedInteractiveViewerState> interactiveViewerKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          MainEditorFontPreloader(emojiEditorConfigs: configs.emojiEditor),
          Padding(
            padding: selectedLayerIndex >= 0 &&
                    configs.layerInteraction.hideToolbarOnInteraction
                ? EdgeInsets.only(
                    top: sizesManager.appBarHeight,
                    bottom: sizesManager.bottomBarHeight,
                  )
                : EdgeInsets.zero,
            child: _buildInteractiveViewer(),
          ),

          /// Build crop area overlay
          if (configs.imageGeneration.captureOnlyBackgroundImageArea)
            _buildCropAreaOverlay(),

          /// Build helper content
          if (!processFinalImage) ...[
            buildHelperLines(),
            if (selectedLayerIndex >= 0) buildRemoveIcon(),
          ],

          /// Build custom body items
          if (configs.mainEditor.widgets.bodyItems != null)
            ...configs.mainEditor.widgets.bodyItems!(
              state,
              rebuildController.stream,
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveViewer() {
    return ExtendedInteractiveViewer(
      key: interactiveViewerKey,
      boundaryMargin: configs.mainEditor.boundaryMargin,
      enableZoom: configs.mainEditor.enableZoom,
      minScale: configs.mainEditor.editorMinScale,
      maxScale: configs.mainEditor.editorMaxScale,
      onInteractionStart: (details) {
        callbacks.mainEditorCallbacks?.onEditorZoomScaleStart?.call(details);
        layerInteractionManager.freeStyleHighPerformanceEditorZoom = (configs
                    .paintEditor.freeStyleHighPerformanceMoving ??
                !isDesktop) ||
            (configs.paintEditor.freeStyleHighPerformanceScaling ?? !isDesktop);

        controllers.uiLayerCtrl.add(null);
      },
      onInteractionUpdate: (details) {
        callbacks.mainEditorCallbacks?.onEditorZoomScaleUpdate?.call(details);
        controllers.cropLayerPainterCtrl.add(null);
      },
      onInteractionEnd: (details) {
        callbacks.mainEditorCallbacks?.onEditorZoomScaleEnd?.call(details);
        layerInteractionManager.freeStyleHighPerformanceEditorZoom = false;
        controllers.uiLayerCtrl.add(null);
        controllers.cropLayerPainterCtrl.add(null);
      },
      child: _buildContentRecorder(),
    );
  }

  Widget _buildContentRecorder() {
    return ContentRecorder(
      key: const ValueKey('main-editor-content-recorder'),
      autoDestroyController: false,
      controller: controllers.screenshot,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          buildImage(),
          buildLayers(),
          if (configs.mainEditor.widgets.bodyItemsRecorded != null)
            ...configs.mainEditor.widgets.bodyItemsRecorded!(
                state, rebuildController.stream),
        ],
      ),
    );
  }

  Widget _buildCropAreaOverlay() {
    return Hero(
      tag: 'crop_layer_painter_hero',
      child: StreamBuilder(
        stream: controllers.cropLayerPainterCtrl.stream,
        builder: (context, snapshot) {
          return CustomPaint(
            foregroundPainter: configs
                    .imageGeneration.captureOnlyBackgroundImageArea
                ? CropLayerPainter(
                    opacity:
                        configs.mainEditor.style.outsideCaptureAreaLayerOpacity,
                    backgroundColor: configs.mainEditor.style.background,
                    imgRatio: stateManager.transformConfigs.isNotEmpty
                        ? stateManager
                            .transformConfigs.cropRect.size.aspectRatio
                        : sizesManager.decodedImageSize.aspectRatio,
                    isRoundCropper: configs.cropRotateEditor.roundCropper,
                    is90DegRotated:
                        stateManager.transformConfigs.is90DegRotated,
                    interactiveViewerScale:
                        interactiveViewerKey.currentState?.scaleFactor ?? 1.0,
                    interactiveViewerOffset:
                        interactiveViewerKey.currentState?.offset ??
                            Offset.zero,
                  )
                : null,
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
