import 'package:flutter/material.dart';

import 'onboarding/onboarding_mockups.dart';
import 'paged_help_dialog.dart';

class TemplateHelpDialog extends StatelessWidget {
  const TemplateHelpDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const TemplateHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PagedHelpDialog(
      blocks: [
        OnboardingStep(
          title: 'Выберите категорию',
          body: 'Сверху выберите категорию — ниже появятся подходящие шаблоны.',
          mockupBuilder: OnboardingMockups.templateCategories,
        ),
        OnboardingStep(
          title: 'Откройте шаблон',
          body: 'Нажмите «Попробовать» на карточке, которая вам нравится.',
          mockupBuilder: OnboardingMockups.templateOpen,
        ),
        OnboardingStep(
          title: 'Добавьте фото',
          body: 'Выберите фото на устройстве. Лицо должно быть хорошо видно.',
          mockupBuilder: OnboardingMockups.templateAddPhoto,
        ),
        OnboardingStep(
          title: 'Получите результат',
          body: 'Готовое фото сохранится в разделе «Готовые фото».',
          mockupBuilder: OnboardingMockups.templateResult,
        ),
      ],
    );
  }
}
