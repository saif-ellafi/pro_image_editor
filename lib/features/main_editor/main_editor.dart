import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui show Image;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '/core/mixins/converted_configs.dart';
import '/core/mixins/editor_callbacks_mixin.dart';
import '/core/mixins/editor_configs_mixin.dart';
import '/core/models/history/last_layer_interaction_position.dart';
import '/core/models/styles/draggable_sheet_style.dart';
import '/features/main_editor/widgets/main_editor_appbar.dart';
import '/features/main_editor/widgets/main_editor_background_image.dart';
import '/features/main_editor/widgets/main_editor_bottombar.dart';
import '/features/main_editor/widgets/main_editor_helper_lines.dart';
import '/features/main_editor/widgets/main_editor_layers.dart';
import '/features/main_editor/widgets/main_editor_remove_layer_area.dart';
import '/pro_image_editor.dart';
import '/shared/services/content_recorder/widgets/content_recorder.dart';
import '/shared/services/import_export/export_state_history.dart';
import '/shared/services/layer_transform_generator.dart';
import '/shared/utils/debounce.dart';
import '/shared/widgets/adaptive_dialog.dart';
import '/shared/widgets/extended/extended_interactive_viewer.dart';
import '/shared/widgets/extended/extended_mouse_cursor.dart';
import '/shared/widgets/screen_resize_detector.dart';
import '../filter_editor/types/filter_matrix.dart';
import '../filter_editor/widgets/filter_generator.dart';
import '../tune_editor/models/tune_adjustment_matrix.dart';
import 'controllers/main_editor_controllers.dart';
import 'mixins/main_editor_global_keys.dart';
import 'services/desktop_interaction_manager.dart';
import 'services/layer_copy_manager.dart';
import 'services/layer_interaction_manager.dart';
import 'services/main_editor_state_history_service.dart';
import 'services/sizes_manager.dart';
import 'services/state_manager.dart';
import 'widgets/main_editor_interactive_content.dart';

/// A widget for image editing using ProImageEditor.
///
/// `ProImageEditor` provides a versatile image editing widget for Flutter
/// applications.
/// It allows you to edit images from various sources like memory, files,
/// assets, or network URLs.
///
/// You can use one of the specific constructors, such as `memory`, `file`,
/// `asset`, or `network`,
/// to create an instance of this widget based on your image source.
/// Additionally, you can provide
/// custom configuration settings through the `configs` parameter.
///
/// Example usage:
///
/// ```dart
/// ProImageEditor.memory(Uint8List.fromList(imageBytes));
/// ProImageEditor.file(File('path/to/image.jpg'));
/// ProImageEditor.asset('assets/images/image.png');
/// ProImageEditor.network('https://example.com/image.jpg');
/// ```
///
/// To handle image editing, you can use the callbacks provided by the
/// `EditorConfigs` instance
/// passed through the `configs` parameter.
///
/// See also:
/// - [ProImageEditorConfigs] for configuring image editing options.
/// - [ProImageEditorCallbacks] for callbacks.
class ProImageEditor extends StatefulWidget
    with SimpleConfigsAccess, SimpleCallbacksAccess {
  /// Creates a `ProImageEditor` widget for image editing.
  ///
  /// Use one of the specific constructors like `memory`, `file`, `asset`, or
  /// `network`
  /// to create an instance of this widget based on your image source.
  ///
  /// The [byteArray], [assetPath], [networkUrl], and [file] parameters
  /// represent different
  /// sources of the image data. At least one of these parameters must not be
  /// null.
  ///
  /// {@template mainEditorConfigs}
  /// The `key` parameter is an optional parameter used to provide a `Key` to
  /// the widget for identification and state preservation.
  ///
  /// The `configs` parameter allows you to customize the image editing
  /// experience by providing various configuration options. If not specified,
  /// default settings will be used.
  ///
  /// The `callbacks` parameter is required and specifies the callbacks to
  /// handle events and interactions within the image editor.
  /// {@endtemplate}
  const ProImageEditor._({
    super.key,
    required this.callbacks,
    this.byteArray,
    this.assetPath,
    this.networkUrl,
    this.file,
    this.configs = const ProImageEditorConfigs(),
  }) : assert(
          byteArray != null ||
              file != null ||
              networkUrl != null ||
              assetPath != null,
          'byteArray, file, networkUrl, or assetPath must not be null.',
        );

  /// This constructor creates a `ProImageEditor` widget configured to edit an
  /// image loaded from the specified `byteArray`.
  ///
  /// The `byteArray` parameter should contain the image data as a `Uint8List`.
  ///
  /// {@macro mainEditorConfigs}
  ///
  /// Example usage:
  /// ```dart
  /// ProImageEditor.ProImageEditor.memory(
  ///   bytes,
  /// {@template mainEditorDemoTemplateCode}
  ///   configs: ProImageEditorConfigs(),
  ///   callbacks: ProImageEditorCallbacks(
  ///      onImageEditingComplete: (Uint8List bytes) async {
  ///        /*
  ///          `Your code to handle the edited image. Upload it to your server
  ///           as an example.
  ///
  ///           You can choose to use await, so that the load dialog remains
  ///           visible until your code is ready,
  ///           or no async, so that the load dialog closes immediately.
  ///        */
  ///        Navigator.pop(context);
  ///      },
  ///   ),
  /// {@endtemplate}
  /// )
  /// ```
  factory ProImageEditor.memory(
    Uint8List byteArray, {
    Key? key,
    required ProImageEditorCallbacks callbacks,
    ProImageEditorConfigs configs = const ProImageEditorConfigs(),
  }) {
    return ProImageEditor._(
      key: key,
      byteArray: byteArray,
      configs: configs,
      callbacks: callbacks,
    );
  }

  /// This constructor creates a `ProImageEditor` widget configured to edit an
  /// image loaded from the specified `file`.
  ///
  /// The `file` parameter should point to the image file.
  ///
  /// {@macro mainEditorConfigs}
  ///
  /// Example usage:
  /// ```dart
  /// ProImageEditor.ProImageEditor.file(
  ///   File(pathToMyFile),
  ///   {@macro mainEditorDemoTemplateCode}
  /// )
  /// ```
  factory ProImageEditor.file(
    File file, {
    Key? key,
    ProImageEditorConfigs configs = const ProImageEditorConfigs(),
    required ProImageEditorCallbacks callbacks,
  }) {
    return ProImageEditor._(
      key: key,
      file: file,
      configs: configs,
      callbacks: callbacks,
    );
  }

  /// This constructor creates a `ProImageEditor` widget configured to edit an
  /// image loaded from the specified `assetPath`.
  ///
  /// The `assetPath` parameter should specify the path to the image asset.
  ///
  /// {@macro mainEditorConfigs}
  ///
  /// Example usage:
  /// ```dart
  /// ProImageEditor.asset(
  ///   'assets/demo.png',
  ///   {@macro mainEditorDemoTemplateCode}
  /// )
  /// ```
  factory ProImageEditor.asset(
    String assetPath, {
    Key? key,
    ProImageEditorConfigs configs = const ProImageEditorConfigs(),
    required ProImageEditorCallbacks callbacks,
  }) {
    return ProImageEditor._(
      key: key,
      assetPath: assetPath,
      configs: configs,
      callbacks: callbacks,
    );
  }

  /// This constructor creates a `ProImageEditor` widget configured to edit an
  /// image loaded from the specified `networkUrl`.
  ///
  /// The `networkUrl` parameter specifies the URL from which the image will be
  /// loaded.
  ///
  /// {@macro mainEditorConfigs}
  ///
  /// Example usage:
  /// ```dart
  /// ProImageEditor.network(
  ///   'https://example.com/image.jpg',
  ///   {@macro mainEditorDemoTemplateCode}
  /// )
  /// ```
  factory ProImageEditor.network(
    String networkUrl, {
    Key? key,
    ProImageEditorConfigs configs = const ProImageEditorConfigs(),
    required ProImageEditorCallbacks callbacks,
  }) {
    return ProImageEditor._(
      key: key,
      networkUrl: networkUrl,
      configs: configs,
      callbacks: callbacks,
    );
  }
  @override
  final ProImageEditorConfigs configs;
  @override
  final ProImageEditorCallbacks callbacks;

  /// Image data as a `Uint8List` from memory.
  final Uint8List? byteArray;

  /// Path to the image asset.
  final String? assetPath;

  /// URL of the image to be loaded from the network.
  final String? networkUrl;

  /// File object representing the image file.
  final File? file;

  @override
  State<ProImageEditor> createState() => ProImageEditorState();
}

