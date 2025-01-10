// Flutter imports:
import 'package:flutter/widgets.dart';

// Project imports:
import '../custom_widgets/text_editor_widgets.dart';
import '../icons/text_editor_icons.dart';
import '../layers/enums/layer_background_mode.dart';
import '../styles/text_editor_style.dart';
import 'utils/editor_safe_area.dart';

export '../custom_widgets/text_editor_widgets.dart';
export '../icons/text_editor_icons.dart';
export '../styles/text_editor_style.dart';

/// Configuration options for a text editor.
///
/// `TextEditorConfigs` allows you to define settings for a text editor,
/// including whether the editor is enabled, which text formatting options
/// are available, and the initial font size.
///
/// Example usage:
/// ```dart
/// TextEditorConfigs(
///   enabled: true,
///   canToggleTextAlign: true,
///   canToggleBackgroundMode: true,
///   initFontSize: 24.0,
/// );
/// ```
class TextEditorConfigs {
  /// Creates an instance of TextEditorConfigs with optional settings.
  ///
  /// By default, the text editor is enabled, and most text formatting options
  /// are enabled. The initial font size is set to 24.0.
  const TextEditorConfigs({
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enabled = true,
    this.showSelectFontStyleBottomBar = false,
    this.canToggleTextAlign = true,
    this.canToggleBackgroundMode = true,
    this.canChangeFontScale = true,
    this.initFontSize = 24.0,
    this.initialTextAlign = TextAlign.center,
    this.initFontScale = 1.0,
    this.maxFontScale = 3.0,
    this.minFontScale = 0.3,
    this.minScale = double.negativeInfinity,
    this.maxScale = double.infinity,
    this.customTextStyles,
    this.defaultTextStyle = const TextStyle(),
    this.initialBackgroundColorMode = LayerBackgroundMode.backgroundAndColor,
    this.safeArea = const EditorSafeArea(),
    this.style = const TextEditorStyle(),
    this.icons = const TextEditorIcons(),
    this.widgets = const TextEditorWidgets(),
  })  : assert(initFontSize > 0, 'initFontSize must be positive'),
        assert(maxScale >= minScale,
            'maxScale must be greater than or equal to minScale');

  /// Indicates whether the text editor is enabled.
  final bool enabled;

  /// Determines if the text alignment options can be toggled.
  final bool canToggleTextAlign;

  /// Determines if the font scale can be change.
  final bool canChangeFontScale;

  /// Determines if the editor show a bottom bar where the user can select
  /// different font styles.
  final bool showSelectFontStyleBottomBar;

  /// Determines if the background mode can be toggled.
  final bool canToggleBackgroundMode;

  /// The initial font size for text.
  final double initFontSize;

  /// The initial text alignment for the layer.
  final TextAlign initialTextAlign;

  /// The initial font scale for text.
  final double initFontScale;

  /// The max font font scale for text.
  final double maxFontScale;

  /// The min font font scale for text.
  final double minFontScale;

  /// The initial background color mode for the layer.
  final LayerBackgroundMode initialBackgroundColorMode;

  /// Allow users to select a different font style
  final List<TextStyle>? customTextStyles;

  /// The default text style to be used in the text editor.
  ///
  /// This style will be applied to the text if no other style is specified.
  final TextStyle defaultTextStyle;

  /// The minimum scale factor from the layer.
  final double minScale;

  /// The maximum scale factor from the layer.
  final double maxScale;

  /// Whether to show input suggestions as the user types.
  ///
  /// This flag only affects Android. On iOS, suggestions are tied directly to
  /// [autocorrect], so that suggestions are only shown when [autocorrect] is
  /// true. On Android autocorrection and suggestion are controlled separately.
  ///
  /// Defaults to true.
  final bool enableSuggestions;

  /// Whether to enable autocorrection.
  ///
  /// Defaults to true.
  final bool autocorrect;

  /// Defines the safe area configuration for the editor.
  final EditorSafeArea safeArea;

  /// Style configuration for the text editor.
  final TextEditorStyle style;

  /// Icons used in the text editor.
  final TextEditorIcons icons;

  /// Widgets associated with the text editor.
  final TextEditorWidgets widgets;

  /// Creates a copy of this `TextEditorConfigs` object with the given fields
  /// replaced with new values.
  ///
  /// The [copyWith] method allows you to create a new instance of
  /// [TextEditorConfigs] with some properties updated while keeping the
  /// others unchanged.
  TextEditorConfigs copyWith({
    bool? enabled,
    bool? canToggleTextAlign,
    bool? canChangeFontScale,
    bool? showSelectFontStyleBottomBar,
    bool? canToggleBackgroundMode,
    double? initFontSize,
    TextAlign? initialTextAlign,
    double? initFontScale,
    double? maxFontScale,
    double? minFontScale,
    LayerBackgroundMode? initialBackgroundColorMode,
    List<TextStyle>? customTextStyles,
    TextStyle? defaultTextStyle,
    double? minScale,
    double? maxScale,
    bool? enableSuggestions,
    bool? autocorrect,
    EditorSafeArea? safeArea,
    TextEditorStyle? style,
    TextEditorIcons? icons,
    TextEditorWidgets? widgets,
  }) {
    return TextEditorConfigs(
      safeArea: safeArea ?? this.safeArea,
      enabled: enabled ?? this.enabled,
      canToggleTextAlign: canToggleTextAlign ?? this.canToggleTextAlign,
      canChangeFontScale: canChangeFontScale ?? this.canChangeFontScale,
      showSelectFontStyleBottomBar:
          showSelectFontStyleBottomBar ?? this.showSelectFontStyleBottomBar,
      canToggleBackgroundMode:
          canToggleBackgroundMode ?? this.canToggleBackgroundMode,
      initFontSize: initFontSize ?? this.initFontSize,
      initialTextAlign: initialTextAlign ?? this.initialTextAlign,
      initFontScale: initFontScale ?? this.initFontScale,
      maxFontScale: maxFontScale ?? this.maxFontScale,
      minFontScale: minFontScale ?? this.minFontScale,
      initialBackgroundColorMode:
          initialBackgroundColorMode ?? this.initialBackgroundColorMode,
      customTextStyles: customTextStyles ?? this.customTextStyles,
      defaultTextStyle: defaultTextStyle ?? this.defaultTextStyle,
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      enableSuggestions: enableSuggestions ?? this.enableSuggestions,
      autocorrect: autocorrect ?? this.autocorrect,
      style: style ?? this.style,
      icons: icons ?? this.icons,
      widgets: widgets ?? this.widgets,
    );
  }
}
