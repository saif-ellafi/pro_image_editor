// Project imports:
import 'utils/export_import_enum.dart';

/// Configuration options for exporting editor contents.
///
/// This class defines various options for exporting editor contents such as
/// paint, text, crop/rotate actions, filters, emojis, and stickers.
class ExportEditorConfigs {
  /// Creates an instance of the [ExportEditorConfigs]
  const ExportEditorConfigs({
    this.historySpan = ExportHistorySpan.all,
    this.exportPaint = true,
    this.exportText = true,
    this.exportCropRotate = true,
    this.exportFilter = true,
    this.exportTuneAdjustments = true,
    this.exportEmoji = true,
    this.exportSticker = true,
    this.serializeSticker = true,
  });

  /// The span of the export history to include in the export.
  ///
  /// By default, it includes the entire export history.
  final ExportHistorySpan historySpan;

  /// Whether to export the layers from the paint editor.
  ///
  /// Defaults to `true`.
  final bool exportPaint;

  /// Whether to export the text content.
  ///
  /// Defaults to `true`.
  final bool exportText;

  /// Whether to export the crop and rotate actions.
  ///
  /// Defaults to `true`.
  final bool exportCropRotate;

  /// Whether to export the applied filters.
  ///
  /// Defaults to `true`.
  final bool exportFilter;

  /// Whether to export the applied tune adjustments.
  ///
  /// Defaults to `true`.
  final bool exportTuneAdjustments;

  /// Whether to export the emojis.
  ///
  /// Defaults to `true`.
  final bool exportEmoji;

  /// Whether to export the stickers.
  ///
  /// Defaults to `true`.
  ///
  /// Warning: Exporting stickers may result in increased file size.
  final bool exportSticker;

  /// Whether to serialize the stickers.
  ///
  /// Defaults to `true`.
  ///
  /// Warning: Not serializing stickers may result in loss of stickers.
  final bool serializeSticker;
}
