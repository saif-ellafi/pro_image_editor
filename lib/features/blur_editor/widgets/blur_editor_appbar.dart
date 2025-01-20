import 'package:flutter/material.dart';
import '/core/models/editor_configs/blur_editor_configs.dart';
import '/core/models/i18n/i18n_blur_editor.dart';

class BlurEditorAppBar extends StatelessWidget implements PreferredSizeWidget {

  const BlurEditorAppBar({
    super.key,
    required this.blurEditorConfigs,
    required this.i18n,
    required this.close,
    required this.done,
  });
  final BlurEditorConfigs blurEditorConfigs;
  final I18nBlurEditor i18n;
  final Function() close;
  final Function() done;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: blurEditorConfigs.style.appBarBackgroundColor,
      foregroundColor: blurEditorConfigs.style.appBarForegroundColor,
      actions: [
        IconButton(
          tooltip: i18n.back,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(blurEditorConfigs.icons.backButton),
          onPressed: close,
        ),
        const Spacer(),
        IconButton(
          tooltip: i18n.done,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(blurEditorConfigs.icons.applyChanges),
          iconSize: 28,
          onPressed: done,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
