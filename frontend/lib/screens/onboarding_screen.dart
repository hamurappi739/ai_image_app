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

  static final welcomeStep = OnboardingStep(
    title: 'Ваши фото — в красивые образы',
    body:
        'Выберите шаблон, загрузите фото — и получите портрет, '
        'фотосессию или свою идею за пару минут.',
    mockupBuilder: OnboardingMockups.welcomeShowcase,
  );

  static final _steps = [
    welcomeStep,
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
      // TODO: link this note to the full privacy policy in Profile.
      footerNote:
          'Мы используем загруженные фото только для создания результата. '
          'Полная политика конфиденциальности находится в разделе «Профиль».',
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
