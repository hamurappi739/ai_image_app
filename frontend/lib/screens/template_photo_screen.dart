import 'package:flutter/material.dart';

import '../widgets/app_screen_header.dart';
import '../widgets/section_help_button.dart';
import '../widgets/template_help_dialog.dart';

enum TemplateVisualKind {
  portrait,
  social,
  winter,
  summer,
  tender,
  vibrant,
  business,
  resume,
  profile,
  expert,
  family,
  child,
  festive,
  product,
  clothing,
  jewelry,
  interior,
}

class PhotoTemplate {
  const PhotoTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.requestDescription,
    required this.visualKind,
    required this.placeholderColors,
    this.previewLabel,
  });

  final String id;
  final String title;
  final String description;
  final String requestDescription;
  final TemplateVisualKind visualKind;
  final List<Color> placeholderColors;
  final String? previewLabel;
}

class _TemplateCategoryGroup {
  const _TemplateCategoryGroup({
    required this.title,
    required this.subtitle,
    required this.templateIds,
  });

  final String title;
  final String subtitle;
  final List<String> templateIds;
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
      id: 'beautiful_portrait',
      title: 'Красивый портрет',
      description: 'Мягкий свет и аккуратный образ для красивого фото.',
      requestDescription:
          'Сделай красивый портрет. Мягкий свет, аккуратная обработка, '
          'естественный внешний вид.',
      visualKind: TemplateVisualKind.portrait,
      placeholderColors: [Color(0xFFF5E8D8), Color(0xFFD4B896)],
      previewLabel: 'Нежный портрет',
    ),
    PhotoTemplate(
      id: 'social_photo',
      title: 'Фото для соцсетей',
      description: 'Современное фото для профиля или публикации.',
      requestDescription:
          'Сделай красивое фото для социальных сетей. '
          'Естественный образ, приятный свет, современный стиль.',
      visualKind: TemplateVisualKind.social,
      placeholderColors: [Color(0xFFEDE9FF), Color(0xFFB8B0D4)],
      previewLabel: 'Для профиля',
    ),
    PhotoTemplate(
      id: 'winter_portrait',
      title: 'Зимний портрет',
      description: 'Уютный зимний образ со снегом и мягким светом.',
      requestDescription:
          'Сделай зимний портрет. Тёплая одежда, мягкий снег на фоне, '
          'уютное настроение.',
      visualKind: TemplateVisualKind.winter,
      placeholderColors: [Color(0xFFE8F4FF), Color(0xFFA8C8E8)],
      previewLabel: 'Зимняя прогулка',
    ),
    PhotoTemplate(
      id: 'business_portrait',
      title: 'Деловой портрет',
      description: 'Аккуратное фото для работы и делового образа.',
      requestDescription:
          'Сделай деловой портрет на светлом фоне. '
          'Аккуратный образ, естественная улыбка, мягкий свет.',
      visualKind: TemplateVisualKind.business,
      placeholderColors: [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
      previewLabel: 'Деловой образ',
    ),
    PhotoTemplate(
      id: 'resume_photo',
      title: 'Фото для резюме',
      description: 'Нейтральный фон, лицо хорошо видно, спокойный стиль.',
      requestDescription:
          'Сделай аккуратное фото для резюме. Нейтральный фон, '
          'деловой стиль, лицо хорошо видно.',
      visualKind: TemplateVisualKind.resume,
      placeholderColors: [Color(0xFFF0F2F8), Color(0xFFD0D6E4)],
      previewLabel: 'Для резюме',
    ),
    PhotoTemplate(
      id: 'product_photo',
      title: 'Фото товара',
      description: 'Чистый фон и хороший свет для продажи товара.',
      requestDescription:
          'Сделай красивое фото товара для продажи. Чистый фон, '
          'хороший свет, предмет должен выглядеть аккуратно.',
      visualKind: TemplateVisualKind.product,
      placeholderColors: [Color(0xFFEAF5EE), Color(0xFFB8D4C4)],
      previewLabel: 'Карточка товара',
    ),
    PhotoTemplate(
      id: 'summer_portrait',
      title: 'Летний портрет',
      description: 'Солнечный свет, лёгкий образ и приятное настроение.',
      requestDescription:
          'Сделай летний портрет. Мягкий солнечный свет, лёгкий образ, '
          'приятный фон.',
      visualKind: TemplateVisualKind.summer,
      placeholderColors: [Color(0xFFFFF0D0), Color(0xFFE8C878)],
      previewLabel: 'Летний день',
    ),
    PhotoTemplate(
      id: 'tender_portrait',
      title: 'Нежный портрет',
      description: 'Мягкий свет, спокойный фон и естественная улыбка.',
      requestDescription:
          'Сделай нежный портрет. Мягкий свет, спокойный фон, '
          'естественная улыбка.',
      visualKind: TemplateVisualKind.tender,
      placeholderColors: [Color(0xFFFCE8F0), Color(0xFFE0B8D0)],
      previewLabel: 'Нежный образ',
    ),
    PhotoTemplate(
      id: 'vibrant_look',
      title: 'Яркий образ',
      description: 'Выразительные цвета и современная стильная подача.',
      requestDescription:
          'Сделай яркий стильный образ. Выразительные цвета, '
          'аккуратная обработка, современный вид.',
      visualKind: TemplateVisualKind.vibrant,
      placeholderColors: [Color(0xFFFFE0B8), Color(0xFFE87858)],
      previewLabel: 'Яркий стиль',
    ),
    PhotoTemplate(
      id: 'profile_photo',
      title: 'Фото для профиля',
      description: 'Аккуратное фото для сайта, блога или мессенджера.',
      requestDescription:
          'Сделай аккуратное фото для профиля. Лицо хорошо видно, '
          'приятный свет, уверенный образ.',
      visualKind: TemplateVisualKind.profile,
      placeholderColors: [Color(0xFFE8EEF8), Color(0xFFB0C0D8)],
      previewLabel: 'Для профиля',
    ),
    PhotoTemplate(
      id: 'expert_look',
      title: 'Экспертный образ',
      description: 'Уверенный деловой стиль для экспертного профиля.',
      requestDescription:
          'Сделай образ эксперта. Деловой стиль, спокойный фон, '
          'уверенное выражение лица.',
      visualKind: TemplateVisualKind.expert,
      placeholderColors: [Color(0xFFD8E4F0), Color(0xFF88A0B8)],
      previewLabel: 'Эксперт',
    ),
    PhotoTemplate(
      id: 'family_photo',
      title: 'Семейное фото',
      description: 'Тёплая атмосфера и естественный свет для семьи.',
      requestDescription:
          'Сделай тёплое семейное фото. Естественный свет, уютная '
          'атмосфера, аккуратная обработка.',
      visualKind: TemplateVisualKind.family,
      placeholderColors: [Color(0xFFF5E8DC), Color(0xFFD4B8A0)],
      previewLabel: 'Семья',
    ),
    PhotoTemplate(
      id: 'photo_with_child',
      title: 'Фото с ребёнком',
      description: 'Нежные эмоции, мягкий свет и тёплое настроение.',
      requestDescription:
          'Сделай нежное фото с ребёнком. Тёплая атмосфера, мягкий свет, '
          'естественные эмоции.',
      visualKind: TemplateVisualKind.child,
      placeholderColors: [Color(0xFFFFF5E8), Color(0xFFE8D0B0)],
      previewLabel: 'С ребёнком',
    ),
    PhotoTemplate(
      id: 'festive_look',
      title: 'Праздничный образ',
      description: 'Нарядный стиль, красивый свет и радостное настроение.',
      requestDescription:
          'Сделай праздничный образ. Красивый свет, нарядный стиль, '
          'радостное настроение.',
      visualKind: TemplateVisualKind.festive,
      placeholderColors: [Color(0xFFFFE8F0), Color(0xFFD87898)],
      previewLabel: 'Праздник',
    ),
    PhotoTemplate(
      id: 'clothing_photo',
      title: 'Фото одежды',
      description: 'Аккуратная подача вещи на чистом фоне для продажи.',
      requestDescription:
          'Сделай красивое фото одежды для продажи. Чистый фон, '
          'хороший свет, вещь выглядит аккуратно.',
      visualKind: TemplateVisualKind.clothing,
      placeholderColors: [Color(0xFFF0F0F8), Color(0xFFC0C0D8)],
      previewLabel: 'Одежда',
    ),
    PhotoTemplate(
      id: 'jewelry_photo',
      title: 'Фото украшений',
      description: 'Мягкий свет и чистый фон — украшение хорошо видно.',
      requestDescription:
          'Сделай красивое фото украшения для продажи. Чистый фон, '
          'мягкий свет, украшение хорошо видно.',
      visualKind: TemplateVisualKind.jewelry,
      placeholderColors: [Color(0xFFFFF8F0), Color(0xFFE8D8C0)],
      previewLabel: 'Украшение',
    ),
    PhotoTemplate(
      id: 'interior_photo',
      title: 'Фото интерьера',
      description: 'Светлая комната, уютная обстановка и аккуратный кадр.',
      requestDescription:
          'Сделай красивое фото интерьера. Светлая комната, аккуратная '
          'обстановка, уютная атмосфера.',
      visualKind: TemplateVisualKind.interior,
      placeholderColors: [Color(0xFFF5F0E8), Color(0xFFC8B8A0)],
      previewLabel: 'Интерьер',
    ),
  ];

  static const _categoryGroups = [
    _TemplateCategoryGroup(
      title: 'Для себя',
      subtitle: 'Красивые портреты и образы для себя и соцсетей.',
      templateIds: [
        'beautiful_portrait',
        'social_photo',
        'winter_portrait',
        'summer_portrait',
        'tender_portrait',
        'vibrant_look',
      ],
    ),
    _TemplateCategoryGroup(
      title: 'Для работы',
      subtitle: 'Деловой стиль для резюме, профиля и экспертного образа.',
      templateIds: [
        'business_portrait',
        'resume_photo',
        'profile_photo',
        'expert_look',
      ],
    ),
    _TemplateCategoryGroup(
      title: 'Для семьи',
      subtitle: 'Тёплые фото для семьи и особых моментов.',
      templateIds: [
        'family_photo',
        'photo_with_child',
        'festive_look',
      ],
    ),
    _TemplateCategoryGroup(
      title: 'Для продажи',
      subtitle: 'Аккуратные фото для товаров, одежды и интерьера.',
      templateIds: [
        'product_photo',
        'clothing_photo',
        'jewelry_photo',
        'interior_photo',
      ],
    ),
  ];

  static final Map<String, PhotoTemplate> _templatesById = {
    for (final t in templates) t.id: t,
  };

  static int _columnCount(double width) {
    if (width >= 560) return 2;
    return 1;
  }

  static double _gridAspectRatio(int columns) {
    return columns == 1 ? 0.80 : 0.74;
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
                      AppScreenHeader(
                        title: 'Фото по шаблону',
                        subtitle:
                            'Выберите готовый вариант. Описание подставится '
                            'само — вам останется только добавить фото.',
                        trailing: SectionHelpButton(
                          onPressed: () => TemplateHelpDialog.show(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _HowItWorksBanner(),
                      const SizedBox(height: 28),
                      for (var i = 0; i < _categoryGroups.length; i++) ...[
                        if (i > 0) const SizedBox(height: 28),
                        _TemplateCategorySection(
                          title: _categoryGroups[i].title,
                          subtitle: _categoryGroups[i].subtitle,
                          templates: [
                            for (final id in _categoryGroups[i].templateIds)
                              if (_templatesById.containsKey(id))
                                _templatesById[id]!,
                          ],
                          columns: columns,
                          aspectRatio: _gridAspectRatio(columns),
                          onTemplateSelected: onTemplateSelected,
                        ),
                      ],
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

class _HowItWorksBanner extends StatelessWidget {
  const _HowItWorksBanner();

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Как это работает',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              const steps = [
                _HowItWorksStep(number: '1', text: 'Выберите шаблон'),
                _HowItWorksStep(number: '2', text: 'Добавьте своё фото'),
                _HowItWorksStep(number: '3', text: 'Нажмите «Создать фото»'),
              ];

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < steps.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      steps[i],
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: steps[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({required this.number, required this.text});

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textSecondary = Color(0xFF6B7280);

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _accentColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: _textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplateCategorySection extends StatelessWidget {
  const _TemplateCategorySection({
    required this.title,
    required this.subtitle,
    required this.templates,
    required this.columns,
    required this.aspectRatio,
    required this.onTemplateSelected,
  });

  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  final String title;
  final String subtitle;
  final List<PhotoTemplate> templates;
  final int columns;
  final double aspectRatio;
  final ValueChanged<PhotoTemplate> onTemplateSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.4,
                color: _textSecondary,
              ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return _TemplateCard(
              template: template,
              onSelect: () => onTemplateSelected(template),
            );
          },
        ),
      ],
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
          _TemplatePreview(template: template),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_fix_high_outlined,
                        size: 15,
                        color: _accentColor.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Описание подставится автоматически',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                            color: _accentColor.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
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

class _TemplatePreview extends StatelessWidget {
  const _TemplatePreview({required this.template});

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textSecondary = Color(0xFF6B7280);

  final PhotoTemplate template;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: template.placeholderColors,
              ),
            ),
          ),
          ..._decorativeElements(template.visualKind),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
          Center(child: _mainVisual(template)),
          if (template.previewLabel != null)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  template.previewLabel!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    );
  }

  List<Widget> _decorativeElements(TemplateVisualKind kind) {
    switch (kind) {
      case TemplateVisualKind.winter:
        return [
          Positioned(
            top: 18,
            right: 22,
            child: Icon(
              Icons.ac_unit,
              size: 18,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            bottom: 36,
            left: 28,
            child: Icon(
              Icons.ac_unit_outlined,
              size: 14,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ];
      case TemplateVisualKind.product:
        return [
          Positioned(
            bottom: 28,
            right: 24,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ];
      case TemplateVisualKind.social:
        return [
          Positioned(
            top: 20,
            right: 24,
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ];
      case TemplateVisualKind.summer:
        return [
          Positioned(
            top: 16,
            right: 20,
            child: Icon(
              Icons.wb_sunny_outlined,
              size: 20,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ];
      case TemplateVisualKind.festive:
        return [
          Positioned(
            top: 14,
            right: 18,
            child: Icon(
              Icons.celebration_outlined,
              size: 18,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ];
      case TemplateVisualKind.jewelry:
        return [
          Positioned(
            top: 18,
            right: 22,
            child: Icon(
              Icons.diamond_outlined,
              size: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _mainVisual(PhotoTemplate template) {
    switch (template.visualKind) {
      case TemplateVisualKind.product:
        return Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 38,
            color: _accentColor.withValues(alpha: 0.88),
          ),
        );
      case TemplateVisualKind.winter:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.ac_unit_outlined,
                size: 34,
                color: const Color(0xFF5B8FD4).withValues(alpha: 0.95),
              ),
            ),
          ],
        );
      case TemplateVisualKind.business:
        return _portraitFrame(
          icon: Icons.business_center_outlined,
          iconColor: const Color(0xFF5A7A9E),
        );
      case TemplateVisualKind.resume:
        return _portraitFrame(
          icon: Icons.badge_outlined,
          iconColor: const Color(0xFF7A8494),
        );
      case TemplateVisualKind.social:
        return _portraitFrame(
          icon: Icons.person_outline,
          iconColor: _accentColor.withValues(alpha: 0.9),
          secondaryIcon: Icons.photo_camera_outlined,
        );
      case TemplateVisualKind.portrait:
        return _portraitFrame(
          icon: Icons.face_retouching_natural_outlined,
          iconColor: const Color(0xFFB8885A),
        );
      case TemplateVisualKind.summer:
        return _portraitFrame(
          icon: Icons.wb_sunny_outlined,
          iconColor: const Color(0xFFD89830),
        );
      case TemplateVisualKind.tender:
        return _portraitFrame(
          icon: Icons.spa_outlined,
          iconColor: const Color(0xFFC878A8),
        );
      case TemplateVisualKind.vibrant:
        return _portraitFrame(
          icon: Icons.palette_outlined,
          iconColor: const Color(0xFFE05838),
        );
      case TemplateVisualKind.profile:
        return _portraitFrame(
          icon: Icons.account_circle_outlined,
          iconColor: const Color(0xFF5A7A9E),
        );
      case TemplateVisualKind.expert:
        return _portraitFrame(
          icon: Icons.school_outlined,
          iconColor: const Color(0xFF4A6888),
        );
      case TemplateVisualKind.family:
        return _portraitFrame(
          icon: Icons.family_restroom_outlined,
          iconColor: const Color(0xFFB8885A),
        );
      case TemplateVisualKind.child:
        return _portraitFrame(
          icon: Icons.child_care_outlined,
          iconColor: const Color(0xFFD89858),
        );
      case TemplateVisualKind.festive:
        return _portraitFrame(
          icon: Icons.celebration_outlined,
          iconColor: const Color(0xFFC84878),
        );
      case TemplateVisualKind.clothing:
        return Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.checkroom_outlined,
            size: 38,
            color: _accentColor.withValues(alpha: 0.88),
          ),
        );
      case TemplateVisualKind.jewelry:
        return Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.diamond_outlined,
            size: 38,
            color: const Color(0xFFD8A848).withValues(alpha: 0.95),
          ),
        );
      case TemplateVisualKind.interior:
        return Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.weekend_outlined,
            size: 38,
            color: const Color(0xFF9A8878).withValues(alpha: 0.95),
          ),
        );
    }
  }

  Widget _portraitFrame({
    required IconData icon,
    required Color iconColor,
    IconData? secondaryIcon,
  }) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.65),
              width: 2,
            ),
          ),
          child: Icon(icon, size: 36, color: iconColor),
        ),
        if (secondaryIcon != null)
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(secondaryIcon, size: 14, color: _accentColor),
            ),
          ),
      ],
    );
  }
}
