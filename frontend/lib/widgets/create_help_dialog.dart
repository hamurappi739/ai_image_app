import 'package:flutter/material.dart';

import 'paged_help_dialog.dart';
import 'ui_preview_placeholders.dart';

class CreateHelpDialog extends StatelessWidget {
  const CreateHelpDialog({
    super.key,
    this.onDismissed,
  });

  final Future<void> Function()? onDismissed;

  @override
  Widget build(BuildContext context) {
    return PagedHelpDialog(
      onDismissed: onDismissed,
      blocks: const [
        PagedHelpBlock(
          title: 'Это режим для своей идеи',
          body:
              'Здесь вы сами описываете результат. '
              'Если не знаете, что написать — начните с «Фото по шаблону».',
          previewBuilder: _customModePreview,
        ),
        PagedHelpBlock(
          title: 'Сначала добавьте фото',
          body: 'Выберите своё фото. Лицо должно быть хорошо видно.',
          previewBuilder: _photoPreview,
        ),
        PagedHelpBlock(
          title: 'Потом напишите описание',
          body: 'Коротко опишите, какой результат хотите получить.',
          previewBuilder: _descriptionPreview,
        ),
        PagedHelpBlock(
          title: 'Чем понятнее — тем лучше',
          body:
              'Чем понятнее описание и фото, '
              'тем лучше результат.',
          previewBuilder: _qualityPreview,
        ),
        PagedHelpBlock(
          title: 'Нажмите «Создать фото»',
          body: 'Готовое фото появится в разделе «Готовые фото».',
          previewBuilder: _createPreview,
        ),
      ],
    );
  }

  static Widget _customModePreview({required bool compact}) =>
      HelpWelcomePreview(compact: compact);

  static Widget _photoPreview({required bool compact}) =>
      HelpPhotoUploadPreview(compact: compact);

  static Widget _descriptionPreview({required bool compact}) =>
      HelpDescriptionPreview(compact: compact);

  static Widget _qualityPreview({required bool compact}) {
    return PhotoQualityExampleCard(
      title: 'Хороший пример',
      photoHint: 'Чёткое фото, лицо хорошо видно',
      descriptionExampleLabel: 'Описание',
      descriptionExample: 'Сделай деловой портрет на светлом фоне',
      gradientColors: const [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
      icon: Icons.face_retouching_natural_outlined,
      isGood: true,
    );
  }

  static Widget _createPreview({required bool compact}) =>
      HelpCreateButtonPreview(compact: compact);
}
