// Project imports:
import '../enums/export_import_enum.dart';

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
    this.exportSticker,
    this.exportWidgets = true,
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

  // TODO: Remove in version 8.0.0
  /// Whether to export the stickers.
  ///
  /// Defaults to `true`.
  ///
  /// Warning: Exporting stickers may result in increased file size.
  @Deprecated('Use exportWidgets instead')
  final bool? exportSticker;

  /// Whether to export the widget layers.
  ///
  /// Defaults to `true`.
  ///
  /// Warning: Exporting widgets may result in a significantly increased file
  /// size if no `exportConfigs` are added to the `WidgetLayer`.
  final bool exportWidgets;

  // TODO: Remove in version 8.0.0
  /// **DEPRECATED:**
  /// Controls whether stickers should be serialized.
  ///
  /// When enabled, each sticker widget is converted to a `Uint8List` and
  /// included in the export history.
  /// **Note:** Enabling this flag with a large number of stickers can
  /// significantly increase the size of the JSON file.
  ///
  /// Defaults to `true`.
  ///
  /// **Warning:** Disabling sticker serialization may result in the loss of
  /// stickers during export.
  @Deprecated(
    'The parameter is no longer used. Instead, add `exportConfigs` to the '
    '`WidgetLayer`',
  )
  final bool serializeSticker;
}
