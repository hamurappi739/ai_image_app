import 'package:flutter/material.dart';

import 'visual_placeholder.dart';

/// Shared visual placeholders for help slides and tips (no real images).
class UiPreviewPlaceholders {
  UiPreviewPlaceholders._();

  static const accent = Color(0xFF5B6CFF);
  static const textPrimary = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF6B7280);

  static VisualPlaceholderMood _moodForIcon(IconData icon) {
    if (icon == Icons.business_center_outlined ||
        icon == Icons.badge_outlined ||
        icon == Icons.school_outlined) {
      return VisualPlaceholderMood.business;
    }
    if (icon == Icons.inventory_2_outlined ||
        icon == Icons.checkroom_outlined) {
      return VisualPlaceholderMood.product;
    }
    if (icon == Icons.family_restroom_outlined ||
        icon == Icons.child_care_outlined) {
      return VisualPlaceholderMood.family;
    }
    if (icon == Icons.photo_camera_outlined) {
      return VisualPlaceholderMood.photoshoot;
    }
    return VisualPlaceholderMood.portrait;
  }

  static Widget framedPreview({
    required List<Color> gradientColors,
    required IconData icon,
    String? badge,
    bool dimmed = false,
    double height = 96,
    VisualPlaceholderMood? mood,
  }) {
    final resolvedMood = mood ?? _moodForIcon(icon);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: VisualPlaceholder(
        mood: resolvedMood,
        height: height,
        gradientColors: gradientColors,
        icon: icon,
        caption: badge,
        showBadges: true,
        borderRadius: BorderRadius.circular(14),
        compact: height < 84,
        dimmed: dimmed,
      ),
    );
  }

  static Widget helpShell({
    required String label,
    required Widget child,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          child,
        ],
      ),
    );
  }
}

