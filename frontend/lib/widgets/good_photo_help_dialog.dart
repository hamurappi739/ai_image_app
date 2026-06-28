import 'package:flutter/material.dart';

import 'onboarding/onboarding_mockups.dart';
import 'paged_help_dialog.dart';

class GoodPhotoHelpDialog extends StatelessWidget {
  const GoodPhotoHelpDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const GoodPhotoHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PagedHelpDialog(
      blocks: [
        OnboardingStep(
          title: 'Добавляйте хорошее фото',
          body: 'Лучше всего подходят чёткие фото, где лицо хорошо видно.',
          mockupBuilder: OnboardingMockups.goodBadPhoto,
        ),
      ],
    );
  }
}
