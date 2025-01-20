import 'package:flutter/widgets.dart';
import '/features/crop_rotate_editor/models/transform_factors.dart';
import '/shared/utils/decode_image.dart';
import '../custom_widgets/main_editor_widgets.dart';
import '../icons/main_editor_icons.dart';
import '../styles/main_editor_style.dart';

export '../custom_widgets/main_editor_widgets.dart';
export '../icons/main_editor_icons.dart';
export '../styles/main_editor_style.dart';

/// Configuration options for a main editor.
class MainEditorConfigs {
  /// Creates an instance of MainEditorConfigs with optional settings.
  const MainEditorConfigs({
    this.enableZoom = false,
    this.enableCloseButton = true,
    this.editorMinScale = 1.0,
    this.editorMaxScale = 5.0,
    this.transformSetup,
    this.boundaryMargin = EdgeInsets.zero,
    this.style = const MainEditorStyle(),
    this.icons = const MainEditorIcons(),
    this.widgets = const MainEditorWidgets(),
  });

  /// Determines whether the close button is displayed on the widget.
  final bool enableCloseButton;

  /// {@template enableZoom}
  /// Indicates whether the editor supports zoom functionality.
  ///
  /// When set to `true`, the editor allows users to zoom in and out, providing
  /// enhanced accessibility and usability, especially on smaller screens or for
  /// users with visual impairments. If set to `false`, the zoom functionality
  /// is disabled, and the editor's content remains at a fixed scale.
  ///
  /// Default value is `false`.
  /// {@endtemplate}
  final bool enableZoom;

  /// The minimum scale factor for the editor.
  ///
  /// This value determines the lowest level of zoom that can be applied to the
  /// editor content. It only has an effect when [enableZoom] is set to
  /// `true`.
  /// If [enableZoom] is `false`, this value is ignored.
  ///
  /// Default value is 1.0.
  final double editorMinScale;

  /// The maximum scale factor for the editor.
  ///
  /// This value determines the highest level of zoom that can be applied to the
  /// editor content. It only has an effect when [enableZoom] is set to
  /// `true`.
  /// If [enableZoom] is `false`, this value is ignored.
  ///
  /// Default value is 5.0.
  final double editorMaxScale;

  /// Zoom boundary
  ///
  /// A margin for the visible boundaries of the child.
  ///
  /// Any transformation that results in the viewport being able to view
  /// outside of the boundaries will be stopped at the boundary.
  /// The boundaries do not rotate with the rest of the scene, so they are
  /// always aligned with the viewport.
  ///
  /// To produce no boundaries at all, pass infinite [EdgeInsets], such as
  /// EdgeInsets.all(double.infinity).
  ///
  /// No edge can be NaN.
  ///
  /// Defaults to [EdgeInsets.zero], which results in boundaries that are the
  /// exact same size and position as the [child].
  final EdgeInsets boundaryMargin;

  /// Initializes the editor with pre-configured transformations,
  /// such as cropping, based on the provided setup.
  final MainEditorTransformSetup? transformSetup;

  /// Style configuration for the main editor.
  final MainEditorStyle style;

  /// Icons used in the main editor.
  final MainEditorIcons icons;

  /// Widgets associated with the main editor.
  final MainEditorWidgets widgets;

  /// Creates a copy of this `MainEditorConfigs` object with the given fields
  /// replaced with new values.
  ///
  /// The [copyWith] method allows you to create a new instance of
  /// [MainEditorConfigs] with some properties updated while keeping the
  /// others unchanged.
  MainEditorConfigs copyWith({
    bool? enableCloseButton,
    bool? enableZoom,
    double? editorMinScale,
    double? editorMaxScale,
    MainEditorTransformSetup? transformSetup,
    EdgeInsets? boundaryMargin,
    MainEditorStyle? style,
    MainEditorIcons? icons,
    MainEditorWidgets? widgets,
  }) {
    return MainEditorConfigs(
      enableCloseButton: enableCloseButton ?? this.enableCloseButton,
      enableZoom: enableZoom ?? this.enableZoom,
      editorMinScale: editorMinScale ?? this.editorMinScale,
      editorMaxScale: editorMaxScale ?? this.editorMaxScale,
      transformSetup: transformSetup ?? this.transformSetup,
      boundaryMargin: boundaryMargin ?? this.boundaryMargin,
      style: style ?? this.style,
      widgets: widgets ?? this.widgets,
      icons: icons ?? this.icons,
    );
  }
}

/// A class that encapsulates the configuration and image information
/// required to set up the main editor's transform settings.
class MainEditorTransformSetup {
  /// Creates an instance of [MainEditorTransformSetup] with the required
  /// transformation configurations and image information.
  ///
  /// - [transformConfigs]: The configuration settings for the transformation.
  /// - [imageInfos]: The information about the image to be edited.
  MainEditorTransformSetup({
    required this.transformConfigs,
    this.imageInfos,
  });

  /// The configuration settings for the transformation applied in the main
  /// editor.
  final TransformConfigs transformConfigs;

  /// The information related to the image that will be edited in the main
  /// editor.
  final ImageInfos? imageInfos;

  /// Creates a copy of the current [MainEditorTransformSetup] instance
  /// with the option to override specific fields.
  ///
  /// - [transformConfigs]: Overrides the existing `transformConfigs` if
  /// provided.
  /// - [imageInfos]: Overrides the existing `imageInfos` if provided.
  ///
  /// Returns a new instance of [MainEditorTransformSetup] with the updated
  /// fields.
  MainEditorTransformSetup copyWith({
    TransformConfigs? transformConfigs,
    ImageInfos? imageInfos,
  }) {
    return MainEditorTransformSetup(
      transformConfigs: transformConfigs ?? this.transformConfigs,
      imageInfos: imageInfos ?? this.imageInfos,
    );
  }
}
