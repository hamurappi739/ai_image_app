import 'package:flutter/material.dart';

import 'ui_preview_placeholders.dart';

class CreateResultTipsCard extends StatelessWidget {
  const CreateResultTipsCard({super.key});

  static const _accentColor = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: _accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Как получить хороший результат',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Посмотрите на примеры ниже — так проще понять, '
                      'что помогает, а что мешает.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.35,
                        color: UiPreviewPlaceholders.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;

              const good = PhotoQualityExampleCard(
                title: 'Хорошее фото',
                photoHint: 'Лицо хорошо видно, свет ровный, фото не размыто.',
                descriptionExampleLabel: 'Пример хорошего описания',
                descriptionExample: 'Сделай деловой портрет на светлом фоне.',
                gradientColors: [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
                icon: Icons.face_retouching_natural_outlined,
                isGood: true,
              );

              const bad = PhotoQualityExampleCard(
                title: 'Плохое фото',
                photoHint: 'Фото тёмное, лицо далеко или закрыто.',
                descriptionExampleLabel: 'Пример плохого описания',
                descriptionExample: 'Сделай красиво.',
                gradientColors: [Color(0xFF3A3F4B), Color(0xFF6B7280)],
                icon: Icons.face_outlined,
                isGood: false,
              );

              if (wide) {
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: good),
                    SizedBox(width: 16),
                    Expanded(child: bad),
                  ],
                );
              }

              return const Column(
                children: [
                  good,
                  SizedBox(height: 16),
                  bad,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
