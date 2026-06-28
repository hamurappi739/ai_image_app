import 'package:flutter/material.dart';

import 'onboarding/onboarding_mockups.dart';
import 'paged_help_dialog.dart';

class GalleryHelpDialog extends StatelessWidget {
  const GalleryHelpDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const GalleryHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PagedHelpDialog(
      blocks: [
        OnboardingStep(
          title: 'Готовые фото',
          body:
              'Здесь сохраняются созданные фото и фотосессии. '
              'Одиночные фото и серии по 3 фото отображаются отдельно.',
          mockupBuilder: OnboardingMockups.photoshootGallery,
        ),
        OnboardingStep(
          title: 'Откройте и скачайте',
          body:
              'Нажмите «Открыть», чтобы посмотреть фото крупнее '
              'и сохранить его на устройство.',
          mockupBuilder: OnboardingMockups.templateResult,
        ),
        OnboardingStep(
          title: 'Удаление из галереи',
          body:
              'Кнопка «Удалить из галереи» убирает фото или фотосессию '
              'только из галереи приложения на этом устройстве.',
          mockupBuilder: OnboardingMockups.photoshootGallery,
        ),
      ],
    );
  }
}
