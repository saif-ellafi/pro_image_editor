import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/core/models/editor_configs/emoji_editor_configs.dart';

class MainEditorFontPreloader extends StatelessWidget {
  const MainEditorFontPreloader({
    super.key,
    required this.emojiEditorConfigs,
  });

  final EmojiEditorConfigs emojiEditorConfigs;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && emojiEditorConfigs.enablePreloadWebFont) {
      return Offstage(
        child: Text('😀', style: emojiEditorConfigs.style.textStyle),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
