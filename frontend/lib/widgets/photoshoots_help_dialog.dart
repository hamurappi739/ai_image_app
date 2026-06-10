import 'package:flutter/material.dart';

import 'paged_help_dialog.dart';
import 'ui_preview_placeholders.dart';

class PhotoshootsHelpDialog extends StatelessWidget {
  const PhotoshootsHelpDialog({
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
          title: 'Выберите стиль',
          body: 'Нажмите на карточку с понравившимся образом.',
          previewBuilder: _stylePreview,
        ),
        PagedHelpBlock(
          title: 'Фотосессия создаёт 3 фото',
          body: 'Вы получите серию из трёх фото в одном стиле.',
          previewBuilder: _tripletPreview,
        ),
        PagedHelpBlock(
          title: 'Загрузите своё фото',
          body: 'Добавьте фото из галереи. Лицо должно быть хорошо видно.',
          previewBuilder: _photoPreview,
        ),
        PagedHelpBlock(
          title: 'Создайте свой образ',
          body:
              'Если не нашли подходящий стиль, '
              'нажмите «Создать свой образ» вверху экрана.',
          previewBuilder: _customStylePreview,
        ),
        PagedHelpBlock(
          title: 'Где смотреть результат',
          body: 'Готовая фотосессия появится в «Готовые фото».',
          previewBuilder: _galleryPreview,
        ),
      ],
    );
  }

  static Widget _stylePreview({required bool compact}) =>
      HelpTemplatePreview(compact: compact);

  static Widget _tripletPreview({required bool compact}) =>
      HelpPhotoshootTripletPreview(compact: compact);

  static Widget _photoPreview({required bool compact}) =>
      HelpPhotoUploadPreview(compact: compact);

  static Widget _customStylePreview({required bool compact}) =>
      HelpCustomStyleBannerPreview(compact: compact);

  static Widget _galleryPreview({required bool compact}) =>
      HelpGalleryPreview(compact: compact);
}
