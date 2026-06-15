import 'package:flutter/material.dart';

import '../data/app_prompts.dart';
import '../assets/preview_asset_paths.dart';
import '../models/generated_image_item.dart';
import '../models/user_balance.dart';
import '../services/api_service.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/template_create_sheet.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/preview_asset_image.dart';
import '../widgets/section_help_button.dart';
import '../widgets/template_help_dialog.dart';
import '../widgets/visual_placeholder.dart';

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

extension TemplateVisualKindPlaceholder on TemplateVisualKind {
  VisualPlaceholderMood get placeholderMood => switch (this) {
        TemplateVisualKind.portrait ||
        TemplateVisualKind.tender ||
        TemplateVisualKind.vibrant =>
          VisualPlaceholderMood.portrait,
        TemplateVisualKind.social => VisualPlaceholderMood.social,
        TemplateVisualKind.business ||
        TemplateVisualKind.resume ||
        TemplateVisualKind.profile ||
        TemplateVisualKind.expert =>
          VisualPlaceholderMood.business,
        TemplateVisualKind.winter => VisualPlaceholderMood.winter,
        TemplateVisualKind.summer => VisualPlaceholderMood.summer,
        TemplateVisualKind.family ||
        TemplateVisualKind.child ||
        TemplateVisualKind.festive =>
          VisualPlaceholderMood.family,
        TemplateVisualKind.product ||
        TemplateVisualKind.clothing ||
        TemplateVisualKind.jewelry =>
          VisualPlaceholderMood.product,
        TemplateVisualKind.interior => VisualPlaceholderMood.interior,
      };
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
    this.previewAssetPath,
  });

  final String id;
  final String title;
  final String description;
  final String requestDescription;
  final TemplateVisualKind visualKind;
  final List<Color> placeholderColors;
  final String? previewLabel;

  /// Planned local preview path (jpg/png under assets/previews/templates/).
  final String? previewAssetPath;

  /// Bundled or planned preview asset for catalog cards and modals.
  String get previewAsset =>
      previewAssetPath ?? PreviewAssetPaths.templateAssetForId(id);

  String? get effectivePreviewAssetPath => previewAsset;
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

class TemplatePhotoScreen extends StatefulWidget {
  const TemplatePhotoScreen({
    super.key,
    required this.apiService,
    required this.balance,
    required this.balanceLoading,
    required this.onImageGenerated,
    required this.onBalanceUpdated,
    required this.onRefreshBalance,
    required this.onOpenGallery,
    required this.onOpenPacks,
    required this.onShowMessage,
  });

  static const _scaffoldBackground = Color(0xFFF7F8FC);

  final ApiService apiService;
  final UserBalance? balance;
  final bool balanceLoading;
  final ValueChanged<GeneratedImageItem> onImageGenerated;
  final ValueChanged<UserBalance> onBalanceUpdated;
  final VoidCallback onRefreshBalance;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenPacks;
  final ValueChanged<String> onShowMessage;

  @override
  State<TemplatePhotoScreen> createState() => _TemplatePhotoScreenState();
}

class _TemplatePhotoScreenState extends State<TemplatePhotoScreen> {
  int _selectedCategoryIndex = 0;

  void _openTemplateSheet(BuildContext context, PhotoTemplate template) {
    TemplateCreateSheet.show(
      context,
      template: template,
      apiService: widget.apiService,
      balance: widget.balance,
      balanceLoading: widget.balanceLoading,
      onImageGenerated: widget.onImageGenerated,
      onBalanceUpdated: widget.onBalanceUpdated,
      onRefreshBalance: widget.onRefreshBalance,
      onOpenGallery: widget.onOpenGallery,
      onOpenPacks: widget.onOpenPacks,
      onShowMessage: widget.onShowMessage,
    );
  }

  static PhotoTemplate _template({
    required String id,
    required String title,
    required TemplateVisualKind visualKind,
    required List<Color> placeholderColors,
    String? previewLabel,
    String? previewAssetPath,
  }) {
    return PhotoTemplate(
      id: id,
      title: title,
      description: AppPrompts.templateShort(id),
      requestDescription: AppPrompts.templateFull(id),
      visualKind: visualKind,
      placeholderColors: placeholderColors,
      previewLabel: previewLabel,
      previewAssetPath: previewAssetPath,
    );
  }

