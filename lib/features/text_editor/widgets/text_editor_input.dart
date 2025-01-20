import 'package:flutter/material.dart';

import '/core/models/editor_callbacks/text_editor_callbacks.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/layers/layer.dart';
import '/plugins/rounded_background_text/src/rounded_background_text_field.dart';

class TextEditorInput extends StatelessWidget {
  const TextEditorInput({
    super.key,
    required this.callbacks,
    required this.configs,
    required this.heroTag,
    required this.focusNode,
    required this.i18n,
    required this.selectedTextStyle,
    required this.align,
    required this.textFontSize,
    required this.textColor,
    required this.backgroundColor,
    required this.layer,
    required this.textCtrl,
  });

  final TextEditorCallbacks? callbacks;
  final TextEditorConfigs configs;
  final I18nTextEditor i18n;
  final String? heroTag;

  final TextStyle selectedTextStyle;
  final TextAlign align;
  final double textFontSize;
  final Color textColor;
  final Color backgroundColor;

  final TextLayer? layer;

  final FocusNode focusNode;
  final TextEditingController textCtrl;

  Widget _flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    if (flightDirection == HeroFlightDirection.pop) {
      return fromHeroContext.widget;
    }

    void animationStatusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });
        animation.removeStatusListener(animationStatusListener);
      }
    }

    animation.addStatusListener(animationStatusListener);

    return toHeroContext.widget;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      ///  TODO: remove `IntrinsicWidth` after improve
      /// `RoundedBackgroundTextField` code
      child: IntrinsicWidth(
        child: Padding(
          padding: configs.style.textFieldMargin,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Hero(
                flightShuttleBuilder: _flightShuttleBuilder,
                tag: heroTag ?? 'Text-Image-Editor-Empty-Hero',
                createRectTween: (begin, end) =>
                    RectTween(begin: begin, end: end),
                child: _buildInputField(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return RoundedBackgroundTextField(
      key: const ValueKey('rounded-background-text-editor-field'),
      controller: textCtrl,
      focusNode: focusNode,
      onChanged: callbacks?.handleChanged,
      onEditingComplete: callbacks?.handleEditingComplete,
      onSubmitted: callbacks?.handleSubmitted,
      autocorrect: configs.autocorrect,
      enableSuggestions: configs.enableSuggestions,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      textAlign: textCtrl.text.isEmpty ? TextAlign.center : align,
      maxLines: null,
      cursorColor: configs.style.inputCursorColor,
      cursorHeight: textFontSize * 1.2,
      scrollPhysics: const NeverScrollableScrollPhysics(),
      hint: textCtrl.text.isEmpty ? i18n.inputHintText : '',
      hintStyle: selectedTextStyle.copyWith(
        color: configs.style.inputHintColor,
        fontSize: textFontSize,
        height: 1.35,
        shadows: [],
      ),
      backgroundColor: backgroundColor,
      style: selectedTextStyle.copyWith(
        color: textColor,
        fontSize: textFontSize,
        height: 1.35,
        letterSpacing: 0,
        decoration: TextDecoration.none,
        shadows: [],
      ),

      /// If we edit an layer we focus to the textfield after the
      /// hero animation is done
      autofocus: layer == null,
    );
  }
}
