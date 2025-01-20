import 'package:flutter/material.dart';

import '/core/models/editor_configs/tune_editor_configs.dart';
import '/core/models/i18n/i18n_tune_editor.dart';

class TuneEditorAppbar extends StatelessWidget implements PreferredSizeWidget {
  const TuneEditorAppbar({
    super.key,
    required this.tuneEditorConfigs,
    required this.i18n,
    required this.canRedo,
    required this.canUndo,
    required this.onRedo,
    required this.onUndo,
    required this.onClose,
    required this.onDone,
  });

  final TuneEditorConfigs tuneEditorConfigs;
  final I18nTuneEditor i18n;

  final bool canRedo;
  final bool canUndo;

  final Function() onRedo;
  final Function() onUndo;
  final Function() onClose;
  final Function() onDone;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: tuneEditorConfigs.style.appBarBackground,
      foregroundColor: tuneEditorConfigs.style.appBarColor,
      actions: [
        IconButton(
          tooltip: i18n.back,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(tuneEditorConfigs.icons.backButton),
          onPressed: onClose,
        ),
        const Spacer(),
        IconButton(
          tooltip: i18n.undo,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(
            tuneEditorConfigs.icons.undoAction,
            color: canUndo ? Colors.white : Colors.white.withAlpha(80),
          ),
          onPressed: canUndo ? onUndo : null,
        ),
        IconButton(
          tooltip: i18n.redo,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(
            tuneEditorConfigs.icons.redoAction,
            color: canRedo ? Colors.white : Colors.white.withAlpha(80),
          ),
          onPressed: canRedo ? onRedo : null,
        ),
        IconButton(
          tooltip: i18n.done,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(tuneEditorConfigs.icons.applyChanges),
          iconSize: 28,
          onPressed: onDone,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