/// State class for the ProImageEditor widget, handling configurations
/// and user interactions for image editing.
class ProImageEditorState extends State<ProImageEditor>
    with
        ImageEditorConvertedConfigs,
        SimpleConfigsAccessState,
        SimpleCallbacksAccessState,
        MainEditorGlobalKeys {
  final _mouseCursorsKey = GlobalKey<ExtendedMouseRegionState>();
  final _bottomBarKey = GlobalKey();
  final _removeAreaKey = GlobalKey();
  final _backgroundImageColorFilterKey = GlobalKey<ColorFilterGeneratorState>();
  final _interactiveViewer = GlobalKey<ExtendedInteractiveViewerState>();
  late final StreamController<void> _rebuildController;

  /// Helper class for managing sizes and layout calculations.
  late final SizesManager sizesManager;

  /// Manager class for handling desktop interactions in the image editor.
  late final DesktopInteractionManager _desktopInteractionManager;

  /// Manager class to copy layers.
  final LayerCopyManager _layerCopyManager = LayerCopyManager();

  /// Helper class for managing interactions with layers in the editor.
  final LayerInteractionManager layerInteractionManager =
      LayerInteractionManager();

  /// Manager class for managing the state of the editor.
  final StateManager stateManager = StateManager();

  late final _stateHistoryService = MainEditorStateHistoryService(
    sizesManager: sizesManager,
    stateManager: stateManager,
    controllers: _controllers,
    configs: configs,
    mainEditorCallbacks: mainEditorCallbacks,
    takeScreenshot: _takeScreenshot,
  );

  /// Controller instances for managing various aspects of the main editor.
  late final MainEditorControllers _controllers;

  /// The current theme used by the image editor.
  late ThemeData _theme;

  /// Temporary layer used during editing.
  Layer? _tempLayer;

  /// Index of the selected layer.
  int selectedLayerIndex = -1;

  /// Flag indicating if the editor has been initialized.
  bool _isInitialized = false;

  /// Flag indicating if the image needs decoding.
  bool _isImageNotDecoded = true;

  /// Flag to track if editing is completed.
  bool _isProcessingFinalImage = false;

  /// The pixel ratio of the device's screen.
  ImageInfos? _imageInfos;

  /// Indicates whether a sub-editor is currently open.
  bool isSubEditorOpen = false;

  /// Indicates whether a sub-editor is in the process of closing.
  bool isSubEditorClosing = false;

  /// Whether a dialog is currently open.
  bool _isDialogOpen = false;

  /// Whether a context menu is currently open.
  bool _isContextMenuOpen = false;

  /// Indicates whether the `onScaleUpdate` function can be triggered to
  /// interact with the layers.
  bool blockOnScaleUpdateFunction = false;

  /// Indicates whether the browser's context menu was enabled before any
  /// changes.
  bool _browserContextMenuBeforeEnabled = false;

  /// Indicates whether PopScope is disabled.
  bool isPopScopeDisabled = false;

  /// Getter for the active layer currently being edited.
  Layer? get _activeLayer =>
      activeLayers.length > selectedLayerIndex && selectedLayerIndex >= 0
          ? activeLayers[selectedLayerIndex]
          : null;

  /// Get the list of layers from the current image editor changes.
  List<Layer> get activeLayers => stateManager.activeLayers;

  /// List to store the history of image editor changes.
  List<EditorStateHistory> get stateHistory => stateManager.stateHistory;

  /// Determines whether undo actions can be performed on the current state.
  bool get canUndo => stateManager.canUndo;

  /// Determines whether redo actions can be performed on the current state.
  bool get canRedo => stateManager.canRedo;

  /// Get the current background image.
  late EditorImage editorImage;

  /// A [Completer] used to track the completion of a page open operation.
  ///
  /// The completer is initialized and can be used to await the page open
  /// operation.
  Completer<bool> _pageOpenCompleter = Completer();

  /// A [Completer] used to track the completion of an image decoding operation.
  ///
  /// The completer is initialized and can be used to await the image
  /// decoding operation.
  final Completer<bool> _decodeImageCompleter = Completer();

  @override
  void initState() {
    super.initState();
    _rebuildController = StreamController.broadcast();
    _controllers = MainEditorControllers(configs, callbacks);
    _desktopInteractionManager = DesktopInteractionManager(
      configs: configs,
      context: context,
      onUpdateUI: mainEditorCallbacks?.handleUpdateUI,
      setState: setState,
    );
    sizesManager = SizesManager(configs: configs, context: context);
    layerInteractionManager.scaleDebounce =
        Debounce(const Duration(milliseconds: 100));

    editorImage = EditorImage(
      assetPath: widget.assetPath,
      byteArray: widget.byteArray,
      file: widget.file,
      networkUrl: widget.networkUrl,
    );

    /// For the case the user add transformConfigs we initialize the editor with
    /// this configurations and not the empty history
    if (mainEditorConfigs.transformSetup != null) {
      _initializeWithTransformations();
    } else {
      stateManager.addHistory(
        EditorStateHistory(
          transformConfigs: TransformConfigs.empty(),
          blur: 0,
          layers: [],
          filters: [],
          tuneAdjustments: [],
        ),
      );
    }

    if (helperLines.hitVibration) {
      Vibration.hasVibrator().then((hasVibrator) {
        layerInteractionManager.deviceCanVibrate = hasVibrator;

        if (layerInteractionManager.deviceCanVibrate) {
          Vibration.hasCustomVibrationsSupport()
              .then((hasCustomVibrationsSupport) {
            layerInteractionManager.deviceCanCustomVibrate =
                hasCustomVibrationsSupport;
          });
        }
      });
    }

    ServicesBinding.instance.keyboard.addHandler(_onKeyEvent);
    if (kIsWeb) {
      _browserContextMenuBeforeEnabled = BrowserContextMenu.enabled;
      BrowserContextMenu.disableContextMenu();
    }
    mainEditorCallbacks?.onInit?.call();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      mainEditorCallbacks?.onAfterViewInit?.call();
      _calcAppBarHeight();
    });
  }

  @override
  void dispose() {
    _rebuildController.close();
    _controllers.dispose();
    layerInteractionManager.scaleDebounce.dispose();
    SystemChrome.setSystemUIOverlayStyle(_theme.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark);
    SystemChrome.restoreSystemUIOverlays();
    ServicesBinding.instance.keyboard.removeHandler(_onKeyEvent);
    if (kIsWeb && _browserContextMenuBeforeEnabled) {
      BrowserContextMenu.enableContextMenu();
    }
    super.dispose();
  }

  @override
  void setState(void Function() fn) {
    _rebuildController.add(null);
    super.setState(fn);
  }

  void _checkInteractiveViewer() {
    _interactiveViewer.currentState?.setEnableInteraction(
      selectedLayerIndex < 0 && layerInteractionManager.selectedLayerId.isEmpty,
    );
  }

  /// Handle keyboard events
  bool _onKeyEvent(KeyEvent event) {
    return _desktopInteractionManager.onKey(
      event,
      activeLayer: _activeLayer,
      onEscape: () {
        if (!_isDialogOpen && !_isContextMenuOpen) {
          if (isSubEditorOpen) {
            if (!mainEditorConfigs.style.subEditorPage.barrierDismissible) {
              if (cropRotateEditor.currentState != null) {
                // Important to close the crop-editor like that cuz we need to
                // set the fake hero first
                cropRotateEditor.currentState!.close();
              } else {
                Navigator.pop(context);
              }
            }
          } else {
            closeEditor();
          }
        }
      },
      onUndoRedo: (undo) {
        if (_isDialogOpen || isSubEditorOpen) return;

        undo ? undoAction() : redoAction();
      },
    );
  }

  /// Adds a new state to the history with the given configuration and updates
  /// the state manager.
  ///
  /// This method is responsible for capturing the current state of the editor,
  /// including layers, transformations, filters, and blur settings. It then
  /// adds this state to the history, enabling undo and redo functionality.
  /// Additionally, it can take a screenshot if required.
  ///
  /// - [layers]: An optional list of layers to be included in the new state.
  /// - [newLayer]: An optional new layer to be added to the current layers.
  /// - [transformConfigs]: Optional transformation configurations for the new
  /// state.
  /// - [filters]: An optional list of filter states to be included in the new
  /// state.
  /// - [tuneAdjustments]: An optional list of tune adjustments states to be
  /// included in the new state.
  /// - [blur]: An optional blur state to be included in the new state.
  /// - [heroScreenshotRequired]: A flag indicating whether a hero screenshot
  /// is required.
  ///
  /// Example usage:
  /// ```dart
  /// addHistory(
  ///   layers: currentLayers,
  ///   newLayer: additionalLayer,
  ///   transformConfigs: currentTransformConfigs,
  ///   filters: currentFilters,
  ///   tuneAdjustments: currentTuneAdjustments
  ///   blur: currentBlurState,
  ///   heroScreenshotRequired: false,
  /// );
  /// ```
  void addHistory({
    List<Layer>? layers,
    Layer? newLayer,
    TransformConfigs? transformConfigs,
    FilterMatrix? filters,
    List<TuneAdjustmentMatrix>? tuneAdjustments,
    double? blur,
    bool heroScreenshotRequired = false,
    bool blockCaptureScreenshot = false,
  }) {
    List<Layer> activeLayerList = _layerCopyManager.copyLayerList(activeLayers);

    stateManager.addHistory(
      EditorStateHistory(
        transformConfigs: transformConfigs,
        blur: blur,
        layers: layers ??
            (newLayer != null
                ? [...activeLayerList, newLayer]
                : activeLayerList),
        filters: filters ?? [],
        tuneAdjustments: tuneAdjustments ?? [],
      ),
      historyLimit: configs.stateHistory.stateHistoryLimit,
    );
    if (!blockCaptureScreenshot) {
      if (!heroScreenshotRequired) {
        _takeScreenshot();
      } else {
        stateManager.heroScreenshotRequired = true;
      }
    } else {
      _controllers.screenshot
          .addEmptyScreenshot(screenshots: stateManager.screenshots);
    }
  }

  /// Replaces a layer at the specified index with a new layer.
  ///
  /// This method updates the current layer at the given [index] in the list of
  /// active layers with the specified [layer]. It also resets the
  /// `selectedLayerId` in the `layerInteractionManager` to an empty string,
  /// effectively deselecting any currently selected layer. Additionally, it
  /// adds the updated list of layers to the history, enabling undo/redo
  /// functionality, and triggers a UI update by sending a null event to the
  /// UI layer controller.
  ///
  /// This is useful when you need to modify an existing layer while maintaining
  /// the rest of the layer order and history tracking.
  ///
  /// Parameters:
  /// - [index]: The index of the layer to be replaced. Must be within the
  ///   bounds of the current list of active layers.
  /// - [layer]: The new `Layer` instance that will replace the existing layer
  ///   at the specified index.
  ///
  /// Example usage:
  /// ```dart
  /// replaceLayer(index: 2, layer: newLayer);
  /// ```
  void replaceLayer({
    required int index,
    required Layer layer,
  }) {
    layerInteractionManager.selectedLayerId = '';
    addHistory(
      layers: [...activeLayers]
        ..removeAt(index)
        ..insert(index, layer),
    );

    _controllers.uiLayerCtrl.add(null);
  }

  /// Add a new layer to the image editor.
  ///
  /// This method adds a new layer to the image editor and updates the editing
  /// state.
  void addLayer(
    Layer layer, {
    int removeLayerIndex = -1,
    bool blockSelectLayer = false,
    bool blockCaptureScreenshot = false,
  }) {
    layerInteractionManager.selectedLayerId = '';

    addHistory(newLayer: layer, blockCaptureScreenshot: blockCaptureScreenshot);

    if (removeLayerIndex >= 0) {
      activeLayers.removeAt(removeLayerIndex);
    }
    if (!blockSelectLayer &&
        layerInteractionManager.layersAreSelectable(configs) &&
        layerInteraction.initialSelected) {
      /// Skip one frame to ensure captured image in separate thread will not
      /// capture the border.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        layerInteractionManager.selectedLayerId = layer.id;
        _controllers.uiLayerCtrl.add(null);
        _checkInteractiveViewer();
      });
    }
    mainEditorCallbacks?.handleAddLayer(layer);
    setState(() {});
  }

  /// Remove a layer from the editor.
  ///
  /// This method removes a layer from the editor and updates the editing state.
  void removeLayer(Layer? layer) {
    int layerPos = activeLayers
        .indexWhere((element) => element.id == (layer?.id ?? _tempLayer!.id));
    if (layerPos >= 0) {
      stateManager.activeLayers[layerPos] =
          _layerCopyManager.copyLayer(_tempLayer ?? layer!);

      mainEditorCallbacks
          ?.handleRemoveLayer(stateManager.activeLayers[layerPos]);

      var layers = _layerCopyManager.copyLayerList(activeLayers)
        ..removeAt(layerPos);
      addHistory(layers: layers);
      setState(() {});
    }
  }

  /// Remove all layers from the editor.
  ///
  /// This method removes all layers from the editor and updates the editing
  /// state.
  void removeAllLayers() {
    addHistory(layers: []);
    setState(() {});
  }

  /// Update the temporary layer in the editor.
  ///
  /// This method updates the temporary layer in the editor and updates the
  /// editing state.
  void _updateTempLayer() {
    addHistory();
    layerInteractionManager.selectedLayerId = '';
    _checkInteractiveViewer();
    _controllers.uiLayerCtrl.add(null);

    /* 
    String selectedLayerId = _layerInteractionManager.selectedLayerId;
    _layerInteractionManager.selectedLayerId = '';
    setState(() {});
    takeScreenshot();
    if (selectedLayerId.isNotEmpty) {
      /// Skip one frame to ensure captured image in separate thread will not 
      /// capture the border.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _layerInteractionManager.selectedLayerId = selectedLayerId;
        setState(() {});
      });
    } */

    List<Layer> oldLayers =
        stateHistory[stateManager.historyPointer - 1].layers;
    int oldIndex =
        oldLayers.indexWhere((element) => element.id == _tempLayer!.id);
    if (oldIndex >= 0) {
      oldLayers[oldIndex] = _layerCopyManager.copyLayer(_tempLayer!);
    }
    _tempLayer = null;
  }

  void _initializeWithTransformations() {
    var transformSetup = mainEditorConfigs.transformSetup!;

    /// Add the initial history
    stateManager.addHistory(
      EditorStateHistory(
        transformConfigs: transformSetup.transformConfigs,
        blur: 0,
        layers: [],
        filters: [],
        tuneAdjustments: [],
      ),
    );

    /// Set the decoded image infos for the case they are not empty
    if (transformSetup.imageInfos != null) {
      _imageInfos = transformSetup.imageInfos!;
      decodeImage(
        transformSetup.transformConfigs,
        transformSetup.imageInfos,
      );
    }
  }

  /// Decode the image being edited.
  ///
  /// This method decodes the image if it hasn't been decoded yet and updates
  /// its properties.
  Future<void> decodeImage([
    TransformConfigs? transformConfigs,
    ImageInfos? imageInfos,
  ]) async {
    bool shouldImportStateHistory =
        _isImageNotDecoded && stateHistoryConfigs.initStateHistory != null;
    _isImageNotDecoded = false;

    if (shouldImportStateHistory && i18n.importStateHistoryMsg.isNotEmpty) {
      LoadingDialog.instance.show(
        context,
        theme: _theme,
        configs: configs,
        message: i18n.importStateHistoryMsg,
      );
    }
    _imageInfos = imageInfos ??
        await decodeImageInfos(
          bytes: await editorImage.safeByteArray(context),
          screenSize: Size(
            sizesManager.lastScreenSize.width,
            sizesManager.bodySize.height,
          ),
          configs: transformConfigs ?? stateManager.transformConfigs,
        );
    sizesManager.originalImageSize ??= _imageInfos!.rawSize;
    sizesManager.decodedImageSize = _imageInfos!.renderedSize;

    _isInitialized = true;
    if (!_decodeImageCompleter.isCompleted) {
      _decodeImageCompleter.complete(true);
    }

    if (shouldImportStateHistory) {
      await importStateHistory(stateHistoryConfigs.initStateHistory!);
      if (i18n.importStateHistoryMsg.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          LoadingDialog.instance.hide();
        });
      }
    }
    if (mounted) setState(() {});
    mainEditorCallbacks?.handleUpdateUI();
  }

  /// Set the temporary layer to a copy of the provided layer.
  void _setTempLayer(Layer layer) {
    _tempLayer = _layerCopyManager.copyLayer(layer);
  }

  void _calcAppBarHeight() {
    double? renderedBottomBarHeight =
        _bottomBarKey.currentContext?.size?.height;
    if (renderedBottomBarHeight != null) {
      sizesManager
        ..bottomBarHeight = renderedBottomBarHeight
        ..appBarHeight = sizesManager.editorSize.height -
            sizesManager.bodySize.height -
            sizesManager.bottomBarHeight;
    }
  }

  /// Replace the background image with a new image and ensures all relevant
  /// states are rebuilt to reflect the new background. This includes marking
  /// all background screenshots as "broken" to trigger re-capture with the
  /// new image, and rebuilding the current editor state to apply the changes.
  ///
  /// The method performs the following steps:
  /// 1. Updates the editor's background image.
  /// 2. Decodes the new image to prepare it for rendering.
  /// 3. Marks all screenshots as "broken" so they are recaptured with the
  /// updated background.
  /// 4. Rebuilds the current editor state to ensure the new background is
  /// applied.
  Future<void> updateBackgroundImage(EditorImage image) async {
    editorImage = image;
    await decodeImage();

    /// Mark all background captured images with the old background image as
    /// "broken" that the editor capture them with the new image again
    for (var item in stateManager.screenshots) {
      item.broken = true;
    }

    /// Force to rebuild everything
    int pos = stateManager.historyPointer;
    EditorStateHistory oldHistory = stateManager.stateHistory[pos];

    stateManager.stateHistory[pos] = EditorStateHistory(
      layers: oldHistory.layers,
      transformConfigs: oldHistory.transformConfigs,
      blur: oldHistory.blur,
      filters: [...oldHistory.filters],
      tuneAdjustments: [...oldHistory.tuneAdjustments],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _backgroundImageColorFilterKey.currentState?.refresh();
      }
    });
  }

  /// Resets the zoom and pan of the image editor.
  void resetZoom() {
    _interactiveViewer.currentState?.reset();
    _controllers.cropLayerPainterCtrl.add(null);
  }

  /// Handle the start of a scaling operation.
  ///
  /// This method is called when a scaling operation begins and initializes the
  /// necessary variables.
  void _onScaleStart(ScaleStartDetails details) {
    if (sizesManager.bodySize != sizesManager.editorSize) {
      _calcAppBarHeight();
    }

    layerInteractionManager
      ..snapStartPosX = details.focalPoint.dx
      ..snapStartPosY = details.focalPoint.dy;

    if (selectedLayerIndex < 0) return;

    var layer = activeLayers[selectedLayerIndex];

    if (layerInteractionManager.selectedLayerId != layer.id) {
      layerInteractionManager.selectedLayerId = '';
      _checkInteractiveViewer();
    }

    _setTempLayer(layer);
    layerInteractionManager
      ..baseScaleFactor = layer.scale
      ..baseAngleFactor = layer.rotation
      ..snapStartRotation = layer.rotation * 180 / pi
      ..snapLastRotation = layerInteractionManager.snapStartRotation
      ..reset();

    double posX = layer.offset.dx;
    double posY = layer.offset.dy;

    layerInteractionManager
      ..lastPositionY = posY <= -layerInteractionManager.hitSpan
          ? LayerLastPosition.top
          : posY >= layerInteractionManager.hitSpan
              ? LayerLastPosition.bottom
              : LayerLastPosition.center
      ..lastPositionX = posX <= -layerInteractionManager.hitSpan
          ? LayerLastPosition.left
          : posX >= layerInteractionManager.hitSpan
              ? LayerLastPosition.right
              : LayerLastPosition.center;
    setState(() {});
    mainEditorCallbacks?.handleScaleStart(details);
  }

  /// Handle updates during scaling.
  ///
  /// This method is called during a scaling operation and updates the selected
  /// layer's position and properties.
  void _onScaleUpdate(ScaleUpdateDetails details) {
    mainEditorCallbacks?.handleScaleUpdate(details);
    if (selectedLayerIndex < 0 || blockOnScaleUpdateFunction) return;

    bool beforeShowHorizontalHelperLine =
        layerInteractionManager.showHorizontalHelperLine;
    bool beforeShowVerticalHelperLine =
        layerInteractionManager.showVerticalHelperLine;
    bool beforeShowRotationHelperLine =
        layerInteractionManager.showRotationHelperLine;

    void checkUpdateHelperLineUI() {
      if (beforeShowHorizontalHelperLine !=
              layerInteractionManager.showHorizontalHelperLine ||
          beforeShowVerticalHelperLine !=
              layerInteractionManager.showVerticalHelperLine ||
          beforeShowRotationHelperLine !=
              layerInteractionManager.showRotationHelperLine) {
        _controllers.helperLineCtrl.add(null);
      }
    }

    if (_activeLayer == null) return;

    if (layerInteractionManager.rotateScaleLayerSizeHelper != null) {
      layerInteractionManager
        ..freeStyleHighPerformanceScaling =
            paintEditorConfigs.freeStyleHighPerformanceScaling ?? !isDesktop
        ..calculateInteractiveButtonScaleRotate(
          configs: configs,
          activeLayer: _activeLayer!,
          configEnabledHitVibration: helperLines.hitVibration,
          details: details,
          editorSize: sizesManager.bodySize,
          layerTheme: layerInteraction.style,
          editorScaleFactor:
              _interactiveViewer.currentState?.scaleFactor ?? 1.0,
          editorScaleOffset:
              _interactiveViewer.currentState?.offset ?? Offset.zero,
        );
      _activeLayer!.key.currentState!.setState(() {});
      checkUpdateHelperLineUI();
      return;
    }

    double editorScaleFactor =
        _interactiveViewer.currentState?.scaleFactor ?? 1.0;

    layerInteractionManager.enabledHitDetection = false;
    if (details.pointerCount == 1) {
      layerInteractionManager
        ..freeStyleHighPerformanceMoving =
            paintEditorConfigs.freeStyleHighPerformanceMoving ?? isWebMobile
        ..calculateMovement(
          editorScaleFactor: editorScaleFactor,
          removeAreaKey: _removeAreaKey,
          activeLayer: _activeLayer!,
          context: context,
          detail: details,
          configEnabledHitVibration: helperLines.hitVibration,
          onHoveredRemoveChanged: _controllers.removeBtnCtrl.add,
        );
    } else if (details.pointerCount == 2) {
      layerInteractionManager
        ..freeStyleHighPerformanceScaling =
            paintEditorConfigs.freeStyleHighPerformanceScaling ?? !isDesktop
        ..calculateScaleRotate(
          editorScaleFactor: editorScaleFactor,
          configs: configs,
          activeLayer: _activeLayer!,
          detail: details,
          editorSize: sizesManager.bodySize,
          screenPaddingHelper: sizesManager.imageMargin,
          configEnabledHitVibration: helperLines.hitVibration,
        );
    }
    mainEditorCallbacks?.handleUpdateLayer(_activeLayer!);
    _activeLayer?.key.currentState?.setState(() {});
    checkUpdateHelperLineUI();
  }

  /// Handle the end of a scaling operation.
  ///
  /// This method is called when a scaling operation ends and resets helper
  /// lines and flags.
  void _onScaleEnd(ScaleEndDetails details) async {
    mainEditorCallbacks?.handleScaleEnd(details);

    if (!layerInteractionManager.hoverRemoveBtn && _tempLayer != null) {
      _updateTempLayer();
    }

    layerInteractionManager.onScaleEnd();
    setState(() {});
  }

  /// Handles tap events on a text layer.
  ///
  /// This method opens a text editor for the specified text layer and updates
  /// the layer's properties
  /// based on the user's input.
  ///
  /// [layerData] - The text layer data to be edited.
  void _onTextLayerTap(TextLayer layerData) async {
    TextLayer? layer = await openPage(
      TextEditor(
        key: textEditor,
        layer: layerData,
        heroTag: layerData.id,
        configs: configs,
        theme: _theme,
        callbacks: callbacks,
      ),

      /// Small Duration is important for a smooth hero animation
      duration: const Duration(milliseconds: 250),
    );

    if (layer == null || !mounted) return;

    int i = activeLayers.indexWhere((element) => element.id == layerData.id);
    if (i >= 0) {
      _setTempLayer(layerData);
      (activeLayers[i] as TextLayer)
        ..text = layer.text
        ..background = layer.background
        ..color = layer.color
        ..colorMode = layer.colorMode
        ..colorPickerPosition = layer.colorPickerPosition
        ..align = layer.align
        ..fontScale = layer.fontScale
        ..textStyle = layer.textStyle
        ..id = layerData.id
        ..flipX = layerData.flipX
        ..flipY = layerData.flipY
        ..offset = layerData.offset
        ..scale = layerData.scale
        ..customSecondaryColor = layer.customSecondaryColor
        ..rotation = layerData.rotation;

      _updateTempLayer();
    }

    setState(() {});
    mainEditorCallbacks?.handleUpdateUI();
  }

  /// Initializes the key event listener by adding a handler to the keyboard
  /// service.
  void initKeyEventListener() {
    ServicesBinding.instance.keyboard.addHandler(_onKeyEvent);
  }

  /// Removes the key event listener by removing the handler from the keyboard
  /// service.
  void removeKeyEventListener() {
    ServicesBinding.instance.keyboard.removeHandler(_onKeyEvent);
  }

  void _selectLayerAfterHeroIsDone(String id) {
    if (layerInteractionManager.layersAreSelectable(configs) &&
        layerInteraction.initialSelected) {
      /// Skip one frame to ensure captured image in separate thread will not
      /// capture the border.
      Future.delayed(const Duration(milliseconds: 1), () async {
        if (isSubEditorOpen) await _pageOpenCompleter.future;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          layerInteractionManager.selectedLayerId = id;
          _checkInteractiveViewer();
          setState(() {});
        });
      });
    }
  }

  /// Open a new page on top of the current page.
  ///
  /// This method navigates to a new page using a fade transition animation.
  Future<T?> openPage<T>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    layerInteractionManager.selectedLayerId = '';
    _checkInteractiveViewer();
    isSubEditorOpen = true;

    if (paintEditorConfigs.freeStyleHighPerformanceHero) {
      layerInteractionManager.freeStyleHighPerformanceHero = true;
    }

    setState(() {});

    SubEditor editorName = SubEditor.unknown;

    if (T is PaintEditor) {
      editorName = SubEditor.paint;
    } else if (T is TextEditor) {
      editorName = SubEditor.text;
    } else if (T is CropRotateEditor) {
      editorName = SubEditor.cropRotate;
    } else if (T is FilterEditor) {
      editorName = SubEditor.filter;
    } else if (T is BlurEditor) {
      editorName = SubEditor.blur;
    } else if (T is EmojiEditor) {
      editorName = SubEditor.emoji;
    }

    mainEditorCallbacks?.handleOpenSubEditor(editorName);
    _pageOpenCompleter = Completer();
    return Navigator.push<T?>(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: mainEditorConfigs.style.subEditorPage.barrierColor,
        barrierDismissible:
            mainEditorConfigs.style.subEditorPage.barrierDismissible,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder:
            mainEditorConfigs.style.subEditorPage.transitionsBuilder ??
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
        pageBuilder: (context, animation, secondaryAnimation) {
          void animationStatusListener(AnimationStatus status) {
            switch (status) {
              case AnimationStatus.completed:
                if (cropRotateEditor.currentState != null) {
                  cropRotateEditor.currentState!.hideFakeHero();
                }
                break;
              case AnimationStatus.dismissed:
                setState(() {
                  isSubEditorOpen = false;
                  isSubEditorClosing = false;
                  if (!_pageOpenCompleter.isCompleted) {
                    _pageOpenCompleter.complete(true);
                  }
                  layerInteractionManager.freeStyleHighPerformanceHero = false;

                  if (stateManager.heroScreenshotRequired) {
                    stateManager.heroScreenshotRequired = false;
                    _takeScreenshot();
                  }
                });

                animation.removeStatusListener(animationStatusListener);
                mainEditorCallbacks?.handleEndCloseSubEditor(editorName);
                break;
              case AnimationStatus.reverse:
                isSubEditorClosing = true;
                mainEditorCallbacks?.handleStartCloseSubEditor(editorName);

                break;
              case AnimationStatus.forward:
                break;
            }
          }

          animation.addStatusListener(animationStatusListener);
          if (mainEditorConfigs.style.subEditorPage.requireReposition) {
            return SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: mainEditorConfigs.style.subEditorPage.positionTop,
                    left: mainEditorConfigs.style.subEditorPage.positionLeft,
                    right: mainEditorConfigs.style.subEditorPage.positionRight,
                    bottom:
                        mainEditorConfigs.style.subEditorPage.positionBottom,
                    child: Center(
                      child: Container(
                        width: mainEditorConfigs
                                .style.subEditorPage.enforceSizeFromMainEditor
                            ? sizesManager.editorSize.width
                            : null,
                        height: mainEditorConfigs
                                .style.subEditorPage.enforceSizeFromMainEditor
                            ? sizesManager.editorSize.height
                            : null,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: mainEditorConfigs
                              .style.subEditorPage.borderRadius,
                        ),
                        child: page,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return page;
          }
        },
      ),
    );
  }

  /// Opens the paint editor.
  ///
  /// This method opens the paint editor and allows the user to draw on the
  /// current image.
  /// After closing the paint editor, any changes made are applied to the
  /// image's layers.
  void openPaintEditor() async {
    List<PaintLayer>? paintItemLayers = await openPage<List<PaintLayer>>(
      PaintEditor.autoSource(
        key: paintEditor,
        editorImage: editorImage,
        initConfigs: PaintEditorInitConfigs(
          configs: configs,
          callbacks: callbacks,
          layers: activeLayers,
          theme: _theme,
          mainImageSize: sizesManager.decodedImageSize,
          mainBodySize: sizesManager.bodySize,
          transformConfigs: stateManager.transformConfigs,
          appliedBlurFactor: stateManager.activeBlur,
          appliedFilters: stateManager.activeFilters,
          appliedTuneAdjustments: stateManager.activeTuneAdjustments,
        ),
      ),
      duration: const Duration(milliseconds: 150),
    );
    if (paintItemLayers != null && paintItemLayers.isNotEmpty) {
      for (var i = 0; i < paintItemLayers.length; i++) {
        addLayer(
          paintItemLayers[i],
          blockSelectLayer: true,
          blockCaptureScreenshot: i != paintItemLayers.length - 1,
        );
      }

      _selectLayerAfterHeroIsDone(paintItemLayers.last.id);

      setState(() {});
      mainEditorCallbacks?.handleUpdateUI();
    }
  }

  /// Opens the text editor.
  ///
  /// This method opens the text editor, allowing the user to add or edit text
  /// layers on the image.
  void openTextEditor({
    /// Small Duration is important for a smooth hero animation
    Duration duration = const Duration(milliseconds: 150),
  }) async {
    TextLayer? layer = await openPage(
      TextEditor(
        key: textEditor,
        configs: configs,
        theme: _theme,
        callbacks: callbacks,
      ),
      duration: duration,
    );

    if (layer == null || !mounted) return;

    addLayer(layer, blockSelectLayer: true);
    _selectLayerAfterHeroIsDone(layer.id);

    setState(() {});
    mainEditorCallbacks?.handleUpdateUI();
  }

  /// Opens the crop rotate editor.
  ///
  /// This method opens the crop editor, allowing the user to crop and rotate
  /// the image.
  void openCropRotateEditor() async {
    if (!_isInitialized) await _decodeImageCompleter.future;

    await openPage<TransformConfigs?>(
      CropRotateEditor.autoSource(
        key: cropRotateEditor,
        editorImage: editorImage,
        initConfigs: CropRotateEditorInitConfigs(
          configs: configs,
          callbacks: callbacks,
          theme: _theme,
          layers: stateManager.activeLayers,
          transformConfigs: stateManager.transformConfigs,
          mainImageSize: sizesManager.decodedImageSize,
          mainBodySize: sizesManager.bodySize,
          enableFakeHero: true,
          appliedBlurFactor: stateManager.activeBlur,
          appliedFilters: stateManager.activeFilters,
          appliedTuneAdjustments: stateManager.activeTuneAdjustments,
          onDone: (transformConfigs, fitToScreenFactor, imageInfos) async {
            List<Layer> updatedLayers = LayerTransformGenerator(
              layers: stateManager.activeLayers,
              activeTransformConfigs: stateManager.transformConfigs,
              newTransformConfigs: transformConfigs,
              layerDrawAreaSize: sizesManager.bodySize,
              undoChanges: false,
              fitToScreenFactor: fitToScreenFactor,
            ).updatedLayers;

            _imageInfos = null;
            unawaited(decodeImage(transformConfigs));
            addHistory(
              transformConfigs: transformConfigs,
              layers: updatedLayers,
              heroScreenshotRequired: true,
            );

            /// Important to reset the layer hero positions
            if (activeLayers.isNotEmpty) {
              _controllers.layerHeroResetCtrl.add(true);
              await Future.delayed(const Duration(milliseconds: 60));
              _controllers.layerHeroResetCtrl.add(false);
            }

            setState(() {});
          },
        ),
      ),
    ).then((transformConfigs) async {
      if (transformConfigs != null) {
        setState(() {});
        mainEditorCallbacks?.handleUpdateUI();
      }
    });
  }

  /// Opens the tune editor.
  ///
  /// This method opens the Tune Editor page, allowing the user to make tune
  /// adjustments (such as brightness, contrast, etc.) to the current image.
  ///
  /// If tune adjustments are made, they are added to the editor's history
  /// and the UI is updated accordingly. If the operation is canceled or no
  /// adjustments are made, the current state remains unchanged.
  void openTuneEditor({
    bool enableHero = true,
  }) async {
    if (!mounted) return;
    List<TuneAdjustmentMatrix>? tuneAdjustments = await openPage(
      HeroMode(
        enabled: enableHero,
        child: TuneEditor.autoSource(
          key: tuneEditor,
          editorImage: editorImage,
          initConfigs: TuneEditorInitConfigs(
            theme: _theme,
            configs: configs,
            callbacks: callbacks,
            transformConfigs: stateManager.transformConfigs,
            layers: activeLayers,
            mainImageSize: sizesManager.decodedImageSize,
            mainBodySize: sizesManager.bodySize,
            convertToUint8List: false,
            appliedBlurFactor: stateManager.activeBlur,
            appliedFilters: stateManager.activeFilters,
            appliedTuneAdjustments: stateManager.activeTuneAdjustments,
          ),
        ),
      ),
    );

    if (tuneAdjustments == null) return;

    addHistory(
      tuneAdjustments: tuneAdjustments,
      heroScreenshotRequired: true,
    );

    setState(() {});
    mainEditorCallbacks?.handleUpdateUI();
  }

  /// Opens the filter editor.
  ///
  /// This method allows the user to apply filters to the current image and
  /// replaces the image
  /// with the filtered version if a filter is applied.
  ///
  /// The filter editor is opened as a page, and the resulting filtered image
  /// is received as a
  /// `Uint8List`. If no filter is applied or the operation is canceled, the
  /// original image is retained.
  void openFilterEditor() async {
    if (!mounted) return;
    FilterMatrix? filters = await openPage(
      FilterEditor.autoSource(
        key: filterEditor,
        editorImage: editorImage,
        initConfigs: FilterEditorInitConfigs(
          theme: _theme,
          configs: configs,
          callbacks: callbacks,
          transformConfigs: stateManager.transformConfigs,
          layers: activeLayers,
          mainImageSize: sizesManager.decodedImageSize,
          mainBodySize: sizesManager.bodySize,
          convertToUint8List: false,
          appliedBlurFactor: stateManager.activeBlur,
          appliedFilters: stateManager.activeFilters,
          appliedTuneAdjustments: stateManager.activeTuneAdjustments,
        ),
      ),
    );

    if (filters == null) return;

    addHistory(
      filters: filters,
      heroScreenshotRequired: true,
    );

    setState(() {});
    mainEditorCallbacks?.handleUpdateUI();
  }

  /// Opens the blur editor as a modal bottom sheet.
  void openBlurEditor() async {
    if (!mounted) return;
    double? blur = await openPage(
      BlurEditor.autoSource(
        key: blurEditor,
        editorImage: editorImage,
        initConfigs: BlurEditorInitConfigs(
          theme: _theme,
          mainImageSize: sizesManager.decodedImageSize,
          mainBodySize: sizesManager.bodySize,
          layers: activeLayers,
          configs: configs,
          callbacks: callbacks,
          transformConfigs: stateManager.transformConfigs,
          convertToUint8List: false,
          appliedBlurFactor: stateManager.activeBlur,
          appliedFilters: stateManager.activeFilters,
          appliedTuneAdjustments: stateManager.activeTuneAdjustments,
        ),
      ),
    );

    if (blur == null) return;

    addHistory(
      blur: blur,
      heroScreenshotRequired: true,
    );

    setState(() {});
    mainEditorCallbacks?.handleUpdateUI();
  }

  /// Opens the emoji editor.
  ///
  /// This method opens the emoji editor as a modal bottom sheet, allowing the
  /// user to add emoji
  /// layers to the current image. The selected emoji layer's properties, such
  /// as scale and offset,
  /// are adjusted before adding it to the image's layers.
  ///
  /// Keyboard event handlers are temporarily removed while the emoji editor is
  /// active and restored
  /// after its closure.
  void openEmojiEditor() async {
    setState(() => layerInteractionManager.selectedLayerId = '');
    _checkInteractiveViewer();
    ServicesBinding.instance.keyboard.removeHandler(_onKeyEvent);
    final effectiveBoxConstraints = emojiEditorConfigs
        .style.editorBoxConstraintsBuilder
        ?.call(context, configs);

    DraggableSheetStyle sheetTheme =
        emojiEditorConfigs.style.themeDraggableSheet;
    bool useDraggableSheet = sheetTheme.maxChildSize != sheetTheme.minChildSize;
    EmojiLayer? layer = await showModalBottomSheet(
        context: context,
        backgroundColor: emojiEditorConfigs.style.backgroundColor,
        constraints: effectiveBoxConstraints,
        showDragHandle: emojiEditorConfigs.style.showDragHandle,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (BuildContext context) {
          if (!useDraggableSheet) {
            return ConstrainedBox(
              constraints: effectiveBoxConstraints ??
                  BoxConstraints(
                      maxHeight:
                          300 + MediaQuery.of(context).viewInsets.bottom),
              child: EmojiEditor(configs: configs),
            );
          }

          return DraggableScrollableSheet(
              expand: sheetTheme.expand,
              initialChildSize: sheetTheme.initialChildSize,
              maxChildSize: sheetTheme.maxChildSize,
              minChildSize: sheetTheme.minChildSize,
              shouldCloseOnMinExtent: sheetTheme.shouldCloseOnMinExtent,
              snap: sheetTheme.snap,
              snapAnimationDuration: sheetTheme.snapAnimationDuration,
              snapSizes: sheetTheme.snapSizes,
              builder: (_, controller) {
                return EmojiEditor(
                  configs: configs,
                  scrollController: controller,
                );
              });
        });
    ServicesBinding.instance.keyboard.addHandler(_onKeyEvent);
    if (layer == null || !mounted) return;
    layer.scale = emojiEditorConfigs.initScale;

    addLayer(layer);

    setState(() {});
    mainEditorCallbacks?.handleUpdateUI();
  }

  /// Opens the sticker editor as a modal bottom sheet.
  void openStickerEditor() async {
    setState(() => layerInteractionManager.selectedLayerId = '');
    _checkInteractiveViewer();
    ServicesBinding.instance.keyboard.removeHandler(_onKeyEvent);
    final effectiveBoxConstraints = stickerEditorConfigs
        .style.editorBoxConstraintsBuilder
        ?.call(context, configs);
    var sheetTheme = stickerEditorConfigs.style.draggableSheetStyle;
    WidgetLayer? layer = await showModalBottomSheet(
        context: context,
        backgroundColor: stickerEditorConfigs.style.bottomSheetBackgroundColor,
        constraints: effectiveBoxConstraints,
        showDragHandle: stickerEditorConfigs.style.showDragHandle,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) {
          return DraggableScrollableSheet(
            expand: sheetTheme.expand,
            initialChildSize: sheetTheme.initialChildSize,
            maxChildSize: sheetTheme.maxChildSize,
            minChildSize: sheetTheme.minChildSize,
            shouldCloseOnMinExtent: sheetTheme.shouldCloseOnMinExtent,
            snap: sheetTheme.snap,
            snapAnimationDuration: sheetTheme.snapAnimationDuration,
            snapSizes: sheetTheme.snapSizes,
            builder: (_, controller) {
              return StickerEditor(
                configs: configs,
                scrollController: controller,
              );
            },
          );
        });
    ServicesBinding.instance.keyboard.addHandler(_onKeyEvent);
    if (layer == null || !mounted) return;

    addLayer(layer);

    setState(() {});
    mainEditorCallbacks?.handleUpdateUI();
  }

  /// Moves a layer in the list to a new position.
  ///
  /// - `oldIndex` is the current index of the layer.
  /// - `newIndex` is the desired index to move the layer to.
  void moveLayerListPosition({
    required int oldIndex,
    required int newIndex,
  }) {
    List<Layer> layers = _layerCopyManager.copyLayerList(activeLayers);
    if (newIndex > oldIndex) {
      var item = layers.removeAt(oldIndex);
      layers.insert(newIndex - 1, item);
    } else {
      var item = layers.removeAt(oldIndex);
      layers.insert(newIndex, item);
    }
    addHistory(layers: layers);
    setState(() {});
  }

  /// Undo the last editing action.
  ///
  /// This function allows the user to undo the most recent editing action
  /// performed on the image.
  /// It decreases the edit position, and the image is decoded to reflect
  /// the previous state.
  void undoAction() {
    if (stateManager.canUndo) {
      setState(() {
        layerInteractionManager.selectedLayerId = '';
        _checkInteractiveViewer();
        stateManager.undo();
        decodeImage();
      });
      mainEditorCallbacks?.handleUndo();
    }
  }

  /// Redo the previously undone editing action.
  ///
  /// This function allows the user to redo an editing action that was
  /// previously undone using the
  /// `undoAction` function. It increases the edit position, and the image is
  /// decoded to reflect
  /// the next state.
  void redoAction() {
    if (stateManager.canRedo) {
      setState(() {
        layerInteractionManager.selectedLayerId = '';
        _checkInteractiveViewer();
        stateManager.redo();
        decodeImage();
      });
      mainEditorCallbacks?.handleRedo();
    }
  }

  /// Takes a screenshot of the current editor state.
  ///
  /// This method is intended to be used for capturing the current state of the
  /// editor and saving it as an image.
  ///
  /// - If a subeditor is currently open, the method waits until it is fully
  ///   loaded.
  /// - The screenshot is taken in a post-frame callback to ensure the UI is
  ///   fully rendered.
  void _takeScreenshot() async {
    // Wait for the editor to be fully open, if it is currently opening
    if (isSubEditorOpen) await _pageOpenCompleter.future;

    // Capture the screenshot in a post-frame callback to ensure the UI is fully
    // rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_imageInfos == null && mounted) await decodeImage();

      if (!mounted) return;

      await _controllers.screenshot.capture(
        imageInfos: _imageInfos!,
        screenshots: stateManager.screenshots,
      );
    });
  }

  /// Complete the editing process and return the edited image.
  ///
  /// This function is called when the user is done editing the image. If no
  /// changes have been made or if the image has no additional layers, it
  /// cancels the editing process and closes the editor. Otherwise, it captures
  /// the current state of the image, including any applied changes or layers,
  /// and returns it as a byte array.
  ///
  /// Before returning the edited image, a loading dialog is displayed to
  /// indicate that the operation is in progress.
  void doneEditing() async {
    if (_isProcessingFinalImage) return;
    if (!stateManager.canUndo && activeLayers.isEmpty) {
      if (!imageGenerationConfigs.allowEmptyEditCompletion) {
        return closeEditor();
      }
    }
    callbacks.onImageEditingStarted?.call();

    /// Hide every unnecessary element that Screenshot Controller will capture
    /// a correct image.
    setState(() {
      _isProcessingFinalImage = true;
      layerInteractionManager.selectedLayerId = '';
      _checkInteractiveViewer();
    });

    /// Ensure hero animations finished
    if (isSubEditorOpen) await _pageOpenCompleter.future;

    /// For the case the user add initial transformConfigs but there are no
    /// changes we need to ensure the editor will generate the image.
    if (mainEditorConfigs.transformSetup != null && !stateManager.canUndo) {
      addHistory();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      LoadingDialog.instance.show(
        context,
        theme: _theme,
        configs: configs,
        message: i18n.doneLoadingMsg,
      );

      if (callbacks.onThumbnailGenerated != null) {
        if (_imageInfos == null) await decodeImage();

        final results = await Future.wait([
          captureEditorImage(),
          _controllers.screenshot.getRawRenderedImage(
              imageInfos: _imageInfos!, useThumbnailSize: false),
        ]);

        await callbacks.onThumbnailGenerated!(
          results[0] as Uint8List,
          results[1] as ui.Image,
        );
      } else {
        Uint8List? bytes = await captureEditorImage();
        await onImageEditingComplete?.call(bytes);
      }

      LoadingDialog.instance.hide();

      onCloseEditor?.call();

      /// Allow users to continue editing if they didn't close the editor.
      setState(() => _isProcessingFinalImage = false);
    });
  }

  /// Captures the final editor image.
  ///
  /// This method generates the final image of the editor content, taking
  /// into account the pixel ratio for high-resolution images. If
  /// `generateOnlyImageBounds` is set in `imageGenerationConfigs`, it uses the
  /// base pixel ratio; otherwise, it uses the maximum of the base pixel ratio
  /// and the device's pixel ratio.
  ///
  /// Returns a [Uint8List] representing the final image.
  ///
  /// Returns an empty [Uint8List] if the screenshot capture fails.
  Future<Uint8List> captureEditorImage() async {
    if (isSubEditorOpen) {
      Navigator.pop(context);
      if (!_pageOpenCompleter.isCompleted) await _pageOpenCompleter.future;
      if (!mounted) return Uint8List.fromList([]);
    }

    if (_imageInfos == null) await decodeImage();

    if (!mounted) return Uint8List.fromList([]);

    bool hasChanges = stateManager.canUndo;
    bool useOriginalImage =
        !hasChanges && imageGenerationConfigs.enableUseOriginalBytes;
    if (!hasChanges && !imageGenerationConfigs.enableUseOriginalBytes) {
      addHistory();
    }

    return await _controllers.screenshot.captureFinalScreenshot(
          imageInfos: _imageInfos!,
          backgroundScreenshot:
              useOriginalImage ? null : stateManager.activeScreenshot,
          originalImageBytes: useOriginalImage
              ? await editorImage.safeByteArray(context)
              : null,
        ) ??
        Uint8List.fromList([]);
  }

  /// Close the image editor.
  ///
  /// This function allows the user to close the image editor without saving
  /// any changes or edits.
  /// It navigates back to the previous screen or closes the modal editor.
  void closeEditor() {
    if (!stateManager.canUndo) {
      if (onCloseEditor == null) {
        Navigator.pop(context);
      } else {
        onCloseEditor!.call();
      }
    } else {
      closeWarning();
    }
  }

  /// Displays a warning dialog before closing the image editor.
  void closeWarning() async {
    if (isPopScopeDisabled) {
      Navigator.pop(context);
      return;
    }
    _isDialogOpen = true;

    bool close = false;

    if (!mounted) return;

    if (mainEditorConfigs.widgets.closeWarningDialog != null) {
      close = await mainEditorConfigs.widgets.closeWarningDialog!(this);
    } else {
      await showAdaptiveDialog(
        context: context,
        builder: (BuildContext context) => Theme(
          data: _theme,
          child: AdaptiveDialog(
            designMode: designMode,
            brightness: _theme.brightness,
            style: configs.dialogConfigs.style.adaptiveDialog,
            title: Text(i18n.various.closeEditorWarningTitle),
            content: Text(i18n.various.closeEditorWarningMessage),
            actions: <AdaptiveDialogAction>[
              AdaptiveDialogAction(
                designMode: designMode,
                onPressed: () => Navigator.pop(context, 'Cancel'),
                child: Text(i18n.various.closeEditorWarningCancelBtn),
              ),
              AdaptiveDialogAction(
                designMode: designMode,
                onPressed: () {
                  close = true;
                  Navigator.pop(context, 'OK');
                },
                child: Text(i18n.various.closeEditorWarningConfirmBtn),
              ),
            ],
          ),
        ),
      );
    }

    if (close) {
      if (onCloseEditor == null) {
        if (mounted) Navigator.pop(context);
      } else {
        onCloseEditor!.call();
      }
    }

    _isDialogOpen = false;
  }

  /// Imports state history and performs necessary recalculations.
  ///
  /// If [ImportStateHistory.configs.recalculateSizeAndPosition] is `true`, it
  /// recalculates the position and size of layers.
  /// It adjusts the scale and offset of each layer based on the image size and
  /// the editor's dimensions.
  ///
  /// If [ImportStateHistory.configs.mergeMode] is
  /// [ImportEditorMergeMode.replace], it replaces the current state history
  /// with the imported one.
  /// Otherwise, it merges the imported state history with the current one
  /// based on the merge mode.
  ///
  /// After importing, it updates the UI by calling [setState()] and the
  /// optional [onUpdateUI] callback.
  Future<void> importStateHistory(ImportStateHistory import) async {
    await _stateHistoryService.importStateHistory(import, context);
  }

  /// Exports the current state history.
  ///
  /// `configs` specifies the export configurations, such as whether to include
  /// filters or layers.
  ///
  /// Returns an [ExportStateHistory] object containing the exported state
  /// history, image state history, image size, edit position, and export
  /// configurations.
  Future<ExportStateHistory> exportStateHistory({
    ExportEditorConfigs configs = const ExportEditorConfigs(),
  }) async {
    if (_imageInfos == null) await decodeImage();
    if (_imageInfos == null) throw ArgumentError('Failed to decode the image');
    if (!mounted) throw ArgumentError('Context unmounted');

    return await _stateHistoryService.exportStateHistory(
      imageInfos: _imageInfos!,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    _theme = configs.theme ??
        ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue.shade800,
            brightness: Brightness.dark,
          ),
        );

    return RecordInvisibleWidget(
      controller: _controllers.screenshot,
      child: ExtendedPopScope(
        canPop: isPopScopeDisabled ||
            !stateManager.canUndo ||
            _isProcessingFinalImage,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop &&
              !isPopScopeDisabled &&
              stateManager.canUndo &&
              !_isProcessingFinalImage) {
            closeWarning();
          }
          mainEditorCallbacks?.onPopInvoked?.call(didPop, result);
        },
        child: ScreenResizeDetector(
          ignoreSafeArea: false,
          onResizeUpdate: (event) {
            sizesManager
              ..recalculateLayerPosition(
                history: stateManager.stateHistory,
                resizeEvent: ResizeEvent(
                  oldContentSize: Size(
                    event.oldContentSize.width,
                    event.oldContentSize.height - sizesManager.allToolbarHeight,
                  ),
                  newContentSize: Size(
                    event.newContentSize.width,
                    event.newContentSize.height - sizesManager.allToolbarHeight,
                  ),
                ),
              )
              ..lastScreenSize = event.newContentSize;
          },
          onResizeEnd: (event) async {
            await decodeImage();
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: mainEditorConfigs.style.uiOverlayStyle,
            child: Theme(
              data: _theme,
              child: SafeArea(
                child: LayoutBuilder(builder: (context, constraints) {
                  sizesManager.editorSize = constraints.biggest;
                  return Scaffold(
                    backgroundColor: mainEditorConfigs.style.background,
                    resizeToAvoidBottomInset: false,
                    appBar: _buildAppBar(),
                    body: _buildBody(),
                    bottomNavigationBar: _buildBottomNavBar(),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (mainEditorConfigs.widgets.appBar != null) {
      return mainEditorConfigs.widgets.appBar!
          .call(this, _rebuildController.stream);
    }

    return selectedLayerIndex >= 0 &&
            configs.layerInteraction.hideToolbarOnInteraction
        ? null
        : MainEditorAppBar(
            i18n: i18n,
            configs: configs,
            closeEditor: closeEditor,
            undoAction: undoAction,
            redoAction: redoAction,
            doneEditing: doneEditing,
            isInitialized: _isInitialized,
            stateManager: stateManager,
          );
  }

  Widget _buildBody() {
    return LayoutBuilder(builder: (context, constraints) {
      sizesManager.bodySize = constraints.biggest;
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerSignal: isDesktop && _activeLayer != null
            ? (event) {
                if (_activeLayer == null) return;
                _desktopInteractionManager.mouseScroll(
                  event,
                  activeLayer: _activeLayer!,
                  selectedLayerIndex: selectedLayerIndex,
                );
              }
            : null,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (layerInteractionManager.selectedLayerId.isNotEmpty) {
              layerInteractionManager.selectedLayerId = '';
              _checkInteractiveViewer();
              setState(() {});
            }
            mainEditorCallbacks?.onTap?.call();
          },
          onDoubleTap: mainEditorCallbacks?.onDoubleTap,
          onLongPress: mainEditorCallbacks?.onLongPress,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: mainEditorConfigs.widgets.wrapBody?.call(
                this,
                _rebuildController.stream,
                _buildInteractiveContent(),
              ) ??
              _buildInteractiveContent(),
        ),
      );
    });
  }

  Widget _buildInteractiveContent() {
    return MainEditorInteractiveContent(
      buildImage: _buildImage,
      buildLayers: _buildLayers,
      buildHelperLines: _buildHelperLines,
      buildRemoveIcon: _buildRemoveIcon,
      callbacks: callbacks,
      sizesManager: sizesManager,
      configs: configs,
      layerInteractionManager: layerInteractionManager,
      controllers: _controllers,
      selectedLayerIndex: selectedLayerIndex,
      processFinalImage: _isProcessingFinalImage,
      rebuildController: _rebuildController,
      stateManager: stateManager,
      interactiveViewerKey: _interactiveViewer,
      state: this,
    );
  }

  Widget? _buildBottomNavBar() {
    if (mainEditorConfigs.widgets.bottomBar != null) {
      return mainEditorConfigs.widgets.bottomBar!
          .call(this, _rebuildController.stream, _bottomBarKey);
    }

    return selectedLayerIndex >= 0 &&
            configs.layerInteraction.hideToolbarOnInteraction
        ? null
        : MainEditorBottombar(
            controllers: _controllers,
            configs: configs,
            sizesManager: sizesManager,
            bottomBarKey: _bottomBarKey,
            theme: _theme,
            openPaintEditor: openPaintEditor,
            openTextEditor: openTextEditor,
            openCropRotateEditor: openCropRotateEditor,
            openTuneEditor: openTuneEditor,
            openFilterEditor: openFilterEditor,
            openBlurEditor: openBlurEditor,
            openEmojiEditor: openEmojiEditor,
            openStickerEditor: openStickerEditor,
          );
  }

  Widget _buildLayers() {
    return MainEditorLayers(
      controllers: _controllers,
      layerInteraction: layerInteraction,
      layerInteractionManager: layerInteractionManager,
      configs: configs,
      callbacks: callbacks,
      sizesManager: sizesManager,
      mouseCursorsKey: _mouseCursorsKey,
      selectedLayerIndex: selectedLayerIndex,
      activeLayers: activeLayers,
      isSubEditorOpen: isSubEditorOpen,
      checkInteractiveViewer: _checkInteractiveViewer,
      onTextLayerTap: _onTextLayerTap,
      state: this,
      setTempLayer: _setTempLayer,
      onContextMenuToggled: (isOpen) {
        _isContextMenuOpen = isOpen;
      },
    );
  }

  Widget _buildHelperLines() {
    return MainEditorHelperLines(
      sizesManager: sizesManager,
      layerInteractionManager: layerInteractionManager,
      controllers: _controllers,
      interactiveViewer: _interactiveViewer,
      helperLines: helperLines,
      configs: configs,
    );
  }

  Widget _buildRemoveIcon() {
    return MainEditorRemoveLayerArea(
      layerInteraction: layerInteraction,
      layerInteractionManager: layerInteractionManager,
      mainEditorConfigs: mainEditorConfigs,
      state: this,
      controllers: _controllers,
      removeAreaKey: _removeAreaKey,
    );
  }

  Widget _buildImage() {
    return MainEditorBackgroundImage(
      backgroundImageColorFilterKey: _backgroundImageColorFilterKey,
      configs: configs,
      editorImage: editorImage,
      isInitialized: _isInitialized,
      sizesManager: sizesManager,
      stateManager: stateManager,
    );
  }
}
