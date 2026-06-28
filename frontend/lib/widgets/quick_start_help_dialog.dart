import 'package:flutter/material.dart';

import '../screens/onboarding_screen.dart';
import 'paged_help_dialog.dart';

class QuickStartHelpDialog extends StatelessWidget {
  const QuickStartHelpDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const QuickStartHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PagedHelpDialog(
      blocks: OnboardingScreen.tutorialSteps,
      lastActionLabel: 'Понятно',
    );
  }
}
