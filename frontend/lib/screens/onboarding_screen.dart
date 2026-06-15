import 'package:flutter/material.dart';

import '../widgets/onboarding/onboarding_mockups.dart';
import '../widgets/onboarding/onboarding_step.dart';
import '../widgets/onboarding/onboarding_visual_shell.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  final Future<void> Function() onComplete;

  static final _steps = [
    OnboardingStep(
      title: 'Добро пожаловать',
      body:
          'Создавайте красивые фото по шаблонам, '
          'фотосессии и свои идеи.',
      mockupBuilder: OnboardingMockups.welcomeHome,
    ),
    OnboardingStep(
      title: 'Выбирайте готовые идеи',
      body:
          'Откройте шаблон, добавьте фото — '
          'и получите готовый результат.',
      mockupBuilder: OnboardingMockups.templateCardTry,
    ),
    OnboardingStep(
      title: 'Создавайте фотосессии',
      body: 'Фотосессия создаёт 3 фото в одном стиле.',
      mockupBuilder: OnboardingMockups.photoshootTriplet,
    ),
    OnboardingStep(
      title: 'Добавляйте хорошее фото',
      body: 'Лучше всего подходят чёткие фото, где лицо хорошо видно.',
      mockupBuilder: OnboardingMockups.goodBadPhoto,
    ),
    OnboardingStep(
      title: 'Все разделы — в меню',
      body:
          'Откройте меню слева сверху, чтобы перейти в любой раздел. '
          'Кнопка «Помощь» — в правом верхнем углу.',
      mockupBuilder: OnboardingMockups.drawerMenu,
    ),
    OnboardingStep(
      title: '3 генерации бесплатно',
      body:
          'Попробуйте первые фото бесплатно. '
          'Обычное фото стоит 1 изображение, фотосессия — 3 изображения.',
      mockupBuilder: OnboardingMockups.freeBalance,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: OnboardingVisualShell(
        steps: _steps,
        presentation: OnboardingPresentation.fullscreen,
        onComplete: onComplete,
        showSkip: true,
        lastActionLabel: 'Начать',
      ),
    );
  }
}
