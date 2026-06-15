import 'package:flutter/material.dart';

/// One step in visual onboarding or section help.
class OnboardingStep {
  OnboardingStep({
    required this.title,
    required this.body,
    Widget Function({required bool compact})? mockupBuilder,
    Widget Function({required bool compact})? previewBuilder,
  }) : mockupBuilder = mockupBuilder ?? previewBuilder!;

  final String title;
  final String body;
  final Widget Function({required bool compact}) mockupBuilder;
}

/// Legacy alias for section help dialogs.
typedef PagedHelpBlock = OnboardingStep;
