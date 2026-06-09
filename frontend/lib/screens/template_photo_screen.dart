import 'package:flutter/material.dart';

import '../widgets/app_screen_header.dart';

class PhotoTemplate {
  const PhotoTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.prompt,
    required this.icon,
    required this.placeholderColors,
    this.previewLabel,
  });

  final String id;
  final String title;
  final String description;
  final String prompt;
  final IconData icon;
  final List<Color> placeholderColors;
  final String? previewLabel;
}

class TemplatePhotoScreen extends StatelessWidget {
  const TemplatePhotoScreen({
    super.key,
    required this.onTemplateSelected,
  });

  static const _scaffoldBackground = Color(0xFFF7F8FC);

  final ValueChanged<PhotoTemplate> onTemplateSelected;

  static const templates = [
    PhotoTemplate(
      id: 'business_portrait',
      title: 'Деловой портрет',
      description: 'Для работы, резюме и деловых профилей.',
      prompt:
          'Деловой портрет в светлой студии, аккуратный деловой образ, '
          'мягкий свет, спокойный фон, реализм',
      icon: Icons.business_center_outlined,
      placeholderColors: [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
      previewLabel: 'Деловой образ',
    ),
    PhotoTemplate(
      id: 'social_photo',
      title: 'Фото для соцсетей',
      description: 'Яркий портрет для профиля и постов.',
      prompt:
          'Портрет для соцсетей, светлый фон, естественная улыбка, '
          'современный стиль, мягкий свет',
      icon: Icons.share_outlined,
      placeholderColors: [Color(0xFFEDE9FF), Color(0xFFB8B0D4)],
      previewLabel: 'Для профиля',
    ),
    PhotoTemplate(
      id: 'winter_portrait',
      title: 'Зимний портрет',
      description: 'Тёплый зимний образ на улице со снегом.',
      prompt:
          'Зимний портрет на улице, тёплая одежда, красивый снег, '
          'мягкий зимний свет, реализм',
      icon: Icons.ac_unit_outlined,
      placeholderColors: [Color(0xFFE8F4FF), Color(0xFFA8C8E8)],
      previewLabel: 'Зимняя прогулка',
    ),
    PhotoTemplate(
      id: 'resume_photo',
      title: 'Фото для резюме',
      description: 'Спокойный профессиональный портрет.',
      prompt:
          'Портрет для резюме, нейтральный светлый фон, уверенный вид, '
          'аккуратный деловой стиль, реализм',
      icon: Icons.badge_outlined,
      placeholderColors: [Color(0xFFF0F2F8), Color(0xFFD0D6E4)],
      previewLabel: 'Для резюме',
    ),
    PhotoTemplate(
      id: 'beautiful_portrait',
      title: 'Красивый портрет',
      description: 'Мягкий свет для личного профиля.',
      prompt:
          'Красивый портрет с мягким светом, приятная атмосфера, '
          'естественные цвета, реализм',
      icon: Icons.face_retouching_natural_outlined,
      placeholderColors: [Color(0xFFF5E8D8), Color(0xFFD4B896)],
      previewLabel: 'Нежный портрет',
    ),
    PhotoTemplate(
      id: 'product_photo',
      title: 'Фото товара',
      description: 'Чистый фон для карточки товара.',
      prompt:
          'Рекламное фото товара на светлом фоне, мягкий студийный свет, '
          'минимализм, аккуратная композиция',
      icon: Icons.inventory_2_outlined,
      placeholderColors: [Color(0xFFEAF5EE), Color(0xFFB8D4C4)],
      previewLabel: 'Карточка товара',
    ),
  ];

  static int _columnCount(double width) {
    if (width >= 900) return 3;
    if (width >= 560) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _columnCount(constraints.maxWidth);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppScreenHeader(
                        title: 'Фото по шаблону',
                        subtitle:
                            'Выберите готовый вариант. Так проще, '
                            'чем писать описание с нуля.',
                      ),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: columns == 1 ? 0.78 : 0.72,
                        ),
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          return _TemplateCard(
                            template: templates[index],
                            onSelect: () =>
                                onTemplateSelected(templates[index]),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onSelect,
  });

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  final PhotoTemplate template;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: template.placeholderColors,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Пример результата',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      template.icon,
                      size: 40,
                      color: _accentColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                if (template.previewLabel != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        template.previewLabel!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      color: _textSecondary,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: onSelect,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Выбрать'),
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
