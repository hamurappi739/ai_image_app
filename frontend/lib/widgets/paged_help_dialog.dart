import 'package:flutter/material.dart';

import 'onboarding/onboarding_step.dart';
import 'onboarding/onboarding_visual_shell.dart';

export 'onboarding/onboarding_step.dart' show OnboardingStep, PagedHelpBlock;

/// Paged section help — visual shell in a large dialog.
class PagedHelpDialog extends StatelessWidget {
  const PagedHelpDialog({
    super.key,
    required this.blocks,
    this.onDismissed,
    this.lastActionLabel = 'Понятно',
  });

  final List<OnboardingStep> blocks;
  final Future<void> Function()? onDismissed;
  final String lastActionLabel;

  @override
  Widget build(BuildContext context) {
    return OnboardingVisualShell(
      steps: blocks,
      presentation: OnboardingPresentation.dialog,
      onComplete: onDismissed,
      lastActionLabel: lastActionLabel,
      dialogTitle: 'Помощь',
    );
  }
}
