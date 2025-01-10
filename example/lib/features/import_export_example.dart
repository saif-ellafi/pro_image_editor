import 'package:example/core/constants/example_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '/core/constants/history_demo/import_history_5_0_0_minified.dart';
import '/core/mixin/example_helper.dart';

/// The import export example
class ImportExportExample extends StatefulWidget {
  /// Creates a new [ImportExportExample] widget.
  const ImportExportExample({super.key});

  @override
  State<ImportExportExample> createState() => _ImportExportExampleState();
}

class _ImportExportExampleState extends State<ImportExportExample>
    with ExampleHelperState<ImportExportExample> {
  @override
  void initState() {
    preCacheImage(assetPath: kImageEditorExampleAssetPath);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!isPreCached) return const PrepareImageWidget();

    return Stack(
      children: [
        ProImageEditor.asset(
          kImageEditorExampleAssetPath,
          key: editorKey,
          callbacks: ProImageEditorCallbacks(
            onImageEditingStarted: onImageEditingStarted,
            onImageEditingComplete: onImageEditingComplete,
            onCloseEditor: () =>
                onCloseEditor(enablePop: !isDesktopMode(context)),
          ),
          configs: ProImageEditorConfigs(
            imageGeneration: const ImageGenerationConfigs(
              generateImageInBackground: false,
            ),
            designMode: platformDesignMode,
            mainEditor: MainEditorConfigs(
              enableCloseButton: !isDesktopMode(context),
              widgets: MainEditorWidgets(
                bodyItems: (editor, rebuildStream) {
                  return [
                    ReactiveWidget(
                        builder: (_) {
                          return Positioned(
                            bottom: 20,
                            left: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.lightBlue.shade200,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(100),
                                  bottomRight: Radius.circular(100),
                                ),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  var history = await editor.exportStateHistory(
                                    configs: const ExportEditorConfigs(
                                        historySpan:
                                            ExportHistorySpan.currentAndBackward
                                        // configs...
                                        ),
                                  );
                                  debugPrint(await history.toJson());
                                },
                                icon: const Icon(
                                  Icons.send_to_mobile_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                        stream: rebuildStream),
                  ];
                },
              ),
            ),
            emojiEditor: EmojiEditorConfigs(
                checkPlatformCompatibility: !kIsWeb,
                style: kIsWeb
                    ? EmojiEditorStyle(
                        textStyle: DefaultEmojiTextStyle.copyWith(
                          fontFamily: GoogleFonts.notoColorEmoji().fontFamily,
                        ),
                      )
                    : const EmojiEditorStyle()),
            stateHistory: StateHistoryConfigs(
              initStateHistory: ImportStateHistory.fromMap(
                kImportHistoryDemoData,
                configs: ImportEditorConfigs(
                  recalculateSizeAndPosition: true,

                  /// The `widgetLoader` is optional and only required if you
                  /// add `exportConfigs` with an id to the widget layers.
                  /// Refer to the [sticker-example](https://github.com/hm21/pro_image_editor/blob/stable/example/lib/features/stickers_example.dart)
                  /// for details on how this works in the sticker editor.
                  ///
                  /// If you add widget layers directly to the editor,
                  /// you can pass the parameters as shown below:
                  ///
                  /// ```dart
                  /// editor.addLayer(
                  ///   WidgetLayer(
                  ///     exportConfigs: const WidgetLayerExportConfigs(
                  ///       id: 'my-special-container',
                  ///     ),
                  ///     widget: Container(
                  ///       width: 100,
                  ///       height: 100,
                  ///       color: Colors.amber,
                  ///     ),
                  ///   ),
                  /// );
                  /// ```
                  widgetLoader: (
                    String id, {
                    Map<String, dynamic>? meta,
                  }) {
                    switch (id) {
                      case 'my-special-container':
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.amber,
                        );

                      /// ... other widgets
                    }
                    throw ArgumentError(
                      'No widget found for the given id: $id',
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