class HelpFreeStartPreview extends StatelessWidget {
  const HelpFreeStartPreview({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return UiPreviewPlaceholders.helpShell(
      compact: compact,
      label: 'Можно попробовать бесплатно',
      child: Row(
        children: [
          Container(
            width: compact ? 44 : 52,
            height: compact ? 44 : 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3 бесплатных фото',
                  style: TextStyle(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: UiPreviewPlaceholders.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'чтобы познакомиться с приложением',
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    color: UiPreviewPlaceholders.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HelpTemplatePreview extends StatelessWidget {
  const HelpTemplatePreview({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return UiPreviewPlaceholders.helpShell(
      compact: compact,
      label: 'Раздел «Фото по шаблону»',
      child: Row(
        children: [
          Expanded(
            child: UiPreviewPlaceholders.framedPreview(
              height: compact ? 72 : 80,
              gradientColors: const [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
              icon: Icons.business_center_outlined,
              mood: VisualPlaceholderMood.business,
              badge: 'Деловой образ',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Деловой портрет',
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: UiPreviewPlaceholders.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: compact ? 32 : 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: UiPreviewPlaceholders.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Выбрать',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HelpDescriptionPreview extends StatelessWidget {
  const HelpDescriptionPreview({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return UiPreviewPlaceholders.helpShell(
      compact: compact,
      label: 'Поле описания',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: UiPreviewPlaceholders.accent.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.edit_outlined,
              size: compact ? 16 : 18,
              color: UiPreviewPlaceholders.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Сделай деловой портрет на светлом фоне',
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  height: 1.35,
                  color: UiPreviewPlaceholders.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpPhotoUploadPreview extends StatelessWidget {
  const HelpPhotoUploadPreview({
    super.key,
    this.compact = false,
    this.shellLabel = 'Добавьте фото',
  });

  final bool compact;
  final String shellLabel;

  @override
  Widget build(BuildContext context) {
    return UiPreviewPlaceholders.helpShell(
      compact: compact,
      label: shellLabel,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: compact ? 14 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD8DCE8),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: compact ? 28 : 32,
              color: UiPreviewPlaceholders.accent,
            ),
            const SizedBox(height: 6),
            Text(
              'Нажмите, чтобы выбрать фото',
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                color: UiPreviewPlaceholders.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpCreateButtonPreview extends StatelessWidget {
  const HelpCreateButtonPreview({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return UiPreviewPlaceholders.helpShell(
      compact: compact,
      label: 'Кнопка внизу экрана',
      child: Container(
        width: double.infinity,
        height: compact ? 44 : 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: UiPreviewPlaceholders.accent.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'Создать фото',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class HelpPhotoshootTripletPreview extends StatelessWidget {
  const HelpPhotoshootTripletPreview({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return UiPreviewPlaceholders.helpShell(
      compact: compact,
      label: 'Фотосессия · 3 фото',
      child: VisualPlaceholderSeries(
        mood: VisualPlaceholderMood.photoshoot,
        height: compact ? 88 : 96,
        gradientColors: const [Color(0xFFEDE9FF), Color(0xFFB8B0D4)],
        icon: Icons.photo_camera_outlined,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class HelpCustomRequestFlowPreview extends StatelessWidget {
  const HelpCustomRequestFlowPreview({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HelpDescriptionPreview(compact: compact),
        SizedBox(height: compact ? 10 : 12),
        HelpCreateButtonPreview(compact: compact),
      ],
    );
  }
}

class HelpDrawerMenuPreview extends StatelessWidget {
  const HelpDrawerMenuPreview({super.key, this.compact = false});

  final bool compact;

  static const _menuItems = [
    'Главная',
    'Фото по шаблону',
    'Фотосессии',
    'Свой запрос',
    'Готовые фото',
    'Купить',
  ];

  @override
  Widget build(BuildContext context) {
    return UiPreviewPlaceholders.helpShell(
      compact: compact,
      label: 'Меню слева сверху',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 40 : 44,
            height: compact ? 40 : 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAEF)),
            ),
            child: Icon(
              Icons.menu,
              size: compact ? 22 : 24,
              color: UiPreviewPlaceholders.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in _menuItems)
                  Padding(
                    padding: EdgeInsets.only(bottom: compact ? 4 : 6),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: compact ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE8EAEF)),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w500,
                          color: UiPreviewPlaceholders.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HelpWelcomePreview extends StatelessWidget {
  const HelpWelcomePreview({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return UiPreviewPlaceholders.helpShell(
      compact: compact,
      label: 'От простого к сложному',
      child: Row(
        children: [
          Expanded(
            child: _WelcomeStepChip(
              compact: compact,
              icon: Icons.dashboard_customize_outlined,
              label: 'Шаблон',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _WelcomeStepChip(
              compact: compact,
              icon: Icons.photo_camera_outlined,
              label: 'Фотосессия',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _WelcomeStepChip(
              compact: compact,
              icon: Icons.edit_outlined,
              label: 'Свой запрос',
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStepChip extends StatelessWidget {
  const _WelcomeStepChip({
    required this.compact,
    required this.icon,
    required this.label,
  });

  final bool compact;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAEF)),
      ),
      child: Column(
        children: [
          Icon(icon, size: compact ? 22 : 24, color: UiPreviewPlaceholders.accent),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: UiPreviewPlaceholders.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class HelpCustomStyleBannerPreview extends StatelessWidget {
  const HelpCustomStyleBannerPreview({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return UiPreviewPlaceholders.helpShell(
      compact: compact,
      label: 'Не нашли стиль?',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFEEF1FF),
              UiPreviewPlaceholders.accent.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: UiPreviewPlaceholders.accent.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Создать свой образ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: UiPreviewPlaceholders.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpStartCreatingPreview extends StatelessWidget {
  const HelpStartCreatingPreview({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return UiPreviewPlaceholders.helpShell(
      compact: compact,
      label: 'Кнопка на главной',
      child: Container(
        width: double.infinity,
        height: compact ? 44 : 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: UiPreviewPlaceholders.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Начать создавать',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class HelpGalleryPreview extends StatelessWidget {
  const HelpGalleryPreview({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return UiPreviewPlaceholders.helpShell(
      compact: compact,
      label: 'Раздел «Готовые фото»',
      child: VisualPlaceholderSeries(
        mood: VisualPlaceholderMood.portrait,
        height: compact ? 88 : 96,
        gradientColors: const [Color(0xFFF8EEF5), Color(0xFFC5D8FF)],
        icon: Icons.photo_library_outlined,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class PhotoQualityExampleCard extends StatelessWidget {
  const PhotoQualityExampleCard({
    super.key,
    required this.title,
    required this.photoHint,
    required this.descriptionExampleLabel,
    required this.descriptionExample,
    required this.gradientColors,
    required this.icon,
    required this.isGood,
  });

  final String title;
  final String photoHint;
  final String descriptionExampleLabel;
  final String descriptionExample;
  final List<Color> gradientColors;
  final IconData icon;
  final bool isGood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isGood ? const Color(0xFF2E9B66) : const Color(0xFFC45C5C);
    final statusBg = isGood ? const Color(0xFFE8F7EF) : const Color(0xFFFCEEEE);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGood
              ? const Color(0xFFB8E6CF)
              : const Color(0xFFF0CACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGood ? Icons.check_circle_outline : Icons.cancel_outlined,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          UiPreviewPlaceholders.framedPreview(
            height: 120,
            gradientColors: gradientColors,
            icon: icon,
            badge: 'Пример фото',
            dimmed: !isGood,
          ),
          const SizedBox(height: 10),
          Text(
            photoHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              height: 1.4,
              color: UiPreviewPlaceholders.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            descriptionExampleLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: UiPreviewPlaceholders.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8EAEF)),
            ),
            child: Text(
              descriptionExample,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.35,
                color: UiPreviewPlaceholders.textPrimary,
                fontStyle: isGood ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
