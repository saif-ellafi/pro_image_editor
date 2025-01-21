// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/widgets.dart';

// Project imports:
import '/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/shared/services/content_recorder/controllers/content_recorder_controller.dart';

/// A class that manages various controllers used in the main editor interface.
class MainEditorControllers {
  /// Constructs a new instance of [MainEditorControllers].
  MainEditorControllers(
    ProImageEditorConfigs configs,
    ProImageEditorCallbacks callbacks,
  ) {
    bottomBarScrollCtrl = ScrollController();
    helperLineCtrl = StreamController.broadcast();
    layerHeroResetCtrl = StreamController.broadcast();
    removeBtnCtrl = StreamController.broadcast();
    uiLayerCtrl = StreamController.broadcast();
    cropLayerPainterCtrl = StreamController.broadcast();
    screenshot = ContentRecorderController(
      configs: configs.imageGeneration,
      enableThumbnailGeneration: callbacks.onThumbnailGenerated != null,
    );
  }

  /// Scroll controller for the bottom bar in the editor interface.
  late final ScrollController bottomBarScrollCtrl;

  /// Stream controller for tracking mouse movement within the editor.
  late final StreamController<void> helperLineCtrl;

  /// Stream controller for resetting layer hero animations.
  late final StreamController<bool> layerHeroResetCtrl;

  /// Stream controller for the remove button.
  late final StreamController<void> removeBtnCtrl;

  /// Controller which updates only the UI from the layers.
  late final StreamController<void> uiLayerCtrl;

  /// Controller which updates only the UI from the crop-layer-painter.
  late final StreamController<void> cropLayerPainterCtrl;

  /// Controller for capturing screenshots of the editor content.
  late final ContentRecorderController screenshot;

  /// Disposes of resources held by the controllers.
  void dispose() {
    bottomBarScrollCtrl.dispose();
    helperLineCtrl.close();
    layerHeroResetCtrl.close();
    removeBtnCtrl.close();
    cropLayerPainterCtrl.close();
    screenshot.destroy();
    uiLayerCtrl.close();
  }
}
