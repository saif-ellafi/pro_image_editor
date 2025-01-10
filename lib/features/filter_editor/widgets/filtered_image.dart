// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/editor_image.dart';
import '/core/models/tune_editor/tune_adjustment_matrix.dart';
import '/shared/widgets/auto_image.dart';
import '../types/filter_matrix.dart';
import 'filter_generator.dart';

/// Represents an image where filters and blur factors can be applied.
class FilteredImage extends StatelessWidget {
  /// Constructor for creating an instance of FilteredImage.
  const FilteredImage({
    super.key,
    required this.width,
    required this.height,
    required this.configs,
    required this.filters,
    required this.tuneAdjustments,
    required this.image,
    required this.blurFactor,
    this.filterKey,
    this.fit = BoxFit.contain,
  });

  /// A key that uniquely identifies the [ColorFilterGeneratorState] widget and
  /// allows access to its state. This can be used to manipulate the state of
  /// the color filter generator from outside the widget tree.
  ///
  /// This key is optional and can be null.
  final GlobalKey<ColorFilterGeneratorState>? filterKey;

  /// The width of the image.
  final double width;

  /// The height of the image.
  final double height;

  /// A class representing configuration options for the Image Editor.
  final ProImageEditorConfigs configs;

  /// The list of filters to be applied on the image.
  final FilterMatrix filters;

  /// The list of tune adjustments to be applied on the image.
  final List<TuneAdjustmentMatrix> tuneAdjustments;

  /// The editor image to display.
  final EditorImage image;

  /// How the image should be inscribed into the space allocated for it.
  final BoxFit fit;

  /// The blur factor
  final double blurFactor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        // StackFit.expand is important for [transformed_content_generator.dart]
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          _buildImage(),
          ColorFilterGenerator(
            key: filterKey,
            filters: filters,
            tuneAdjustments: tuneAdjustments,
            child: _buildImage(),
          ),
          ClipRect(
            clipBehavior: Clip.hardEdge,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurFactor, sigmaY: blurFactor),
              child: Container(
                width: width,
                height: height,
                alignment: Alignment.center,
                color: Colors.white.withValues(alpha: 0.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return AutoImage(
      image,
      fit: fit,
      width: width,
      height: height,
      configs: configs,
    );
  }
}
