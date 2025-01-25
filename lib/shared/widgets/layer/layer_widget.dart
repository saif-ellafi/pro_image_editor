// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '/core/mixins/converted_configs.dart';
import '/core/mixins/editor_configs_mixin.dart';
import '/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/layers/layer.dart';
import '/features/paint_editor/enums/paint_editor_enum.dart';
import '/features/paint_editor/widgets/draw_paint_item.dart';
import '/plugins/rounded_background_text/src/rounded_background_text.dart';
import '../../styles/platform_text_styles.dart';
import 'interaction_helper/layer_interaction_helper_widget.dart';

/// A widget representing a layer within a design canvas.
class LayerWidget extends StatefulWidget with SimpleConfigsAccess {
  /// Creates a [LayerWidget] with the specified properties.
  const LayerWidget({
    super.key,
    this.onScaleRotateDown,
    this.onScaleRotateUp,
    required this.editorCenterX,
    required this.editorCenterY,
    required this.configs,
    required this.layerData,
    this.onContextMenuToggled,
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onEditTap,
    this.onRemoveTap,
    this.highPerformanceMode = false,
    this.enableHitDetection = false,
    this.selected = false,
    this.isInteractive = false,
    this.callbacks = const ProImageEditorCallbacks(),
  });
  @override
  final ProImageEditorConfigs configs;

  @override
  final ProImageEditorCallbacks callbacks;

  /// The x-coordinate of the editor's center.
  ///
  /// This parameter specifies the horizontal center of the editor's body in
  /// logical pixels, used to position and transform layers relative to the
  /// editor's center.
  final double editorCenterX;

  /// The y-coordinate of the editor's center.
  ///
  /// This parameter specifies the vertical center of the editor's body in
  /// logical pixels,  used to position and transform layers relative to the
  /// editor's center.
  final double editorCenterY;

  /// Data for the layer.
  final Layer layerData;

  /// Callback when the context menu open/close
  final Function(bool isOpen)? onContextMenuToggled;

  /// Callback when a tap down event occurs.
  final Function()? onTapDown;

  /// Callback when a tap up event occurs.
  final Function()? onTapUp;

  /// Callback when a tap event occurs.
  final Function(Layer)? onTap;

  /// Callback for removing the layer.
  final Function()? onRemoveTap;

  /// Callback for editing the layer.
  final Function()? onEditTap;

  /// Callback for handling pointer down events associated with scale and rotate
  /// gestures.
  ///
  /// This callback is triggered when the user presses down on the widget to
  /// begin a scaling or rotating gesture. It provides both the pointer event
  /// and the size of the widget being interacted with, allowing for precise
  /// manipulation.
  ///
  /// - Parameters:
  ///   - event: The [PointerDownEvent] containing details about the pointer
  ///     interaction, such as position and device type.
  ///   - size: The [Size] of the widget being manipulated, useful for
  ///     calculating scaling and rotation transformations relative to the
  ///     widget's dimensions.
  final Function(PointerDownEvent, Size)? onScaleRotateDown;

  /// Callback for handling pointer up events associated with scale and rotate
  /// gestures.
  ///
  /// This callback is triggered when the user releases the widget after a
  /// scaling or rotating gesture. It allows for finalizing the interaction and
  /// making any necessary updates or state changes based on the completed
  /// gesture.
  ///
  /// - Parameter event: The [PointerUpEvent] containing details about the
  ///   pointer release, such as position and device type.
  final Function(PointerUpEvent)? onScaleRotateUp;

  /// Controls high-performance for free-style drawing.
  final bool highPerformanceMode;

  /// Enables or disables hit detection.
  /// When set to `true`, it allows detecting user interactions with the
  /// interface.
  final bool enableHitDetection;

  /// Indicates whether the layer is selected.
  final bool selected;

  /// Indicates whether the layer is interactive.
  final bool isInteractive;

  @override
  createState() => _LayerWidgetState();
}