  static final templates = [
    _template(
      id: 'beautiful_portrait',
      title: 'Красивый портрет',
      visualKind: TemplateVisualKind.portrait,
      placeholderColors: [Color(0xFFF5E8D8), Color(0xFFD4B896)],
      previewLabel: 'Нежный портрет',
    ),
    _template(
      id: 'social_photo',
      title: 'Фото для соцсетей',
      visualKind: TemplateVisualKind.social,
      placeholderColors: [Color(0xFFEDE9FF), Color(0xFFB8B0D4)],
      previewLabel: 'Для профиля',
    ),
    _template(
      id: 'winter_portrait',
      title: 'Зимний портрет',
      visualKind: TemplateVisualKind.winter,
      placeholderColors: [Color(0xFFE8F4FF), Color(0xFFA8C8E8)],
      previewLabel: 'Зимняя прогулка',
    ),
    _template(
      id: 'business_portrait',
      title: 'Деловой портрет',
      visualKind: TemplateVisualKind.business,
      placeholderColors: [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
      previewLabel: 'Деловой образ',
    ),
    _template(
      id: 'resume_photo',
      title: 'Фото для резюме',
      visualKind: TemplateVisualKind.resume,
      placeholderColors: [Color(0xFFF0F2F8), Color(0xFFD0D6E4)],
      previewLabel: 'Для резюме',
    ),
    _template(
      id: 'product_photo',
      title: 'Фото товара',
      visualKind: TemplateVisualKind.product,
      placeholderColors: [Color(0xFFEAF5EE), Color(0xFFB8D4C4)],
      previewLabel: 'Карточка товара',
    ),
    _template(
      id: 'summer_portrait',
      title: 'Летний портрет',
      visualKind: TemplateVisualKind.summer,
      placeholderColors: [Color(0xFFFFF0D0), Color(0xFFE8C878)],
      previewLabel: 'Летний день',
    ),
    _template(
      id: 'tender_portrait',
      title: 'Нежный портрет',
      visualKind: TemplateVisualKind.tender,
      placeholderColors: [Color(0xFFFCE8F0), Color(0xFFE0B8D0)],
      previewLabel: 'Нежный образ',
    ),
    _template(
      id: 'vibrant_look',
      title: 'Яркий образ',
      visualKind: TemplateVisualKind.vibrant,
      placeholderColors: [Color(0xFFFFE0B8), Color(0xFFE87858)],
      previewLabel: 'Яркий стиль',
    ),
    _template(
      id: 'profile_photo',
      title: 'Фото для профиля',
      visualKind: TemplateVisualKind.profile,
      placeholderColors: [Color(0xFFE8EEF8), Color(0xFFB0C0D8)],
      previewLabel: 'Для профиля',
    ),
    _template(
      id: 'expert_look',
      title: 'Экспертный образ',
      visualKind: TemplateVisualKind.expert,
      placeholderColors: [Color(0xFFD8E4F0), Color(0xFF88A0B8)],
      previewLabel: 'Эксперт',
    ),
    _template(
      id: 'family_photo',
      title: 'Семейное фото',
      visualKind: TemplateVisualKind.family,
      placeholderColors: [Color(0xFFF5E8DC), Color(0xFFD4B8A0)],
      previewLabel: 'Семья',
    ),
    _template(
      id: 'photo_with_child',
      title: 'Фото с ребёнком',
      visualKind: TemplateVisualKind.child,
      placeholderColors: [Color(0xFFFFF5E8), Color(0xFFE8D0B0)],
      previewLabel: 'С ребёнком',
    ),
    _template(
      id: 'festive_look',
      title: 'Праздничный образ',
      visualKind: TemplateVisualKind.festive,
      placeholderColors: [Color(0xFFFFE8F0), Color(0xFFD87898)],
      previewLabel: 'Праздник',
    ),
    _template(
      id: 'clothing_photo',
      title: 'Фото одежды',
      visualKind: TemplateVisualKind.clothing,
      placeholderColors: [Color(0xFFF0F0F8), Color(0xFFC0C0D8)],
      previewLabel: 'Одежда',
    ),
    _template(
      id: 'jewelry_photo',
      title: 'Фото украшений',
      visualKind: TemplateVisualKind.jewelry,
      placeholderColors: [Color(0xFFFFF8F0), Color(0xFFE8D8C0)],
      previewLabel: 'Украшение',
    ),
    _template(
      id: 'interior_photo',
      title: 'Фото интерьера',
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

  static double _cardMainExtent(double gridWidth, int columns) {
    final cardWidth = (gridWidth - (columns - 1) * 16) / columns;
    final previewHeight = cardWidth * 3 / 4;
    const contentHeight = 14.0 + 38.0 + 6.0 + 34.0 + 10.0 + 40.0 + 14.0;
    return previewHeight + contentHeight;
  }

  List<PhotoTemplate> _templatesForCategory(int index) {
    final group = _categoryGroups[index];
    return [
      for (final id in group.templateIds)
        if (_templatesById.containsKey(id)) _templatesById[id]!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final category = _categoryGroups[_selectedCategoryIndex];
    final categoryLabels = [
      for (final g in _categoryGroups) g.title,
    ];

    return Scaffold(
      backgroundColor: TemplatePhotoScreen._scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _columnCount(constraints.maxWidth);
                final templates = _templatesForCategory(_selectedCategoryIndex);
                final cardExtent =
                    _cardMainExtent(constraints.maxWidth, columns);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppScreenHeader(
                        title: 'Шаблоны фото',
                        subtitle:
                            'Выберите шаблон, добавьте фото и создайте '
                            'результат.',
                        trailing: SectionHelpButton(
                          onPressed: () => TemplateHelpDialog.show(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _HowItWorksBanner(),
                      const SizedBox(height: 20),
                      CategoryFilterChips(
                        labels: categoryLabels,
                        selectedIndex: _selectedCategoryIndex,
                        onSelected: (index) {
                          setState(() => _selectedCategoryIndex = index);
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        category.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              height: 1.4,
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: cardExtent,
                        ),
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          return _TemplateCard(
                            template: template,
                            onTry: () =>
                                _openTemplateSheet(context, template),
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

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onTry,
  });

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  final PhotoTemplate template;
  final VoidCallback onTry;

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
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: PreviewAssetImage(
              assetPath: template.previewAsset,
              fit: BoxFit.cover,
              placeholder: LayoutBuilder(
                builder: (context, constraints) => VisualPlaceholder(
                  mood: template.visualKind.placeholderMood,
                  gradientColors: template.placeholderColors,
                  caption: template.previewLabel ??
                      VisualPlaceholderPalette.theme(
                        template.visualKind.placeholderMood,
                      ).caption,
                  variant: template.id.hashCode.abs() % 4,
                  height: constraints.maxHeight,
                  compact: true,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  template.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  template.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    height: 1.35,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: FilledButton(
                    onPressed: onTry,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Попробовать'),
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
