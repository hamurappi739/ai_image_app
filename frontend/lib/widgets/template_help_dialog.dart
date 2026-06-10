import 'package:flutter/material.dart';

import 'paged_help_dialog.dart';
import 'ui_preview_placeholders.dart';

class TemplateHelpDialog extends StatelessWidget {
  const TemplateHelpDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const TemplateHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const PagedHelpDialog(
      blocks: [
        PagedHelpBlock(
          title: 'Выберите подходящий шаблон',
          body: 'Нажмите «Выбрать» на карточке, которая вам нравится.',
          previewBuilder: _templatePreview,
        ),
        PagedHelpBlock(
          title: 'Описание подставится автоматически',
          body:
              'Приложение само заполнит текст — '
              'ничего писать с нуля не нужно.',
          previewBuilder: _descriptionPreview,
        ),
        PagedHelpBlock(
          title: 'Потом добавьте своё фото',
          body: 'Выберите фото из галереи телефона. Лицо должно быть хорошо видно.',
          previewBuilder: _photoPreview,
        ),
        PagedHelpBlock(
          title: 'Нажмите «Создать фото»',
          body: 'Обычно ждать 20–60 секунд. Результат появится в «Готовые фото».',
          previewBuilder: _createPreview,
        ),
      ],
    );
  }

  static Widget _templatePreview({required bool compact}) =>
      HelpTemplatePreview(compact: compact);

  static Widget _descriptionPreview({required bool compact}) =>
      HelpDescriptionPreview(compact: compact);

  static Widget _photoPreview({required bool compact}) =>
      HelpPhotoUploadPreview(compact: compact);

  static Widget _createPreview({required bool compact}) =>
      HelpCreateButtonPreview(compact: compact);
}
