import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/core/models/editor_configs/pro_image_editor_configs.dart';
import 'package:pro_image_editor/shared/widgets/flat_icon_text_button.dart';

class CropEditorBottombar extends StatelessWidget {
  const CropEditorBottombar({
    super.key,
    required this.bottomBarScrollCtrl,
    required this.i18n,
    required this.configs,
    required this.theme,
    required this.onRotate,
    required this.onFlip,
    required this.onOpenAspectRatioOptions,
    required this.onReset,
  });

  final ScrollController bottomBarScrollCtrl;
  final I18nCropRotateEditor i18n;
  final CropRotateEditorConfigs configs;
  final ThemeData theme;

  final Function() onRotate;
  final Function() onFlip;
  final Function() onOpenAspectRatioOptions;
  final Function() onReset;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Scrollbar(
        controller: bottomBarScrollCtrl,
        scrollbarOrientation: ScrollbarOrientation.top,
        thickness: isDesktop ? null : 0,
        child: BottomAppBar(
          height: kToolbarHeight,
          color: configs.style.bottomBarBackground,
          padding: EdgeInsets.zero,
          child: Center(
            child: SingleChildScrollView(
              controller: bottomBarScrollCtrl,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: min(MediaQuery.of(context).size.width, 500),
                  maxWidth: 500,
                ),
                child: Builder(builder: (context) {
                  Color foregroundColor = configs.style.appBarColor;
                  return Wrap(
                    direction: Axis.horizontal,
                    alignment: WrapAlignment.spaceAround,
                    children: <Widget>[
                      if (configs.canRotate)
                        FlatIconTextButton(
                          key: const ValueKey('crop-rotate-editor-rotate-btn'),
                          label: Text(
                            i18n.rotate,
                            style: TextStyle(
                                fontSize: 10.0, color: foregroundColor),
                          ),
                          icon: Icon(configs.icons.rotate,
                              color: foregroundColor),
                          onPressed: onRotate,
                        ),
                      if (configs.canFlip)
                        FlatIconTextButton(
                          key: const ValueKey('crop-rotate-editor-flip-btn'),
                          label: Text(
                            i18n.flip,
                            style: TextStyle(
                                fontSize: 10.0, color: foregroundColor),
                          ),
                          icon:
                              Icon(configs.icons.flip, color: foregroundColor),
                          onPressed: onFlip,
                        ),
                      if (configs.canChangeAspectRatio)
                        FlatIconTextButton(
                          key: const ValueKey('crop-rotate-editor-ratio-btn'),
                          label: Text(
                            i18n.ratio,
                            style: TextStyle(
                                fontSize: 10.0, color: foregroundColor),
                          ),
                          icon: Icon(configs.icons.aspectRatio,
                              color: foregroundColor),
                          onPressed: onOpenAspectRatioOptions,
                        ),
                      if (configs.canReset)
                        FlatIconTextButton(
                          key: const ValueKey('crop-rotate-editor-reset-btn'),
                          label: Text(
                            i18n.reset,
                            style: TextStyle(
                                fontSize: 10.0, color: foregroundColor),
                          ),
                          icon:
                              Icon(configs.icons.reset, color: foregroundColor),
                          onPressed: onReset,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
