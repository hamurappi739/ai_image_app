import 'package:flutter/material.dart';

import '../screens/onboarding_screen.dart';
import 'paged_help_dialog.dart';

/// Help dialog with the first-run welcome showcase (read-only, no onboarding flag).
class WelcomeShowcaseHelpDialog extends StatelessWidget {
  const WelcomeShowcaseHelpDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const WelcomeShowcaseHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PagedHelpDialog(
      blocks: [OnboardingScreen.welcomeStep],
      lastActionLabel: 'Понятно',
    );
  }
}
