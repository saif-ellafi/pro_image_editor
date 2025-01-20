import 'package:flutter/material.dart';

import '/core/models/editor_configs/layer_interaction_configs.dart';
import '/core/models/editor_configs/main_editor_configs.dart';
import '../controllers/main_editor_controllers.dart';
import '../main_editor.dart';
import '../services/layer_interaction_manager.dart';

class MainEditorRemoveLayerArea extends StatelessWidget {
  const MainEditorRemoveLayerArea({
    super.key,
    required this.layerInteraction,
    required this.layerInteractionManager,
    required this.mainEditorConfigs,
    required this.state,
    required this.controllers,
    required this.removeAreaKey,
  });

  final LayerInteractionConfigs layerInteraction;
  final LayerInteractionManager layerInteractionManager;
  final MainEditorConfigs mainEditorConfigs;
  final MainEditorControllers controllers;
  final GlobalKey<State<StatefulWidget>> removeAreaKey;
  final ProImageEditorState state;

  @override
  Widget build(BuildContext context) {
    return mainEditorConfigs.widgets.removeLayerArea?.call(
          removeAreaKey,
          state,
          controllers.removeBtnCtrl.stream,
        ) ??
        Positioned(
          key: removeAreaKey,
          top: 0,
          left: 0,
          child: SafeArea(
            bottom: false,
            child: StreamBuilder(
                stream: controllers.removeBtnCtrl.stream,
                builder: (context, snapshot) {
                  return Container(
                    height: kToolbarHeight,
                    width: kToolbarHeight,
                    decoration: BoxDecoration(
                      color: layerInteractionManager.hoverRemoveBtn
                          ? layerInteraction.style.removeAreaBackgroundActive
                          : layerInteraction.style.removeAreaBackgroundInactive,
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(100)),
                    ),
                    padding: const EdgeInsets.only(right: 12, bottom: 7),
                    child: Center(
                      child: Icon(
                        mainEditorConfigs.icons.removeElementZone,
                        size: 28,
                      ),
                    ),
                  );
                }),
          ),
        );
  }
}