class _LayerWidgetState extends State<LayerWidget>
    with ImageEditorConvertedConfigs, SimpleConfigsAccessState {
  final _layerKey = GlobalKey();

  /// The type of layer being represented.
  late _LayerType _layerType;

  /// Flag to control the display of a move cursor.
  bool _showMoveCursor = false;

  @override
  void initState() {
    switch (widget.layerData.runtimeType) {
      case const (TextLayer):
        _layerType = _LayerType.text;
        break;
      case const (EmojiLayer):
        _layerType = _LayerType.emoji;
        break;
      case const (WidgetLayer):
        _layerType = _LayerType.widget;
        break;
      case const (PaintLayer):
        _layerType = _LayerType.canvas;
        break;
      default:
        _layerType = _LayerType.unknown;
        break;
    }

    super.initState();
  }

  /// Handles a secondary tap up event, typically for showing a context menu.
  void _onSecondaryTapUp(TapUpDetails details) {
    if (_checkHitIsOutsideInCanvas()) return;
    final Offset clickPosition = details.globalPosition;
    double spacing = 14.0;

    widget.onContextMenuToggled?.call(true);

    // Show a popup menu at the click position
    showMenu(
      context: context,
      useRootNavigator: true,
      position: RelativeRect.fromLTRB(
        clickPosition.dx,
        clickPosition.dy,
        clickPosition.dx + 1.0, // Adding a small value to avoid zero width
        clickPosition.dy + 1.0, // Adding a small value to avoid zero height
      ),
      items: <PopupMenuEntry<String>>[
        if (_layerType == _LayerType.text &&
            widget.layerData.interaction.enableEdit)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              spacing: spacing,
              children: [
                Icon(layerInteraction.icons.edit),
                Text(i18n.layerInteraction.edit),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            spacing: spacing,
            children: [
              Icon(layerInteraction.icons.remove),
              Text(i18n.layerInteraction.remove),
            ],
          ),
        ),
      ],
    ).then((String? selectedValue) {
      switch (selectedValue) {
        case 'edit':
          widget.onEditTap?.call();
          break;
        case 'remove':
          widget.onRemoveTap?.call();
          break;
        default:
      }

      widget.onContextMenuToggled?.call(false);
    });
  }

  /// Handles a tap event on the layer.
  void _onTap() {
    if (_checkHitIsOutsideInCanvas()) return;
    widget.onTap?.call(_layer);
  }

  /// Handles a pointer down event on the layer.
  void _onPointerDown(PointerDownEvent event) {
    if (_checkHitIsOutsideInCanvas()) return;
    if (!isDesktop || event.buttons != kSecondaryMouseButton) {
      widget.onTapDown?.call();
    }
  }

  /// Handles a pointer up event on the layer.
  void _onPointerUp(PointerUpEvent event) {
    widget.onTapUp?.call();
  }

  /// Checks if the hit is outside the canvas for certain types of layers.
  bool _checkHitIsOutsideInCanvas() {
    return _layerType == _LayerType.canvas && !(_layer as PaintLayer).item.hit;
  }

  /// Calculates the transformation matrix for the layer's position and
  /// rotation.
  Matrix4 _calcTransformMatrix() {
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Add a small z-offset to avoid rendering issues
      ..rotateX(_layer.flipY ? pi : 0)
      ..rotateY(_layer.flipX ? pi : 0)
      ..rotateZ(_layer.rotation);
  }

  /// Returns the current layer being displayed.
  Layer get _layer => widget.layerData;

  /// Calculates the horizontal offset for the layer.
  double get offsetX => _layer.offset.dx + widget.editorCenterX;

  /// Calculates the vertical offset for the layer.
  double get offsetY => _layer.offset.dy + widget.editorCenterY;

  @override
  Widget build(BuildContext context) {
    // Position the widget with specified padding
    return Positioned(
      top: offsetY,
      left: offsetX,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: _buildPosition(), // Build the widget content
      ),
    );
  }

  /// Build the content with possible transformations
  Widget _buildPosition() {
    Matrix4 transformMatrix = _calcTransformMatrix();

    return Hero(
      key: _layerKey,
      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
      tag: widget.layerData.id,
      child: Transform(
        transform: transformMatrix,
        alignment: Alignment.center,
        child: LayerInteractionHelperWidget(
          layerData: widget.layerData,
          configs: configs,
          callbacks: callbacks,
          selected: widget.selected,
          onEditLayer: widget.onEditTap,
          isInteractive: widget.isInteractive,
          onScaleRotateDown: (details) {
            widget.onScaleRotateDown?.call(details, context.size ?? Size.zero);
          },
          onScaleRotateUp: widget.onScaleRotateUp,
          onRemoveLayer: widget.onRemoveTap,
          child: MouseRegion(
            hitTestBehavior: HitTestBehavior.translucent,
            cursor: _showMoveCursor && widget.layerData.interaction.enableMove
                ? layerInteraction.style.hoverCursor
                : MouseCursor.defer,
            onEnter: (event) {
              if (_layerType != _LayerType.canvas) {
                setState(() {
                  _showMoveCursor = true;
                });
              }
            },
            onExit: (event) {
              if (_layerType == _LayerType.canvas) {
                (widget.layerData as PaintLayer).item.hit = false;
              } else {
                setState(() {
                  _showMoveCursor = false;
                });
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onSecondaryTapUp: isDesktop ? _onSecondaryTapUp : null,
              onTap: _onTap,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                child: Padding(
                  padding: EdgeInsets.all(widget.selected ? 7.0 : 0),
                  child: FittedBox(
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the content widget based on the type of layer being displayed.
  Widget _buildContent() {
    switch (_layerType) {
      case _LayerType.emoji:
        return _buildEmoji();
      case _LayerType.text:
        return _buildText();
      case _LayerType.widget:
        return _buildWidgetLayer();
      case _LayerType.canvas:
        return _buildCanvas();
      default:
        return const SizedBox.shrink();
    }
  }

  double getLineHeight(TextStyle style) {
    final span = TextSpan(text: 'X', style: style);
    final painter = TextPainter(
      text: span,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.preferredLineHeight;
  }

  /// Build the text widget
  Widget _buildText() {
    var fontSize = textEditorConfigs.initFontSize * _layer.scale;
    var layer = _layer as TextLayer;
    var style = TextStyle(
      fontSize: fontSize * layer.fontScale,
      color: layer.color,
      overflow: TextOverflow.ellipsis,
    );

    double height = getLineHeight(style);
    const horizontalPaddingFactor = 0.3;

    return Container(
      // Fix Hit-Box
      padding: EdgeInsets.only(
        left: height * horizontalPaddingFactor,
        right: height * horizontalPaddingFactor,
        bottom: height * 0.175 / 2,
      ),
      child: HeroMode(
        enabled: false,
        child: RoundedBackgroundText(
          layer.text.toString(),
          backgroundColor: layer.background,
          textAlign: layer.align,
          style: layer.textStyle?.copyWith(
                fontSize: style.fontSize,
                fontWeight: style.fontWeight,
                color: style.color,
                fontFamily: style.fontFamily,
              ) ??
              style,
        ),
      ),
    );
  }

  /// Build the emoji widget
  Widget _buildEmoji() {
    var layer = _layer as EmojiLayer;
    return Material(
      // Prevent hero animation bug
      type: MaterialType.transparency,
      textStyle: platformTextStyle(context, designMode),
      child: Text(
        layer.emoji.toString(),
        textAlign: TextAlign.center,
        style: emojiEditorConfigs.style.textStyle.copyWith(
          fontSize: textEditorConfigs.initFontSize * _layer.scale,
        ),
      ),
    );
  }

  /// Build the layer widget
  Widget _buildWidgetLayer() {
    var layer = _layer as WidgetLayer;
    return SizedBox(
      width: stickerEditorConfigs.initWidth * layer.scale,
      child: FittedBox(
        fit: BoxFit.contain,
        child: layer.widget,
      ),
    );
  }

  /// Build the canvas widget
  Widget _buildCanvas() {
    var layer = _layer as PaintLayer;
    return Padding(
      // Better hit detection for mobile devices
      padding: EdgeInsets.all(isDesktop ? 0 : 15),
      child: RepaintBoundary(
        child: Opacity(
          opacity: layer.opacity,
          child: CustomPaint(
            size: layer.size,
            willChange: false,
            isComplex: layer.item.mode == PaintMode.freeStyle,
            painter: DrawPaintItem(
              item: layer.item,
              scale: widget.layerData.scale,
              selected: widget.selected,
              enabledHitDetection: widget.enableHitDetection,
              freeStyleHighPerformance: widget.highPerformanceMode,
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: camel_case_types
enum _LayerType { emoji, text, widget, canvas, unknown }
