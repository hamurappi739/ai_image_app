import 'package:flutter/material.dart';

import 'onboarding/onboarding_mockups.dart';
import 'paged_help_dialog.dart';

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
      blocks: [
        OnboardingStep(
          title: 'Выберите стиль',
          body: 'Выберите категорию и нажмите на понравившуюся фотосессию.',
          mockupBuilder: OnboardingMockups.photoshootStylePick,
        ),
        OnboardingStep(
          title: 'Фотосессия = 3 фото',
          body: 'Вы получите серию из трёх фото в одном стиле.',
          mockupBuilder: OnboardingMockups.photoshootThreeResults,
        ),
        OnboardingStep(
          title: 'Добавьте фото',
          body: 'Загрузите своё фото — лицо должно быть хорошо видно.',
          mockupBuilder: OnboardingMockups.photoshootAddPhoto,
        ),
        OnboardingStep(
          title: 'Смотрите готовые фото',
          body: 'Готовая фотосессия появится в разделе «Готовые фото».',
          mockupBuilder: OnboardingMockups.photoshootGallery,
        ),
      ],
    );
  }
}
