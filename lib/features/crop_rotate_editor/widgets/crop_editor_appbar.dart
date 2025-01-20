import 'package:flutter/material.dart';

import '../../../core/models/editor_configs/crop_rotate_editor_configs.dart';
import '../../../core/models/i18n/i18n_crop_rotate_editor.dart';

class CropEditorAppbar extends StatelessWidget implements PreferredSizeWidget {
  const CropEditorAppbar({
    super.key,
    required this.configs,
    required this.i18n,
    required this.enableCloseButton,
    required this.canUndo,
    required this.canRedo,
    required this.onDone,
    required this.onClose,
    required this.onUndo,
    required this.onRedo,
  });

  final CropRotateEditorConfigs configs;
  final I18nCropRotateEditor i18n;

  final bool enableCloseButton;
  final bool canUndo;
  final bool canRedo;

  final Function() onDone;
  final Function() onClose;
  final Function() onUndo;
  final Function() onRedo;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: configs.style.appBarBackground,
      foregroundColor: configs.style.appBarColor,
      actions: [
        if (enableCloseButton)
          IconButton(
            tooltip: i18n.back,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            icon: Icon(configs.icons.backButton),
            onPressed: onClose,
          ),
        const Spacer(),
        IconButton(
          tooltip: i18n.undo,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(
            configs.icons.undoAction,
            color: canUndo ? Colors.white : Colors.white.withAlpha(80),
          ),
          onPressed: onUndo,
        ),
        IconButton(
          tooltip: i18n.redo,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(
            configs.icons.redoAction,
            color: canRedo ? Colors.white : Colors.white.withAlpha(80),
          ),
          onPressed: onRedo,
        ),
        _buildDoneBtn(),
      ],
    );
  }

  /// Builds and returns an IconButton for applying changes.
  Widget _buildDoneBtn() {
    return IconButton(
      tooltip: i18n.done,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      icon: Icon(configs.icons.applyChanges),
      iconSize: 28,
      onPressed: onDone,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
