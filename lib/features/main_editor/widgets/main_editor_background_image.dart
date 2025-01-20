import 'package:flutter/material.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/editor_image.dart';
import '/features/filter_editor/widgets/filter_generator.dart';
import '/features/filter_editor/widgets/filtered_image.dart';
import '/shared/widgets/auto_image.dart';
import '/shared/widgets/transform/transformed_content_generator.dart';
import '../services/sizes_manager.dart';
import '../services/state_manager.dart';

class MainEditorBackgroundImage extends StatelessWidget {
  const MainEditorBackgroundImage({
    super.key,
    required this.stateManager,
    required this.sizesManager,
    required this.configs,
    required this.editorImage,
    required this.backgroundImageColorFilterKey,
    required this.isInitialized,
  });

  final EditorImage editorImage;
  final StateManager stateManager;
  final SizesManager sizesManager;
  final ProImageEditorConfigs configs;
  final GlobalKey<ColorFilterGeneratorState> backgroundImageColorFilterKey;
  final bool isInitialized;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: configs.heroTag,
      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
      child: !isInitialized
          ? AutoImage(
              editorImage,
              fit: BoxFit.contain,
              width: sizesManager.decodedImageSize.width,
              height: sizesManager.decodedImageSize.height,
              configs: configs,
            )
          : TransformedContentGenerator(
              transformConfigs: stateManager.transformConfigs,
              configs: configs,
              child: FilteredImage(
                filterKey: backgroundImageColorFilterKey,
                width: sizesManager.decodedImageSize.width,
                height: sizesManager.decodedImageSize.height,
                configs: configs,
                image: editorImage,
                filters: stateManager.activeFilters,
                tuneAdjustments: stateManager.activeTuneAdjustments,
                blurFactor: stateManager.activeBlur,
              ),
            ),
    );
  }
}
