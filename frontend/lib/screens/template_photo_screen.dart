import 'package:flutter/material.dart';

import '../assets/preview_asset_paths.dart';
import '../data/catalog_visuals.dart';
import '../models/catalog_entries.dart';
import '../services/catalog_service.dart';
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
    this.previewUrl,
    this.generationBlocked = false,
    this.generationBlockedMessage,
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

  /// Optional remote preview URL from backend catalog.
  final String? previewUrl;

  final bool generationBlocked;
  final String? generationBlockedMessage;

  /// Bundled or planned preview asset for catalog cards and modals.
  String get previewAsset =>
      previewAssetPath ?? PreviewAssetPaths.templateAssetForId(id);

  String? get effectivePreviewAssetPath => previewAsset;

  String? get effectivePreviewNetworkUrl =>
      isHttpPreviewUrl(previewUrl) ? previewUrl!.trim() : null;

  factory PhotoTemplate.fromCatalog(CatalogTemplateEntry entry) {
    final visuals = CatalogVisuals.templateFor(entry.id);
    return PhotoTemplate(
      id: entry.id,
      title: entry.title,
      description: entry.shortDescription,
      requestDescription: entry.prompt,
      visualKind: visuals.kind,
      placeholderColors: visuals.placeholderColors,
      previewLabel: visuals.previewLabel,
      previewAssetPath: entry.previewAsset,
      previewUrl: entry.previewUrl,
      generationBlocked: entry.generationBlocked,
      generationBlockedMessage: entry.generationBlockedMessage,
    );
  }
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

  static int _columnCount(double width) {
    if (width >= 560) return 2;
    return 1;
  }

  static double _gridItemWidth(double gridWidth, int columns) {
    if (columns <= 1) return gridWidth;
    return (gridWidth - 16 * (columns - 1)) / columns;
  }

  List<PhotoTemplate> _templatesForCategory(int index) {
    final group = _categoryGroups[index];
    return CatalogService.instance
        .templatesForCategory(group.title)
        .map(PhotoTemplate.fromCatalog)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!CatalogService.instance.isLoaded) {
      return const Scaffold(
        backgroundColor: TemplatePhotoScreen._scaffoldBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                final itemWidth =
                    _gridItemWidth(constraints.maxWidth, columns);

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
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final template in templates)
                            SizedBox(
                              width: itemWidth,
                              child: _TemplateCard(
                                template: template,
                                onTry: () =>
                                    _openTemplateSheet(context, template),
                              ),
                            ),
                        ],
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
  static const _previewHeight = 190.0;

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
          SizedBox(
            height: _previewHeight,
            width: double.infinity,
            child: PreviewAssetImage(
              assetPath: template.previewAsset,
              networkUrl: template.effectivePreviewNetworkUrl,
              fit: BoxFit.cover,
              placeholder: VisualPlaceholder(
                mood: template.visualKind.placeholderMood,
                gradientColors: template.placeholderColors,
                caption: template.previewLabel ??
                    VisualPlaceholderPalette.theme(
                      template.visualKind.placeholderMood,
                    ).caption,
                variant: template.id.hashCode.abs() % 4,
                height: _previewHeight,
                compact: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
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
