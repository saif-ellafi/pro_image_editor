// Dart imports:
import 'dart:async';
import 'dart:io';
import 'dart:math';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_image_editor/features/paint_editor/widgets/paint_editor_appbar.dart';
import 'package:pro_image_editor/features/paint_editor/widgets/paint_editor_bottombar.dart';
import 'package:pro_image_editor/features/paint_editor/widgets/paint_editor_color_picker.dart';

import '/core/constants/image_constants.dart';
import '/core/mixins/converted_callbacks.dart';
import '/core/mixins/converted_configs.dart';
import '/core/mixins/standalone_editor.dart';
import '/core/models/transform_helper.dart';
import '/pro_image_editor.dart';
import '/shared/services/content_recorder/widgets/content_recorder.dart';
import '/shared/styles/platform_text_styles.dart';
import '/shared/widgets/auto_image.dart';
import '/shared/widgets/bottom_sheets_header_row.dart';
import '/shared/widgets/extended/extended_interactive_viewer.dart';
import '/shared/widgets/layer/layer_stack.dart';
import '/shared/widgets/platform/platform_popup_menu.dart';
import '/shared/widgets/transform/transformed_content_generator.dart';
import '../filter_editor/widgets/filtered_image.dart';
import 'controllers/paint_controller.dart';
import 'models/painted_model.dart';
import 'services/paint_desktop_interaction_manager.dart';
import 'widgets/paint_canvas.dart';

export 'enums/paint_editor_enum.dart';
export 'models/paint_bottom_bar_item.dart';
export 'widgets/draw_paint_item.dart';

/// The `PaintEditor` widget allows users to editing images with paint
/// tools.
///
/// You can create a `PaintEditor` using one of the factory methods provided:
/// - `PaintEditor.file`: Loads an image from a file.
/// - `PaintEditor.asset`: Loads an image from an asset.
/// - `PaintEditor.network`: Loads an image from a network URL.
/// - `PaintEditor.memory`: Loads an image from memory as a `Uint8List`.
/// - `PaintEditor.autoSource`: Automatically selects the source based on
/// provided parameters.
class PaintEditor extends StatefulWidget
    with StandaloneEditor<PaintEditorInitConfigs> {
  /// Constructs a `PaintEditor` widget.
  ///
  /// The [key] parameter is used to provide a key for the widget.
  /// The [editorImage] parameter specifies the image to be edited.
  /// The [initConfigs] parameter specifies the initialization configurations
  /// for the editor.
  const PaintEditor._({
    super.key,
    required this.editorImage,
    required this.initConfigs,
    this.paintOnly = false,
  });

  /// Constructs a `PaintEditor` widget with image data loaded from memory.
  factory PaintEditor.memory(
    Uint8List byteArray, {
    Key? key,
    required PaintEditorInitConfigs initConfigs,
  }) {
    return PaintEditor._(
      key: key,
      editorImage: EditorImage(byteArray: byteArray),
      initConfigs: initConfigs,
    );
  }

  /// Constructs a `PaintEditor` widget with an image loaded from a file.
  factory PaintEditor.file(
    File file, {
    Key? key,
    required PaintEditorInitConfigs initConfigs,
  }) {
    return PaintEditor._(
      key: key,
      editorImage: EditorImage(file: file),
      initConfigs: initConfigs,
    );
  }

  /// Constructs a `PaintEditor` widget with an image loaded from an asset.
  factory PaintEditor.asset(
    String assetPath, {
    Key? key,
    required PaintEditorInitConfigs initConfigs,
  }) {
    return PaintEditor._(
      key: key,
      editorImage: EditorImage(assetPath: assetPath),
      initConfigs: initConfigs,
    );
  }

  /// Constructs a `PaintEditor` widget with an image loaded from a network
  /// URL.
  factory PaintEditor.network(
    String networkUrl, {
    Key? key,
    required PaintEditorInitConfigs initConfigs,
  }) {
    return PaintEditor._(
      key: key,
      editorImage: EditorImage(networkUrl: networkUrl),
      initConfigs: initConfigs,
    );
  }

  /// Constructs a `PaintEditor` widget optimized for drawing purposes.
  factory PaintEditor.drawing({
    Key? key,
    required PaintEditorInitConfigs initConfigs,
  }) {
    return PaintEditor._(
      key: key,
      editorImage: EditorImage(byteArray: kImageEditorTransparentBytes),
      initConfigs: initConfigs,
      paintOnly: true,
    );
  }

  /// Constructs a `PaintEditor` widget with an image loaded automatically
  /// based on the provided source.
  ///
  /// Either [byteArray], [file], [networkUrl], or [assetPath] must be provided.
  factory PaintEditor.autoSource({
    Key? key,
    Uint8List? byteArray,
    File? file,
    String? assetPath,
    String? networkUrl,
    EditorImage? editorImage,
    required PaintEditorInitConfigs initConfigs,
  }) {
    if (byteArray != null || editorImage?.byteArray != null) {
      return PaintEditor.memory(
        byteArray ?? editorImage!.byteArray!,
        key: key,
        initConfigs: initConfigs,
      );
    } else if (file != null || editorImage?.file != null) {
      return PaintEditor.file(
        file ?? editorImage!.file!,
        key: key,
        initConfigs: initConfigs,
      );
    } else if (networkUrl != null || editorImage?.networkUrl != null) {
      return PaintEditor.network(
        networkUrl ?? editorImage!.networkUrl!,
        key: key,
        initConfigs: initConfigs,
      );
    } else if (assetPath != null || editorImage?.assetPath != null) {
      return PaintEditor.asset(
        assetPath ?? editorImage!.assetPath!,
        key: key,
        initConfigs: initConfigs,
      );
    } else {
      throw ArgumentError(
          "Either 'byteArray', 'file', 'networkUrl' or 'assetPath' "
          'must be provided.');
    }
  }
  @override
  final PaintEditorInitConfigs initConfigs;
  @override
  final EditorImage editorImage;

  /// A flag indicating whether only paint operations are allowed.
  final bool paintOnly;

  @override
  State<PaintEditor> createState() => PaintEditorState();
}

