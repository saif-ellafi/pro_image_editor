import 'package:flutter/material.dart';

import '/core/models/editor_configs/filter_editor_configs.dart';
import '/core/models/i18n/i18n_filter_editor.dart';

class FilterEditorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const FilterEditorAppBar({
    super.key,
    required this.filterEditorConfigs,
    required this.i18n,
    required this.close,
    required this.done,
  });
  final FilterEditorConfigs filterEditorConfigs;
  final I18nFilterEditor i18n;
  final Function() close;
  final Function() done;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: filterEditorConfigs.style.appBarBackground,
      foregroundColor: filterEditorConfigs.style.appBarColor,
      actions: [
        IconButton(
          tooltip: i18n.back,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(filterEditorConfigs.icons.backButton),
          onPressed: close,
        ),
        const Spacer(),
        IconButton(
          tooltip: i18n.done,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(filterEditorConfigs.icons.applyChanges),
          iconSize: 28,
          onPressed: done,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
