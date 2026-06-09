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
  });

  final String id;
  final String title;
  final String description;
  final String prompt;
  final IconData icon;
  final List<Color> placeholderColors;
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
      description: 'Аккуратный образ для работы, резюме и деловых профилей.',
      prompt:
          'Деловой портрет в светлой студии, аккуратный деловой образ, '
          'мягкий свет, спокойный фон, реализм',
      icon: Icons.business_center_outlined,
      placeholderColors: [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
    ),
    PhotoTemplate(
      id: 'social_photo',
      title: 'Фото для соцсетей',
      description: 'Яркий и понятный портрет для профиля и постов.',
      prompt:
          'Портрет для соцсетей, светлый фон, естественная улыбка, '
          'современный стиль, мягкий свет',
      icon: Icons.share_outlined,
      placeholderColors: [Color(0xFFEDE9FF), Color(0xFFB8B0D4)],
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
    ),
    PhotoTemplate(
      id: 'resume_photo',
      title: 'Фото для резюме',
      description: 'Спокойный профессиональный портрет без лишних деталей.',
      prompt:
          'Портрет для резюме, нейтральный светлый фон, уверенный вид, '
          'аккуратный деловой стиль, реализм',
      icon: Icons.badge_outlined,
      placeholderColors: [Color(0xFFF0F2F8), Color(0xFFD0D6E4)],
    ),
    PhotoTemplate(
      id: 'beautiful_portrait',
      title: 'Красивый портрет',
      description: 'Мягкий свет и приятная атмосфера для личного профиля.',
      prompt:
          'Красивый портрет с мягким светом, приятная атмосфера, '
          'естественные цвета, реализм',
      icon: Icons.face_retouching_natural_outlined,
      placeholderColors: [Color(0xFFF5E8D8), Color(0xFFD4B896)],
    ),
    PhotoTemplate(
      id: 'product_photo',
      title: 'Фото товара',
      description: 'Чистый фон и аккуратный свет для карточки товара.',
      prompt:
          'Рекламное фото товара на светлом фоне, мягкий студийный свет, '
          'минимализм, аккуратная композиция',
      icon: Icons.inventory_2_outlined,
      placeholderColors: [Color(0xFFEAF5EE), Color(0xFFB8D4C4)],
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
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: columns == 1 ? 0.92 : 0.82,
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
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: template.placeholderColors,
                ),
              ),
              child: Center(
                child: Icon(
                  template.icon,
                  size: 44,
                  color: _accentColor.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      template.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.35,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: onSelect,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accentColor,
                        side: BorderSide(
                          color: _accentColor.withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Выбрать',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
