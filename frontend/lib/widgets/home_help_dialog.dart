import 'package:flutter/material.dart';

import 'paged_help_dialog.dart';
import 'ui_preview_placeholders.dart';

class HomeHelpDialog extends StatelessWidget {
  const HomeHelpDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const HomeHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PagedHelpDialog(
      blocks: [
        PagedHelpBlock(
          title: 'Меню слева сверху',
          body:
              'Все разделы приложения — в меню слева сверху: '
              'шаблоны, фотосессии, своя идея, готовые фото, '
              'раздел «Купить» и профиль.',
          previewBuilder: ({required compact}) =>
              HelpDrawerMenuPreview(compact: compact),
        ),
        PagedHelpBlock(
          title: 'Начните с шаблона',
          body:
              'Кнопка «Начать создавать» на главной '
              'открывает «Фото по шаблону» — самый простой старт.',
          previewBuilder: ({required compact}) =>
              HelpStartCreatingPreview(compact: compact),
        ),
      ],
    );
  }
}