/// State class for managing the paint editor, handling user interactions
/// and paint operations.
class PaintEditorState extends State<PaintEditor>
    with
        ImageEditorConvertedConfigs,
        ImageEditorConvertedCallbacks,
        StandaloneEditorState<PaintEditor, PaintEditorInitConfigs> {
  final _paintCanvas = GlobalKey<PaintCanvasState>();
  final _interactiveViewer = GlobalKey<ExtendedInteractiveViewerState>();

  /// Controller for managing paint operations within the widget's context.
  late final PaintController paintCtrl;

  /// Update the color picker.
  late final StreamController<void> uiPickerStream;

  /// Update the appbar icons.
  late final StreamController<void> _uiAppbarStream;

  /// A ScrollController for controlling the scrolling behavior of the bottom
  /// navigation bar.
  late ScrollController _bottomBarScrollCtrl;

  /// A boolean flag representing whether the fill mode is enabled or disabled.
  bool _isFillMode = false;

  /// Controls high-performance for free-style drawing.
  bool _freeStyleHighPerformance = false;

  /// Get the fillBackground status.
  bool get fillBackground => _isFillMode;

  /// Determines whether undo actions can be performed on the current state.
  bool get canUndo => paintCtrl.canUndo;

  /// Determines whether redo actions can be performed on the current state.
  bool get canRedo => paintCtrl.canRedo;

  /// Determines whether the user draw something.
  bool get isActive => paintCtrl.busy;

  /// Manager class for handling desktop interactions.
  late final PaintDesktopInteractionManager _desktopInteractionManager;

  /// Get the current PaintMode.
  PaintMode get paintMode => paintCtrl.mode;

  /// Get the current strokeWidth.
  double get strokeWidth => paintCtrl.strokeWidth;

  /// Get the active selected color.
  Color get activeColor => paintCtrl.color;

  /// A list of [PaintModeBottomBarItem] representing the available drawing
  /// modes in the paint editor.
  /// The list is dynamically generated based on the configuration settings in
  /// the [PaintEditorConfigs] object.
  List<PaintModeBottomBarItem> get paintModes => [
        if (paintEditorConfigs.hasOptionFreeStyle)
          PaintModeBottomBarItem(
            mode: PaintMode.freeStyle,
            icon: paintEditorConfigs.icons.freeStyle,
            label: i18n.paintEditor.freestyle,
          ),
        if (paintEditorConfigs.hasOptionArrow)
          PaintModeBottomBarItem(
            mode: PaintMode.arrow,
            icon: paintEditorConfigs.icons.arrow,
            label: i18n.paintEditor.arrow,
          ),
        if (paintEditorConfigs.hasOptionLine)
          PaintModeBottomBarItem(
            mode: PaintMode.line,
            icon: paintEditorConfigs.icons.line,
            label: i18n.paintEditor.line,
          ),
        if (paintEditorConfigs.hasOptionRect)
          PaintModeBottomBarItem(
            mode: PaintMode.rect,
            icon: paintEditorConfigs.icons.rectangle,
            label: i18n.paintEditor.rectangle,
          ),
        if (paintEditorConfigs.hasOptionCircle)
          PaintModeBottomBarItem(
            mode: PaintMode.circle,
            icon: paintEditorConfigs.icons.circle,
            label: i18n.paintEditor.circle,
          ),
        if (paintEditorConfigs.hasOptionDashLine)
          PaintModeBottomBarItem(
            mode: PaintMode.dashLine,
            icon: paintEditorConfigs.icons.dashLine,
            label: i18n.paintEditor.dashLine,
          ),
        if (paintEditorConfigs.hasOptionEraser)
          PaintModeBottomBarItem(
            mode: PaintMode.eraser,
            icon: paintEditorConfigs.icons.eraser,
            label: i18n.paintEditor.eraser,
          ),
      ];

  /// The Uint8List from the fake hero image, which is drawn when finish
  /// editing.
  Uint8List? _fakeHeroBytes;

  /// Indicates whether the editor supports zoom functionality.
  bool get _enableZoom => paintEditorConfigs.enableZoom;

  @override
  void initState() {
    super.initState();
    paintCtrl = PaintController(
      fill: paintEditorConfigs.initialFill,
      mode: paintEditorConfigs.initialPaintMode,
      strokeWidth: paintEditorConfigs.style.initialStrokeWidth,
      color: paintEditorConfigs.style.initialColor,
      opacity: paintEditorConfigs.style.initialOpacity,
      strokeMultiplier: 1,
    );

    _isFillMode = paintEditorConfigs.initialFill;

    initStreamControllers();

    _bottomBarScrollCtrl = ScrollController();
    _desktopInteractionManager =
        PaintDesktopInteractionManager(context: context);
    ServicesBinding.instance.keyboard.addHandler(_onKeyEvent);

    /// Important to set state after view init to set action icons
    paintEditorCallbacks?.onInit?.call();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      paintEditorCallbacks?.onAfterViewInit?.call();
      setState(() {});
      paintEditorCallbacks?.handleUpdateUI();
    });
  }

  @override
  void dispose() {
    paintCtrl.dispose();
    _bottomBarScrollCtrl.dispose();
    uiPickerStream.close();
    _uiAppbarStream.close();
    screenshotCtrl.destroy();
    ServicesBinding.instance.keyboard.removeHandler(_onKeyEvent);
    super.dispose();
  }

  @override
  void setState(void Function() fn) {
    rebuildController.add(null);
    super.setState(fn);
  }

  /// Initializes stream controllers for managing UI updates.
  void initStreamControllers() {
    uiPickerStream = StreamController.broadcast();
    _uiAppbarStream = StreamController.broadcast();

    uiPickerStream.stream.listen((_) => rebuildController.add(null));
    _uiAppbarStream.stream.listen((_) => rebuildController.add(null));
  }

  /// Handle keyboard events
  bool _onKeyEvent(KeyEvent event) {
    return _desktopInteractionManager.onKey(
      event,
      onUndoRedo: (undo) {
        if (undo) {
          undoAction();
        } else {
          redoAction();
        }
      },
    );
  }

  /// Opens a bottom sheet to adjust the line weight when drawing.
  void openLineWeightBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: paintEditorConfigs.style.lineWidthBottomSheetBackground,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return Material(
            color: Colors.transparent,
            textStyle: platformTextStyle(context, designMode),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BottomSheetHeaderRow(
                      title: i18n.paintEditor.lineWidth,
                      theme: initConfigs.theme,
                      textStyle:
                          paintEditorConfigs.style.lineWidthBottomSheetTitle,
                      closeButton:
                          paintEditorConfigs.widgets.lineWidthCloseButton !=
                                  null
                              ? (fn) => paintEditorConfigs
                                  .widgets.lineWidthCloseButton!(this, fn)
                              : null,
                    ),
                    StatefulBuilder(builder: (context, setState) {
                      if (paintEditorConfigs.widgets.sliderLineWidth != null) {
                        return paintEditorConfigs.widgets.sliderLineWidth!(
                          this,
                          rebuildController.stream,
                          paintCtrl.strokeWidth,
                          (value) {
                            setStrokeWidth(value);
                            setState(() {});
                          },
                          (onChangedEnd) {},
                        );
                      }

                      return Slider.adaptive(
                        max: 40,
                        min: 2,
                        divisions: 19,
                        value: paintCtrl.strokeWidth,
                        onChanged: (value) {
                          setStrokeWidth(value);
                          setState(() {});
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// Opens a bottom sheet to adjust the opacity when drawing.
  void openOpacityBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: paintEditorConfigs.style.opacityBottomSheetBackground,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return Material(
            color: Colors.transparent,
            textStyle: platformTextStyle(context, designMode),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BottomSheetHeaderRow(
                      title: i18n.paintEditor.changeOpacity,
                      theme: initConfigs.theme,
                      textStyle:
                          paintEditorConfigs.style.opacityBottomSheetTitle,
                      closeButton:
                          paintEditorConfigs.widgets.changeOpacityCloseButton !=
                                  null
                              ? (fn) => paintEditorConfigs
                                  .widgets.changeOpacityCloseButton!(this, fn)
                              : null,
                    ),
                    StatefulBuilder(builder: (context, setState) {
                      if (paintEditorConfigs.widgets.sliderChangeOpacity !=
                          null) {
                        return paintEditorConfigs.widgets.sliderChangeOpacity!(
                          this,
                          rebuildController.stream,
                          paintCtrl.opacity,
                          (value) {
                            setOpacity(value);
                            setState(() {});
                          },
                          (onChangedEnd) {},
                        );
                      }

                      return Slider.adaptive(
                        max: 1,
                        min: 0,
                        divisions: 100,
                        value: paintCtrl.opacity,
                        onChanged: (value) {
                          setOpacity(value);
                          setState(() {});
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// Sets the fill mode for drawing elements.
  /// When the `fill` parameter is `true`, drawing elements will be filled;
  /// otherwise, they will be outlined.
  void setFill(bool fill) {
    paintCtrl.setFill(fill);
    _uiAppbarStream.add(null);
    paintEditorCallbacks?.handleToggleFill(fill);
  }

  /// Sets the opacity for drawing elements.
  ///
  /// The opacity must be between 0 and 1.
  void setOpacity(double value) {
    paintCtrl.setOpacity(value);
    _uiAppbarStream.add(null);
    paintEditorCallbacks?.handleOpacity(value);
  }

  /// Toggles the fill mode.
  void toggleFill() {
    _isFillMode = !_isFillMode;
    setFill(_isFillMode);
    rebuildController.add(null);
  }

  /// Set the PaintMode for the current state and trigger an update if provided.
  void setMode(PaintMode mode) {
    paintCtrl.setMode(mode);
    paintEditorCallbacks?.handlePaintModeChanged(mode);
    rebuildController.add(null);
    _interactiveViewer.currentState?.setEnableInteraction(
      mode == PaintMode.moveAndZoom,
    );
    _paintCanvas.currentState?.setState(() {});
  }

  /// Undoes the last action performed in the paint editor.
  void undoAction() {
    if (canUndo) screenshotHistoryPosition--;
    paintCtrl.undo();
    _uiAppbarStream.add(null);
    setState(() {});
    paintEditorCallbacks?.handleUndo();
  }

  /// Redoes the previously undone action in the paint editor.
  void redoAction() {
    if (canRedo) screenshotHistoryPosition++;
    paintCtrl.redo();
    _uiAppbarStream.add(null);
    setState(() {});
    paintEditorCallbacks?.handleRedo();
  }

  /// Finishes editing in the paint editor and returns the painted items as
  /// a result.
  /// If no changes have been made, it closes the editor without returning any
  /// changes.
  void done() async {
    doneEditing(
        editorImage: widget.editorImage,
        onSetFakeHero: (bytes) {
          if (initConfigs.enableFakeHero) {
            setState(() {
              _fakeHeroBytes = bytes;
            });
          }
        },
        onCloseWithValue: () {
          if (!canUndo) return Navigator.pop(context);
          Navigator.of(context).pop(
            _exportPaintedItems(editorBodySize),
          );
        });
    paintEditorCallbacks?.handleDone();
  }

  /// Exports the painted items as a list of [PaintLayer].
  ///
  /// This method converts the paint history into a list of
  /// [PaintLayer] representing the painted items.
  ///
  /// Example:
  /// ```dart
  /// List<PaintLayer> layers = exportPaintedItems();
  /// ```
  List<PaintLayer> _exportPaintedItems(Size editorSize) {
    Rect findRenderedLayerRect(List<Offset?> points) {
      if (points.isEmpty) return Rect.zero;

      double leftmostX = double.infinity;
      double topmostY = double.infinity;
      double rightmostX = double.negativeInfinity;
      double bottommostY = double.negativeInfinity;

      for (final point in points) {
        if (point != null) {
          if (point.dx < leftmostX) {
            leftmostX = point.dx;
          }
          if (point.dy < topmostY) {
            topmostY = point.dy;
          }
          if (point.dx > rightmostX) {
            rightmostX = point.dx;
          }
          if (point.dy > bottommostY) {
            bottommostY = point.dy;
          }
        }
      }

      return Rect.fromPoints(
        Offset(leftmostX, topmostY),
        Offset(rightmostX, bottommostY),
      );
    }

    // Convert to free positions
    return paintCtrl.activePaintItemList.map((e) {
      PaintedModel layer = PaintedModel(
        mode: e.mode,
        offsets: [...e.offsets],
        color: e.color,
        strokeWidth: e.strokeWidth,
        fill: e.fill,
        opacity: e.opacity,
      );

      // Find extreme points of the paint layer
      Rect? layerRect = findRenderedLayerRect(e.offsets);

      Size size = layerRect.size;

      bool onlyStrokeMode = e.mode == PaintMode.freeStyle ||
          e.mode == PaintMode.line ||
          e.mode == PaintMode.dashLine ||
          e.mode == PaintMode.arrow ||
          ((e.mode == PaintMode.rect || e.mode == PaintMode.circle) && !e.fill);

      // Scale and offset the offsets of the paint layer
      double strokeHelperWidth = onlyStrokeMode ? e.strokeWidth : 0;

      for (int i = 0; i < layer.offsets.length; i++) {
        Offset? point = layer.offsets[i];
        if (point != null) {
          layer.offsets[i] = Offset(
            point.dx - layerRect.left + strokeHelperWidth / 2,
            point.dy - layerRect.top + strokeHelperWidth / 2,
          );
        }
      }

      // Calculate the final offset of the paint layer
      Offset finalOffset = Offset(
        layerRect.center.dx - editorSize.width / 2,
        layerRect.center.dy - editorSize.height / 2,
      );

      if (onlyStrokeMode) {
        size = Size(
          size.width + strokeHelperWidth,
          size.height + strokeHelperWidth,
        );
      }

      // Create and return a PaintLayer instance for the exported layer
      return PaintLayer(
        item: layer.copy(),
        rawSize: Size(
          max(size.width, layer.strokeWidth),
          max(size.height, layer.strokeWidth),
        ),
        opacity: layer.opacity,
        offset: finalOffset,
      );
    }).toList();
  }

  /// Set the stroke width.
  void setStrokeWidth(double value) {
    paintCtrl.setStrokeWidth(value);
    rebuildController.add(null);
    callbacks.paintEditorCallbacks?.handleLineWidthChanged(value);
    setState(() {});
  }

  /// Handles changes in the selected color.
  void colorChanged(Color color) {
    paintCtrl.setColor(color);
    uiPickerStream.add(null);
    paintEditorCallbacks?.handleColorChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: paintEditorConfigs.style.uiOverlayStyle,
      child: ExtendedPopScope(
        child: Theme(
          data: theme.copyWith(
              tooltipTheme: theme.tooltipTheme.copyWith(preferBelow: true)),
          child: SafeArea(
            top: paintEditorConfigs.safeArea.top,
            bottom: paintEditorConfigs.safeArea.bottom,
            left: paintEditorConfigs.safeArea.left,
            right: paintEditorConfigs.safeArea.right,
            child: RecordInvisibleWidget(
              controller: screenshotCtrl,
              child: LayoutBuilder(builder: (context, constraints) {
                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  backgroundColor: paintEditorConfigs.style.background,
                  appBar: _buildAppBar(constraints),
                  body: _buildBody(),
                  bottomNavigationBar: _buildBottomBar(),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the app bar for the paint editor.
  /// Returns a [PreferredSizeWidget] representing the app bar.
  PreferredSizeWidget? _buildAppBar(BoxConstraints constraints) {
    if (paintEditorConfigs.widgets.appBar != null) {
      return paintEditorConfigs.widgets.appBar!
          .call(this, rebuildController.stream);
    }

    return ReactiveAppbar(
      stream: _uiAppbarStream.stream,
      builder: (context) => PaintEditorAppBar(
        paintEditorConfigs: paintEditorConfigs,
        i18n: i18n.paintEditor,
        constraints: constraints,
        onUndo: undoAction,
        onRedo: redoAction,
        onToggleFill: toggleFill,
        onTapMenuFill: () {
          _isFillMode = !_isFillMode;
          setFill(_isFillMode);
          if (designMode == ImageEditorDesignMode.cupertino) {
            Navigator.pop(context);
          }
        },
        onDone: done,
        onClose: close,
        canRedo: canRedo,
        canUndo: canUndo,
        isFillMode: _isFillMode,
        onOpenOpacityBottomSheet: openOpacityBottomSheet,
        onOpenLineWeightBottomSheet: openLineWeightBottomSheet,
        designMode: designMode,
      ),
    );
  }

  /// Builds the main body of the paint editor.
  /// Returns a [Widget] representing the editor's body.
  Widget _buildBody() {
    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        editorBodySize = constraints.biggest;
        return Theme(
          data: theme,
          child: Material(
            color: initConfigs.convertToUint8List
                ? paintEditorConfigs.style.background
                : Colors.transparent,
            textStyle: platformTextStyle(context, designMode),
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: _fakeHeroBytes != null
                  ? [
                      Hero(
                        tag: configs.heroTag,
                        child: AutoImage(
                          EditorImage(byteArray: _fakeHeroBytes),
                          configs: configs,
                        ),
                      ),
                    ]
                  : [
                      ExtendedInteractiveViewer(
                        key: _interactiveViewer,
                        enableZoom: _enableZoom,
                        boundaryMargin: paintEditorConfigs.boundaryMargin,
                        minScale: paintEditorConfigs.editorMinScale,
                        maxScale: paintEditorConfigs.editorMaxScale,
                        enableInteraction: paintMode == PaintMode.moveAndZoom,
                        onInteractionStart: (details) {
                          _freeStyleHighPerformance = (paintEditorConfigs
                                      .freeStyleHighPerformanceMoving ??
                                  !isDesktop) ||
                              (paintEditorConfigs
                                      .freeStyleHighPerformanceScaling ??
                                  !isDesktop);

                          callbacks.paintEditorCallbacks?.onEditorZoomScaleStart
                              ?.call(details);
                          setState(() {});
                        },
                        onInteractionUpdate: callbacks
                            .paintEditorCallbacks?.onEditorZoomScaleUpdate,
                        onInteractionEnd: (details) {
                          _freeStyleHighPerformance = false;
                          callbacks.paintEditorCallbacks?.onEditorZoomScaleEnd
                              ?.call(details);
                          setState(() {});
                        },
                        child: ContentRecorder(
                          autoDestroyController: false,
                          controller: screenshotCtrl,
                          child: Stack(
                            alignment: Alignment.center,
                            fit: StackFit.expand,
                            children: [
                              if (!widget.paintOnly)
                                TransformedContentGenerator(
                                  configs: configs,
                                  transformConfigs: initialTransformConfigs ??
                                      TransformConfigs.empty(),
                                  child: FilteredImage(
                                    width: getMinimumSize(
                                            mainImageSize, editorBodySize)
                                        .width,
                                    height: getMinimumSize(
                                            mainImageSize, editorBodySize)
                                        .height,
                                    configs: configs,
                                    image: editorImage,
                                    filters: appliedFilters,
                                    tuneAdjustments: appliedTuneAdjustments,
                                    blurFactor: appliedBlurFactor,
                                  ),
                                )
                              else
                                SizedBox(
                                  width: configs
                                      .imageGeneration.maxOutputSize.width,
                                  height: configs
                                      .imageGeneration.maxOutputSize.height,
                                ),
                              if (layers != null)
                                LayerStack(
                                  configs: configs,
                                  layers: layers!,
                                  transformHelper: TransformHelper(
                                    mainBodySize: getMinimumSize(
                                        mainBodySize, editorBodySize),
                                    mainImageSize: getMinimumSize(
                                        mainImageSize, editorBodySize),
                                    editorBodySize: editorBodySize,
                                    transformConfigs: initialTransformConfigs,
                                  ),
                                ),
                              _buildPainter(),
                              if (paintEditorConfigs
                                      .widgets.bodyItemsRecorded !=
                                  null)
                                ...paintEditorConfigs
                                        .widgets.bodyItemsRecorded!(
                                    this, rebuildController.stream),
                            ],
                          ),
                        ),
                      ),
                      PaintEditorColorPicker(
                        state: this,
                        configs: configs,
                        rebuildController: rebuildController,
                      ),
                      if (paintEditorConfigs.widgets.bodyItems != null)
                        ...paintEditorConfigs.widgets.bodyItems!(
                            this, rebuildController.stream),
                    ],
            ),
          ),
        );
      }),
    );
  }

  /// Builds the bottom navigation bar of the paint editor.
  /// Returns a [Widget] representing the bottom navigation bar.
  Widget? _buildBottomBar() {
    if (paintEditorConfigs.widgets.bottomBar != null) {
      return paintEditorConfigs.widgets.bottomBar!
          .call(this, rebuildController.stream);
    }

    if (paintModes.length <= 1) return const SizedBox.shrink();

    return PaintEditorBottombar(
      configs: configs.paintEditor,
      paintMode: paintMode,
      i18n: i18n.paintEditor,
      theme: theme,
      enableZoom: _enableZoom,
      paintModes: paintModes,
      setMode: setMode,
      bottomBarScrollCtrl: _bottomBarScrollCtrl,
    );
  }

  /// Builds the paint canvas for the editor.
  /// Returns a [Widget] representing the paint canvas.
  Widget _buildPainter() {
    return PaintCanvas(
      key: _paintCanvas,
      paintCtrl: paintCtrl,
      drawAreaSize: mainBodySize ?? editorBodySize,
      freeStyleHighPerformance: _freeStyleHighPerformance,
      onRemoveLayer: (idList) {
        paintCtrl.removeLayers(idList);
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          takeScreenshot();
        });
      },
      onStart: () {
        rebuildController.add(null);
      },
      onCreated: () {
        _uiAppbarStream.add(null);
        uiPickerStream.add(null);
        paintEditorCallbacks?.handleDrawingDone();
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          takeScreenshot();
        });
      },
    );
  }
}
