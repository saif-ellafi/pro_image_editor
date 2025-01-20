import 'dart:async';

import 'package:flutter/material.dart';

import '/core/models/editor_callbacks/main_editor_callbacks.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/history/state_history.dart';
import '/core/models/layers/layer.dart';
import '/shared/services/import_export/constants/export_import_version.dart';
import '/shared/services/import_export/enums/export_import_enum.dart';
import '/shared/services/import_export/export_state_history.dart';
import '/shared/services/import_export/import_state_history.dart';
import '/shared/services/import_export/models/export_state_history_configs.dart';
import '/shared/utils/decode_image.dart';
import '../controllers/main_editor_controllers.dart';
import 'sizes_manager.dart';
import 'state_manager.dart';

class MainEditorStateHistoryService {
  MainEditorStateHistoryService({
    required this.configs,
    required this.takeScreenshot,
    required this.sizesManager,
    required this.stateManager,
    required this.controllers,
    required this.mainEditorCallbacks,
  });
  final SizesManager sizesManager;
  final StateManager stateManager;
  final MainEditorControllers controllers;
  final ProImageEditorConfigs configs;
  final MainEditorCallbacks? mainEditorCallbacks;

  final Function() takeScreenshot;

  /// Imports state history and performs necessary recalculations.
  Future<void> importStateHistory(
      ImportStateHistory import, BuildContext context) async {
    // Recalculate position and size if needed
    if (import.configs.recalculateSizeAndPosition ||
        import.version == ExportImportVersion.version_1_0_0) {
      _recalculateSizeAndPosition(import);
    }

    // Precache widget layers
    await _precacheLayers(import, context);

    // Merge or replace state history
    if (import.configs.mergeMode == ImportEditorMergeMode.replace) {
      _replaceStateHistory(import);
    } else {
      _mergeStateHistory(import);
    }

    // Update state and UI
    stateManager.updateActiveItems();
    mainEditorCallbacks?.handleUpdateUI();
  }

  /// Exports the current state history.
  Future<ExportStateHistory> exportStateHistory({
    ExportEditorConfigs configs = const ExportEditorConfigs(),
    required BuildContext context,
    required ImageInfos imageInfos,
  }) async {
    return ExportStateHistory(
      editorConfigs: this.configs,
      stateHistory: stateManager.stateHistory,
      imageInfos: imageInfos,
      imgSize: sizesManager.decodedImageSize,
      editorPosition: stateManager.historyPointer,
      configs: configs,
      contentRecorderCtrl: controllers.screenshot,
      context: context,
    );
  }

  void _recalculateSizeAndPosition(ImportStateHistory import) {
    for (EditorStateHistory el in import.stateHistory) {
      for (Layer layer in el.layers) {
        if (import.configs.recalculateSizeAndPosition) {
          Size currentImageSize = sizesManager.decodedImageSize;
          Size lastDecodedImageSize = import.lastRenderedImgSize;

          double scaleWidth =
              currentImageSize.width / lastDecodedImageSize.width;
          double scaleHeight =
              currentImageSize.height / lastDecodedImageSize.height;

          scaleWidth = scaleWidth.isFinite ? scaleWidth : 1;
          scaleHeight = scaleHeight.isFinite ? scaleHeight : 1;

          double scale = (scaleWidth + scaleHeight) / 2;

          layer
            ..scale *= scale
            ..offset = Offset(
              layer.offset.dx * scaleWidth,
              layer.offset.dy * scaleHeight,
            );
        }

        if (import.version == ExportImportVersion.version_1_0_0) {
          layer.offset -= Offset(
            sizesManager.bodySize.width / 2 - sizesManager.imageScreenGaps.left,
            sizesManager.bodySize.height / 2 - sizesManager.imageScreenGaps.top,
          );
        }
      }
    }
  }

  Future<void> _precacheLayers(
      ImportStateHistory import, BuildContext context) async {
    await Future.wait(
      import.requirePrecacheList.toSet().map(
            (item) => precacheImage(
              item.toImageProvider(),
              context,
            ),
          ),
    );
  }

  void _replaceStateHistory(ImportStateHistory import) {
    stateManager
      ..screenshots = []
      ..stateHistory = [
        EditorStateHistory(
          transformConfigs: TransformConfigs.empty(),
          blur: 0,
          filters: [],
          layers: [],
          tuneAdjustments: [],
        ),
        ...import.stateHistory,
      ]
      ..historyPointer =
          import.editorPosition + (import.stateHistory.isEmpty ? 0 : 1);

    for (var i = 0; i < import.stateHistory.length; i++) {
      controllers.screenshot
          .addEmptyScreenshot(screenshots: stateManager.screenshots);
    }
  }

  void _mergeStateHistory(ImportStateHistory import) {
    for (var el in stateManager.screenshots) {
      el.broken = true;
    }

    for (var el in import.stateHistory) {
      if (import.configs.mergeMode == ImportEditorMergeMode.merge) {
        el.layers.insertAll(0, stateManager.stateHistory.last.layers);
        el.filters.insertAll(0, stateManager.stateHistory.last.filters);
        el.tuneAdjustments
            .insertAll(0, stateManager.stateHistory.last.tuneAdjustments);
      }
    }

    for (var i = 0; i < import.stateHistory.length; i++) {
      stateManager.stateHistory.add(import.stateHistory[i]);
      if (i < import.stateHistory.length - 1) {
        controllers.screenshot
            .addEmptyScreenshot(screenshots: stateManager.screenshots);
      } else {
        takeScreenshot();
      }
    }
    stateManager.historyPointer = stateManager.stateHistory.length - 1;
  }
}
