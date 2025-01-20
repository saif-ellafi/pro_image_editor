import 'package:flutter/material.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/shared/widgets/platform/platform_circular_progress_indicator.dart';
import '../services/state_manager.dart';

class MainEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainEditorAppBar({
    super.key,
    required this.i18n,
    required this.configs,
    required this.closeEditor,
    required this.undoAction,
    required this.redoAction,
    required this.doneEditing,
    required this.isInitialized,
    required this.stateManager,
  });

  final bool isInitialized;
  final I18n i18n;
  final ProImageEditorConfigs configs;
  final Function() closeEditor;
  final Function() undoAction;
  final Function() redoAction;
  final Function() doneEditing;

  Color get foregroundColor => mainEditorConfigs.style.appBarColor;
  MainEditorConfigs get mainEditorConfigs => configs.mainEditor;
  final StateManager stateManager;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      foregroundColor: foregroundColor,
      backgroundColor: mainEditorConfigs.style.appBarBackground,
      leading: mainEditorConfigs.enableCloseButton
          ? IconButton(
              tooltip: i18n.cancel,
              icon: Icon(mainEditorConfigs.icons.closeEditor),
              onPressed: closeEditor,
            )
          : null,
      actions: [
        IconButton(
          key: const ValueKey('MainEditorUndoButton'),
          tooltip: i18n.undo,
          icon: Icon(
            mainEditorConfigs.icons.undoAction,
            color: stateManager.canUndo
                ? foregroundColor
                : foregroundColor.withAlpha(80),
          ),
          onPressed: undoAction,
        ),
        IconButton(
          key: const ValueKey('MainEditorRedoButton'),
          tooltip: i18n.redo,
          icon: Icon(
            mainEditorConfigs.icons.redoAction,
            color: stateManager.canRedo
                ? foregroundColor
                : foregroundColor.withAlpha(80),
          ),
          onPressed: redoAction,
        ),
        !isInitialized
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: SizedBox.square(
                  dimension: 24,
                  child: PlatformCircularProgressIndicator(configs: configs),
                ),
              )
            : IconButton(
                key: const ValueKey('MainEditorDoneButton'),
                tooltip: i18n.done,
                icon: Icon(mainEditorConfigs.icons.doneIcon),
                iconSize: 28,
                onPressed: doneEditing,
              ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
