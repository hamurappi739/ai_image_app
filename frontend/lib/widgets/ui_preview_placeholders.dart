import 'package:flutter/material.dart';

import 'preview_asset_image.dart';
import 'visual_placeholder.dart';

/// Shared visual placeholders for help slides and tips (no real images).
class UiPreviewPlaceholders {
  UiPreviewPlaceholders._();

  static const accent = Color(0xFF5B6CFF);
  static const textPrimary = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF6B7280);

  static const _businessPortrait =
      'assets/previews/templates/business_portrait.jpg';
  static const _beautifulPortrait =
      'assets/previews/templates/beautiful_portrait.jpg';
  static const _childPhoto = 'assets/previews/templates/child_photo.jpg';
  static const _goodPhoto = 'assets/guides/good_photo.jpg';
  static const _badPhoto = 'assets/guides/bad_photo.jpg';
  static const _studioPortrait1 =
      'assets/previews/photoshoots/studio_portrait_1.jpg';
  static const _studioPortrait2 =
      'assets/previews/photoshoots/studio_portrait_2.jpg';
  static const _studioPortrait3 =
      'assets/previews/photoshoots/studio_portrait_3.jpg';

  static Widget assetPreview({
    required String assetPath,
    double aspectRatio = 4 / 3,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(14)),
    bool dimmed = false,
    bool compact = false,
  }) {
    Widget image = PreviewAssetImage(
      assetPath: assetPath,
      fit: BoxFit.cover,
      placeholder: Container(
        color: const Color(0xFFE8EAEF),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          color: textSecondary,
          size: compact ? 20 : 24,
        ),
      ),
    );
    if (dimmed) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.35),
          BlendMode.darken,
        ),
        child: image,
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(aspectRatio: aspectRatio, child: image),
    );
  }

  static Widget photoshootThumbRow({
    bool compact = false,
    bool showLabels = false,
  }) {
    const paths = [_studioPortrait1, _studioPortrait2, _studioPortrait3];
    return Row(
      children: [
        for (var i = 0; i < paths.length; i++) ...[
          if (i > 0) SizedBox(width: compact ? 4 : 6),
          Expanded(
            child: Column(
              children: [
                assetPreview(
                  assetPath: paths[i],
                  aspectRatio: 3 / 4,
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                  compact: compact,
                ),
                if (showLabels) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Фото ${i + 1}',
                    style: TextStyle(
                      fontSize: compact ? 9 : 10,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

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
            child: UiPreviewPlaceholders.assetPreview(
              assetPath: UiPreviewPlaceholders._businessPortrait,
              compact: compact,
              borderRadius: BorderRadius.circular(14),
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
      child: Row(
        children: [
          SizedBox(
            width: compact ? 72 : 80,
            child: UiPreviewPlaceholders.assetPreview(
              assetPath: UiPreviewPlaceholders._goodPhoto,
              aspectRatio: 1,
              compact: compact,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: compact ? 72 : 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: UiPreviewPlaceholders.accent.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: compact ? 24 : 28,
                    color: UiPreviewPlaceholders.accent,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Выбрать фото',
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: UiPreviewPlaceholders.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      child: UiPreviewPlaceholders.photoshootThumbRow(compact: compact),
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
    'Своя идея',
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
              label: 'Своя идея',
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
      child: Row(
        children: [
          Expanded(
            child: UiPreviewPlaceholders.assetPreview(
              assetPath: UiPreviewPlaceholders._beautifulPortrait,
              compact: compact,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: UiPreviewPlaceholders.assetPreview(
              assetPath: UiPreviewPlaceholders._childPhoto,
              compact: compact,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: UiPreviewPlaceholders.assetPreview(
              assetPath: UiPreviewPlaceholders._studioPortrait1,
              aspectRatio: 3 / 4,
              compact: compact,
            ),
          ),
        ],
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
    this.previewAssetPath,
  });

  final String title;
  final String photoHint;
  final String descriptionExampleLabel;
  final String descriptionExample;
  final List<Color> gradientColors;
  final IconData icon;
  final bool isGood;
  final String? previewAssetPath;

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
          UiPreviewPlaceholders.assetPreview(
            assetPath: previewAssetPath ??
                (isGood
                    ? UiPreviewPlaceholders._goodPhoto
                    : UiPreviewPlaceholders._badPhoto),
            aspectRatio: 4 / 3,
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
