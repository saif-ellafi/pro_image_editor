/// A class representing the interaction settings for a layer.
///
/// The `LayerInteraction` class defines the enablement of various interaction
/// capabilities for a layer, including moving, scaling, rotating, and
/// selection.
class LayerInteraction {
  /// Creates a new instance of [LayerInteraction] with customizable
  /// interaction settings.
  ///
  /// All interaction settings are enabled by default unless specified
  /// otherwise.
  ///
  /// - [enableMove]: Enables the ability to move the layer.
  /// - [enableScale]: Enables the ability to scale the layer.
  /// - [enableRotate]: Enables the ability to rotate the layer.
  /// - [enableSelection]: Enables the ability to select the layer.
  LayerInteraction({
    this.enableMove = true,
    this.enableScale = true,
    this.enableRotate = true,
    this.enableSelection = true,
  });

  /// Creates a [LayerInteraction] instance from a [Map].
  ///
  /// - [map]: The map containing interaction settings with keys matching
  ///   the property names.
  /// - [keyConverter]: An optional function to convert keys from the map to
  ///   match the property names. Defaults to identity mapping.
  factory LayerInteraction.fromMap(
    Map<String, dynamic> map, {
    Function(String key)? keyConverter,
  }) {
    keyConverter ??= (String key) => key;

    return LayerInteraction(
      enableMove: map[keyConverter('enableMove')] ?? false,
      enableScale: map[keyConverter('enableScale')] ?? false,
      enableRotate: map[keyConverter('enableRotate')] ?? false,
      enableSelection: map[keyConverter('enableSelection')] ?? false,
    );
  }

  /// Creates a [LayerInteraction] instance with all interaction properties
  /// set to the specified [value].
  ///
  /// The [value] parameter is used to set the following properties:
  /// - [enableMove]
  /// - [enableScale]
  /// - [enableRotate]
  /// - [enableSelection]
  ///
  /// This factory constructor allows for quick initialization of a
  /// [LayerInteraction] object with uniform interaction capabilities.
  factory LayerInteraction.fromDefaultValue(bool value) {
    return LayerInteraction(
      enableMove: value,
      enableScale: value,
      enableRotate: value,
      enableSelection: value,
    );
  }

  /// Whether moving the layer is enabled.
  bool enableMove;

  /// Whether scaling the layer is enabled.
  bool enableScale;

  /// Whether rotating the layer is enabled.
  bool enableRotate;

  /// Whether selecting the layer is enabled.
  bool enableSelection;

  /// Creates a copy of this [LayerInteraction] with optional overrides.
  ///
  /// - [enableMove]: If provided, overrides the current `enableMove` setting.
  /// - [enableScale]: If provided, overrides the current `enableScale` setting.
  /// - [enableRotate]: If provided, overrides the current `enableRotate`
  ///   setting.
  /// - [enableSelection]: If provided, overrides the current `enableSelection`
  ///   setting.
  LayerInteraction copyWith({
    bool? enableMove,
    bool? enableScale,
    bool? enableRotate,
    bool? enableSelection,
  }) {
    return LayerInteraction(
      enableMove: enableMove ?? this.enableMove,
      enableScale: enableScale ?? this.enableScale,
      enableRotate: enableRotate ?? this.enableRotate,
      enableSelection: enableSelection ?? this.enableSelection,
    );
  }

  /// Converts this [LayerInteraction] instance into a [Map].
  ///
  /// Returns a map representation of the interaction settings with keys
  /// corresponding to the property names.
  Map<String, dynamic> toMap() {
    return {
      'enableMove': enableMove,
      'enableScale': enableScale,
      'enableRotate': enableRotate,
      'enableSelection': enableSelection,
    };
  }

  /// Converts this [LayerInteraction] instance into a [Map] while comparing
  /// it to another reference [LayerInteraction].
  ///
  /// Only includes the properties where the current instance's values differ
  /// from the [interaction] reference.
  Map<String, dynamic> toMapFromReference(LayerInteraction interaction) {
    return {
      if (interaction.enableMove != enableMove) 'enableMove': enableMove,
      if (interaction.enableScale != enableScale) 'enableScale': enableScale,
      if (interaction.enableRotate != enableRotate)
        'enableRotate': enableRotate,
      if (interaction.enableSelection != enableSelection)
        'enableSelection': enableSelection,
    };
  }

  /// Returns a string representation of the [LayerInteraction] instance.
  @override
  String toString() {
    return 'LayerInteraction(enableMove: $enableMove, '
        'enableScale: $enableScale, '
        'enableRotate: $enableRotate, '
        'enableSelection: $enableSelection)';
  }

  /// Compares this [LayerInteraction] instance with another for equality.
  ///
  /// Two [LayerInteraction] instances are considered equal if all their
  /// properties match.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LayerInteraction &&
        other.enableMove == enableMove &&
        other.enableScale == enableScale &&
        other.enableRotate == enableRotate &&
        other.enableSelection == enableSelection;
  }

  /// Returns a hash code for this [LayerInteraction] instance.
  @override
  int get hashCode {
    return enableMove.hashCode ^
        enableScale.hashCode ^
        enableRotate.hashCode ^
        enableSelection.hashCode;
  }
}
