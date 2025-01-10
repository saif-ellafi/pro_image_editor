// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/services.dart';

import '/core/models/crop_rotate_editor/transform_factors.dart';
import '/core/models/editor_image.dart';
import '/core/models/history/state_history.dart';
import '/core/models/layers/layer.dart';
import '/core/models/tune_editor/tune_adjustment_matrix.dart';
import '/core/utils/parser/double_parser.dart';
import '/core/utils/parser/int_parser.dart';
import '/core/utils/parser/size_parser.dart';
import '/features/filter_editor/utils/filter_generator/filter_addons.dart';
import 'constants/export_import_version.dart';
import 'models/import_state_history_configs.dart';
import 'utils/key_minifier.dart';

/// This class represents the state history of an imported editor session.
class ImportStateHistory {
  /// Constructs an [ImportStateHistory] instance.
  ImportStateHistory._({
    required this.editorPosition,
    required this.imgSize,
    required this.lastRenderedImgSize,
    required this.stateHistory,
    required this.configs,
    required this.version,
    required this.requirePrecacheList,
  });

  /// Creates an [ImportStateHistory] instance from a JSON file.
  factory ImportStateHistory.fromJsonFile(
    File file, {
    ImportEditorConfigs configs = const ImportEditorConfigs(),
  }) {
    String json = file.readAsStringSync();
    return ImportStateHistory.fromJson(json, configs: configs);
  }

  /// Creates an [ImportStateHistory] instance from a JSON string.
  factory ImportStateHistory.fromJson(
    String json, {
    ImportEditorConfigs configs = const ImportEditorConfigs(),
  }) {
    return ImportStateHistory.fromMap(jsonDecode(json), configs: configs);
  }

  /// Creates an [ImportStateHistory] instance from a map representation.
  factory ImportStateHistory.fromMap(
    Map<String, dynamic> map, {
    ImportEditorConfigs configs = const ImportEditorConfigs(),
  }) {
    bool isMinified = map['m'] == true;

    EditorKeyMinifier minifier = EditorKeyMinifier(enableMinify: isMinified);

    final blurKey = minifier.convertHistoryKey('blur');
    final tuneKey = minifier.convertHistoryKey('tune');
    final filtersKey = minifier.convertHistoryKey('filters');
    final transformKey = minifier.convertHistoryKey('transform');

    /// Initialize default values
    final version = map[minifier.convertMainKey('version')] as String? ??
        ExportImportVersion.version_1_0_0;
    final stateHistory = <EditorStateHistory>[];
    final widgetRecords = _parseWidgetRecords(map, version);
    final lastRenderedImgSize =
        safeParseSize(map[minifier.convertMainKey('lastRenderedImgSize')]);
    final List<EditorImage> requirePrecacheList = [];

    Map<String, Map<String, dynamic>> lastLayerStateHelper = {
      ...map[minifier.convertMainKey('references')] ?? {}
    };

    var historyList =
        (map[minifier.convertMainKey('history')] as List<dynamic>? ?? []);

    /// Parse history
    for (final historyItem in historyList) {
      /// Layers
      List<Layer> layers = [];
      switch (version) {
        case ExportImportVersion.version_1_0_0:
        case ExportImportVersion.version_2_0_0:
        case ExportImportVersion.version_3_0_1:
        case ExportImportVersion.version_3_0_0:
        case ExportImportVersion.version_4_0_0:
          layers = (historyItem['layers'] as List<dynamic>? ?? [])
              .map(
                (layer) => Layer.fromMap(
                  layer,
                  widgetRecords: widgetRecords,
                  widgetLoader: configs.widgetLoader,
                  requirePrecache: requirePrecacheList.add,
                ),
              )
              .toList();
          break;
        default:
          for (var rawLayer in List.from(
              historyItem[minifier.convertHistoryKey('layers')] ?? [])) {
            String id = rawLayer['id'];
            Map<String, dynamic> convertedLayerMap = {
              ...lastLayerStateHelper[id] ?? {},
              ...rawLayer,
            };

            layers.add(Layer.fromMap(
              convertedLayerMap,
              widgetRecords: widgetRecords,
              widgetLoader: configs.widgetLoader,
              requirePrecache: requirePrecacheList.add,
              minifier: minifier,
              id: id,
            ));

            lastLayerStateHelper[id] =
                Map<String, Object>.from(convertedLayerMap);
          }
      }

      /// Blur
      final blur = historyItem[blurKey] != null
          ? safeParseDouble(historyItem[blurKey])
          : null;

      /// Filters
      final filters = _parseFilters(historyItem[filtersKey], version);

      /// Tune Adjustments
      final tuneAdjustments = (historyItem[tuneKey] as List<dynamic>? ?? [])
          .map((tune) => TuneAdjustmentMatrix.fromMap(tune))
          .toList();

      /// Transformations
      final transformConfigs = historyItem[transformKey] != null &&
              Map.from(historyItem[transformKey]).isNotEmpty
          ? TransformConfigs.fromMap(historyItem[transformKey])
          : TransformConfigs.empty();

      stateHistory.add(EditorStateHistory(
        blur: blur,
        layers: layers,
        filters: filters,
        tuneAdjustments: tuneAdjustments,
        transformConfigs: transformConfigs,
      ));
    }

    return ImportStateHistory._(
      editorPosition: safeParseInt(map[minifier.convertMainKey('position')]),
      imgSize: safeParseSize(map[minifier.convertMainKey('imgSize')]),
      lastRenderedImgSize: lastRenderedImgSize,
      stateHistory: stateHistory,
      configs: configs,
      version: version,
      requirePrecacheList: requirePrecacheList,
    );
  }

  /// Helper to parse filters
  static List<List<double>> _parseFilters(dynamic filtersData, String version) {
    if (filtersData == null) return [];

    switch (version) {
      case ExportImportVersion.version_1_0_0:
        return (filtersData as List<dynamic>).expand((el) {
          final filterMatrix = List<List<double>>.from(el['filters'] ?? []);
          final opacity = safeParseDouble(el['opacity'], fallback: 1);
          if (opacity != 1) {
            filterMatrix.add(ColorFilterAddons.opacity(opacity));
          }
          return filterMatrix;
        }).toList();
      default:
        return (filtersData as List<dynamic>)
            .map((el) => List<double>.from(el))
            .toList();
    }
  }

  static List<Uint8List> _parseWidgetRecords(
      Map<String, dynamic> map, String version) {
    List<dynamic> items = [];
    switch (version) {
      case ExportImportVersion.version_1_0_0:
      case ExportImportVersion.version_2_0_0:
      case ExportImportVersion.version_3_0_0:
      case ExportImportVersion.version_3_0_1:
        items = (map['stickers'] as List<dynamic>? ?? []);
        break;
      default:
        items = (map['widgetRecords'] as List<dynamic>? ?? []);
        break;
    }

    return items.map((item) => Uint8List.fromList(List.from(item))).toList();
  }

  /// A list of widget layers that need to be pre-cached.
  ///
  /// This list contains images that should be loaded and cached in memory
  /// before they are used in the editor to ensure smooth performance and
  /// quick access.
  final List<EditorImage> requirePrecacheList;

  /// The position of the editor.
  final int editorPosition;

  /// The size of the imported image.
  final Size imgSize;

  /// The size of the last used screen.
  final Size lastRenderedImgSize;

  /// The state history of each editor state in the session.
  final List<EditorStateHistory> stateHistory;

  /// The configurations for importing the editor state history.
  final ImportEditorConfigs configs;

  /// Version from import/export history for backward compatibility.
  final String version;
}
