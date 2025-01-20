import 'package:flutter/material.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/shared/widgets/platform/platform_popup_menu.dart';

class PaintEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PaintEditorAppBar({
    super.key,
    required this.paintEditorConfigs,
    required this.i18n,
    required this.constraints,
    required this.onTapMenuFill,
    required this.onUndo,
    required this.onRedo,
    required this.onToggleFill,
    required this.onDone,
    required this.onClose,
    required this.canUndo,
    required this.canRedo,
    required this.onOpenOpacityBottomSheet,
    required this.onOpenLineWeightBottomSheet,
    required this.isFillMode,
    required this.designMode,
  });
  final PaintEditorConfigs paintEditorConfigs;
  final I18nPaintEditor i18n;
  final BoxConstraints constraints;
  final ImageEditorDesignMode designMode;

  final bool canUndo;
  final bool canRedo;
  final bool isFillMode;

  final Function() onTapMenuFill;
  final Function() onUndo;
  final Function() onRedo;
  final Function() onToggleFill;
  final Function() onDone;
  final Function() onClose;
  final Function() onOpenOpacityBottomSheet;
  final Function() onOpenLineWeightBottomSheet;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: paintEditorConfigs.style.appBarBackground,
      foregroundColor: paintEditorConfigs.style.appBarColor,
      actions: _buildAction(constraints),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// Builds an action bar depending on the allowed space
  List<Widget> _buildAction(BoxConstraints constraints) {
    const int defaultIconButtonSize = 48;
    final List<Widget> configButtons = _getConfigButtons();
    final List<Widget> actionButtons = _getActionButtons();

    // Taking into account the back button
    final expandedIconButtonsSize =
        (1 + configButtons.length + actionButtons.length) *
            defaultIconButtonSize;

    return [
      IconButton(
        tooltip: i18n.back,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        icon: Icon(paintEditorConfigs.icons.backButton),
        onPressed: onClose,
      ),
      const Spacer(),
      ...[
        if (constraints.maxWidth >= expandedIconButtonsSize) ...[
          ...configButtons,
          if (constraints.maxWidth >= 640) const Spacer(),
          ...actionButtons,
        ] else ...[
          ..._buildShortActionBar(
            constraints,
            actionButtons,
            defaultIconButtonSize,
          ),
        ],
      ],
    ];
  }

  /// Builds an action bar with limited number of quick actions
  List<Widget> _buildShortActionBar(
    BoxConstraints constraints,
    List<Widget> actionButtons,
    int defaultIconButtonSize,
  ) {
    final shrunkIconButtonsSize =
        (1 + actionButtons.length) * defaultIconButtonSize;
    final bool hasEnoughSpace = constraints.maxWidth >= shrunkIconButtonsSize;

    return [
      if (hasEnoughSpace) ...[
        ...actionButtons,
      ] else ...[
        _buildDoneBtn(),
      ],
      PlatformPopupBtn(
        designMode: designMode,
        title: i18n.smallScreenMoreTooltip,
        options: [
          if (paintEditorConfigs.canChangeLineWidth)
            PopupMenuOption(
              label: i18n.lineWidth,
              icon: Icon(
                paintEditorConfigs.icons.lineWeight,
              ),
              onTap: onOpenLineWeightBottomSheet,
            ),
          if (paintEditorConfigs.canToggleFill)
            PopupMenuOption(
              label: i18n.toggleFill,
              icon: Icon(
                !isFillMode
                    ? paintEditorConfigs.icons.noFill
                    : paintEditorConfigs.icons.fill,
              ),
              onTap: onTapMenuFill,
            ),
          if (paintEditorConfigs.canChangeOpacity)
            PopupMenuOption(
              label: i18n.changeOpacity,
              icon: Icon(
                paintEditorConfigs.icons.changeOpacity,
              ),
              onTap: onOpenOpacityBottomSheet,
            ),
          if (!hasEnoughSpace) ...[
            if (canUndo)
              PopupMenuOption(
                label: i18n.undo,
                icon: Icon(
                  paintEditorConfigs.icons.undoAction,
                ),
                onTap: onUndo,
              ),
            if (canRedo)
              PopupMenuOption(
                label: i18n.redo,
                icon: Icon(
                  paintEditorConfigs.icons.redoAction,
                ),
                onTap: onRedo,
              ),
          ]
        ],
      )
    ];
  }

  /// Builds and returns a list of IconButton to change the line width /
  /// toggle fill or un-fill / change the opacity.
  List<Widget> _getConfigButtons() => [
        if (paintEditorConfigs.canChangeLineWidth)
          IconButton(
            tooltip: i18n.lineWidth,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            icon: Icon(
              paintEditorConfigs.icons.lineWeight,
              color: Colors.white,
            ),
            onPressed: onOpenLineWeightBottomSheet,
          ),
        if (paintEditorConfigs.canToggleFill)
          IconButton(
            tooltip: i18n.toggleFill,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            icon: Icon(
              !isFillMode
                  ? paintEditorConfigs.icons.noFill
                  : paintEditorConfigs.icons.fill,
              color: Colors.white,
            ),
            onPressed: onToggleFill,
          ),
        if (paintEditorConfigs.canChangeOpacity)
          IconButton(
            tooltip: i18n.changeOpacity,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            icon: Icon(
              paintEditorConfigs.icons.changeOpacity,
              color: Colors.white,
            ),
            onPressed: onOpenOpacityBottomSheet,
          ),
      ];

  /// Builds and returns a list of IconButton to undo / redo / apply changes.
  List<Widget> _getActionButtons() => [
        IconButton(
          tooltip: i18n.undo,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(
            paintEditorConfigs.icons.undoAction,
            color: canUndo ? Colors.white : Colors.white.withAlpha(80),
          ),
          onPressed: onUndo,
        ),
        IconButton(
          tooltip: i18n.redo,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(
            paintEditorConfigs.icons.redoAction,
            color: canRedo ? Colors.white : Colors.white.withAlpha(80),
          ),
          onPressed: onRedo,
        ),
        _buildDoneBtn(),
      ];

  /// Builds and returns an IconButton for applying changes.
  Widget _buildDoneBtn() {
    return IconButton(
      tooltip: i18n.done,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      icon: Icon(paintEditorConfigs.icons.applyChanges),
      iconSize: 28,
      onPressed: onDone,
    );
  }
}
