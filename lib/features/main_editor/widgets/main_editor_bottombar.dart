import 'dart:math';

import 'package:flutter/material.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/shared/widgets/flat_icon_text_button.dart';
import '../controllers/main_editor_controllers.dart';
import '../services/sizes_manager.dart';

class MainEditorBottombar extends StatelessWidget {
  const MainEditorBottombar({
    super.key,
    required this.controllers,
    required this.configs,
    required this.sizesManager,
    required this.bottomBarKey,
    required this.theme,
    required this.openPaintEditor,
    required this.openTextEditor,
    required this.openCropRotateEditor,
    required this.openTuneEditor,
    required this.openFilterEditor,
    required this.openBlurEditor,
    required this.openEmojiEditor,
    required this.openStickerEditor,
  });

  final MainEditorControllers controllers;
  final ProImageEditorConfigs configs;
  final SizesManager sizesManager;
  final GlobalKey<State<StatefulWidget>> bottomBarKey;
  final ThemeData theme;

  final Function() openPaintEditor;
  final Function() openTextEditor;
  final Function() openCropRotateEditor;
  final Function() openTuneEditor;
  final Function() openFilterEditor;
  final Function() openBlurEditor;
  final Function() openEmojiEditor;
  final Function() openStickerEditor;

  final double _bottomIconSize = 22.0;
  Color get _foregroundColor => configs.mainEditor.style.bottomBarColor;
  TextStyle get _bottomTextStyle => TextStyle(
        fontSize: 10.0,
        color: _foregroundColor,
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: bottomBarKey,
      child: LayoutBuilder(builder: (context, constraints) {
        return Theme(
          data: theme,
          child: Scrollbar(
            controller: controllers.bottomBarScrollCtrl,
            scrollbarOrientation: ScrollbarOrientation.top,
            thickness: isDesktop ? null : 0,
            child: BottomAppBar(
              height: kBottomNavigationBarHeight,
              color: configs.mainEditor.style.bottomBarBackground,
              padding: EdgeInsets.zero,
              child: Center(
                child: SingleChildScrollView(
                  controller: controllers.bottomBarScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: min(
                          sizesManager.lastScreenSize.width != 0
                              ? sizesManager.lastScreenSize.width
                              : constraints.maxWidth,
                          600),
                      maxWidth: 600,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: _buildEditorButtons(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Builds a list of editor action buttons dynamically
  List<Widget> _buildEditorButtons() {
    return [
      if (configs.paintEditor.enabled)
        _buildActionButton(
          key: const ValueKey('open-paint-editor-btn'),
          label: configs.i18n.paintEditor.bottomNavigationBarText,
          icon: configs.paintEditor.icons.bottomNavBar,
          onPressed: openPaintEditor,
        ),
      if (configs.textEditor.enabled)
        _buildActionButton(
          key: const ValueKey('open-text-editor-btn'),
          label: configs.i18n.textEditor.bottomNavigationBarText,
          icon: configs.textEditor.icons.bottomNavBar,
          onPressed: openTextEditor,
        ),
      if (configs.cropRotateEditor.enabled)
        _buildActionButton(
          key: const ValueKey('open-crop-rotate-editor-btn'),
          label: configs.i18n.cropRotateEditor.bottomNavigationBarText,
          icon: configs.cropRotateEditor.icons.bottomNavBar,
          onPressed: openCropRotateEditor,
        ),
      if (configs.tuneEditor.enabled)
        _buildActionButton(
          key: const ValueKey('open-tune-editor-btn'),
          label: configs.i18n.tuneEditor.bottomNavigationBarText,
          icon: configs.tuneEditor.icons.bottomNavBar,
          onPressed: openTuneEditor,
        ),
      if (configs.filterEditor.enabled)
        _buildActionButton(
          key: const ValueKey('open-filter-editor-btn'),
          label: configs.i18n.filterEditor.bottomNavigationBarText,
          icon: configs.filterEditor.icons.bottomNavBar,
          onPressed: openFilterEditor,
        ),
      if (configs.blurEditor.enabled)
        _buildActionButton(
          key: const ValueKey('open-blur-editor-btn'),
          label: configs.i18n.blurEditor.bottomNavigationBarText,
          icon: configs.blurEditor.icons.bottomNavBar,
          onPressed: openBlurEditor,
        ),
      if (configs.emojiEditor.enabled)
        _buildActionButton(
          key: const ValueKey('open-emoji-editor-btn'),
          label: configs.i18n.emojiEditor.bottomNavigationBarText,
          icon: configs.emojiEditor.icons.bottomNavBar,
          onPressed: openEmojiEditor,
        ),
      if (configs.stickerEditor.enabled)
        _buildActionButton(
          key: const ValueKey('open-sticker-editor-btn'),
          label: configs.i18n.stickerEditor.bottomNavigationBarText,
          icon: configs.stickerEditor.icons.bottomNavBar,
          onPressed: openStickerEditor,
        ),
    ];
  }

  /// Helper to build a single action button
  Widget _buildActionButton({
    required ValueKey<String> key,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return FlatIconTextButton(
      key: key,
      label: Text(label, style: _bottomTextStyle),
      icon: Icon(icon, size: _bottomIconSize, color: _foregroundColor),
      onPressed: onPressed,
    );
  }
}
