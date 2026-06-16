import 'package:flutter/material.dart';

import '../screens/template_photo_screen.dart';

/// UI-only metadata for catalog templates (not stored in JSON).
class CatalogTemplateVisuals {
  const CatalogTemplateVisuals({
    required this.kind,
    required this.placeholderColors,
    this.previewLabel,
  });

  final TemplateVisualKind kind;
  final List<Color> placeholderColors;
  final String? previewLabel;
}

/// UI-only metadata for catalog photoshoots (not stored in JSON).
class CatalogPhotoshootVisuals {
  const CatalogPhotoshootVisuals({
    required this.initials,
    required this.icon,
    required this.gradientColors,
    this.previewVariant = 0,
  });

  final String initials;
  final IconData icon;
  final List<Color> gradientColors;
  final int previewVariant;
}

class CatalogVisuals {
  CatalogVisuals._();

  static const _templateVisuals = <String, CatalogTemplateVisuals>{
    'beautiful_portrait': CatalogTemplateVisuals(
      kind: TemplateVisualKind.portrait,
      placeholderColors: [Color(0xFFF5E8D8), Color(0xFFD4B896)],
      previewLabel: 'Нежный портрет',
    ),
    'social_photo': CatalogTemplateVisuals(
      kind: TemplateVisualKind.social,
      placeholderColors: [Color(0xFFEDE9FF), Color(0xFFB8B0D4)],
      previewLabel: 'Для профиля',
    ),
    'winter_portrait': CatalogTemplateVisuals(
      kind: TemplateVisualKind.winter,
      placeholderColors: [Color(0xFFE8F4FF), Color(0xFFA8C8E8)],
      previewLabel: 'Зимняя прогулка',
    ),
    'business_portrait': CatalogTemplateVisuals(
      kind: TemplateVisualKind.business,
      placeholderColors: [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
      previewLabel: 'Деловой образ',
    ),
    'resume_photo': CatalogTemplateVisuals(
      kind: TemplateVisualKind.resume,
      placeholderColors: [Color(0xFFF0F2F8), Color(0xFFD0D6E4)],
      previewLabel: 'Для резюме',
    ),
    'product_photo': CatalogTemplateVisuals(
      kind: TemplateVisualKind.product,
      placeholderColors: [Color(0xFFEAF5EE), Color(0xFFB8D4C4)],
      previewLabel: 'Карточка товара',
    ),
    'summer_portrait': CatalogTemplateVisuals(
      kind: TemplateVisualKind.summer,
      placeholderColors: [Color(0xFFFFF0D0), Color(0xFFE8C878)],
      previewLabel: 'Летний день',
    ),
    'tender_portrait': CatalogTemplateVisuals(
      kind: TemplateVisualKind.tender,
      placeholderColors: [Color(0xFFFCE8F0), Color(0xFFE0B8D0)],
      previewLabel: 'Нежный образ',
    ),
    'vibrant_look': CatalogTemplateVisuals(
      kind: TemplateVisualKind.vibrant,
      placeholderColors: [Color(0xFFFFE0B8), Color(0xFFE87858)],
      previewLabel: 'Яркий стиль',
    ),
    'profile_photo': CatalogTemplateVisuals(
      kind: TemplateVisualKind.profile,
      placeholderColors: [Color(0xFFE8EEF8), Color(0xFFB0C0D8)],
      previewLabel: 'Для профиля',
    ),
    'expert_look': CatalogTemplateVisuals(
      kind: TemplateVisualKind.expert,
      placeholderColors: [Color(0xFFD8E4F0), Color(0xFF88A0B8)],
      previewLabel: 'Эксперт',
    ),
    'family_photo': CatalogTemplateVisuals(
      kind: TemplateVisualKind.family,
      placeholderColors: [Color(0xFFF5E8DC), Color(0xFFD4B8A0)],
      previewLabel: 'Семья',
    ),
    'photo_with_child': CatalogTemplateVisuals(
      kind: TemplateVisualKind.child,
      placeholderColors: [Color(0xFFFFF5E8), Color(0xFFE8D0B0)],
      previewLabel: 'С ребёнком',
    ),
    'festive_look': CatalogTemplateVisuals(
      kind: TemplateVisualKind.festive,
      placeholderColors: [Color(0xFFFFE8F0), Color(0xFFD87898)],
      previewLabel: 'Праздник',
    ),
    'clothing_photo': CatalogTemplateVisuals(
      kind: TemplateVisualKind.clothing,
      placeholderColors: [Color(0xFFF0F0F8), Color(0xFFC0C0D8)],
      previewLabel: 'Одежда',
    ),
    'jewelry_photo': CatalogTemplateVisuals(
      kind: TemplateVisualKind.jewelry,
      placeholderColors: [Color(0xFFFFF8F0), Color(0xFFE8D8C0)],
      previewLabel: 'Украшение',
    ),
    'interior_photo': CatalogTemplateVisuals(
      kind: TemplateVisualKind.interior,
      placeholderColors: [Color(0xFFF5F0E8), Color(0xFFC8B8A0)],
      previewLabel: 'Интерьер',
    ),
  };

  static const _photoshootVisuals = <String, CatalogPhotoshootVisuals>{
    'studio_portrait': CatalogPhotoshootVisuals(
      initials: 'СП',
      icon: Icons.portrait_outlined,
      gradientColors: [Color(0xFFE8E4F4), Color(0xFFB8B0D4)],
      previewVariant: 0,
    ),
    'business_portrait': CatalogPhotoshootVisuals(
      initials: 'ДП',
      icon: Icons.business_center_outlined,
      gradientColors: [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
      previewVariant: 1,
    ),
    'home_portrait': CatalogPhotoshootVisuals(
      initials: 'ДМ',
      icon: Icons.home_outlined,
      gradientColors: [Color(0xFFF5E8D8), Color(0xFFD4B896)],
      previewVariant: 2,
    ),
    'premium_portrait': CatalogPhotoshootVisuals(
      initials: 'ПР',
      icon: Icons.diamond_outlined,
      gradientColors: [Color(0xFFD8C8F8), Color(0xFF9070D8)],
      previewVariant: 3,
    ),
    'winter_photoshoot': CatalogPhotoshootVisuals(
      initials: 'ЗМ',
      icon: Icons.ac_unit,
      gradientColors: [Color(0xFFD0ECFA), Color(0xFF6CB8E8)],
      previewVariant: 1,
    ),
    'urban_portrait': CatalogPhotoshootVisuals(
      initials: 'ГР',
      icon: Icons.location_city_outlined,
      gradientColors: [Color(0xFFC8D4F8), Color(0xFF6878D0)],
      previewVariant: 0,
    ),
    'evening_look': CatalogPhotoshootVisuals(
      initials: 'ВЧ',
      icon: Icons.nightlife_outlined,
      gradientColors: [Color(0xFF7A5898), Color(0xFF3A2868)],
      previewVariant: 2,
    ),
    'travel_portrait': CatalogPhotoshootVisuals(
      initials: 'ПТ',
      icon: Icons.flight_outlined,
      gradientColors: [Color(0xFFC0ECE0), Color(0xFF58B8A8)],
      previewVariant: 3,
    ),
    'tender_photoshoot': CatalogPhotoshootVisuals(
      initials: 'НФ',
      icon: Icons.spa_outlined,
      gradientColors: [Color(0xFFF8E8F0), Color(0xFFD8A8C8)],
      previewVariant: 2,
    ),
    'summer_photoshoot': CatalogPhotoshootVisuals(
      initials: 'ЛФ',
      icon: Icons.wb_sunny_outlined,
      gradientColors: [Color(0xFFFFF0C8), Color(0xFFE8C060)],
      previewVariant: 1,
    ),
    'expert_photoshoot': CatalogPhotoshootVisuals(
      initials: 'ЭФ',
      icon: Icons.school_outlined,
      gradientColors: [Color(0xFFD0DCE8), Color(0xFF7898B8)],
      previewVariant: 0,
    ),
    'business_brand': CatalogPhotoshootVisuals(
      initials: 'БП',
      icon: Icons.work_outline,
      gradientColors: [Color(0xFFC8D8E8), Color(0xFF6888A8)],
      previewVariant: 1,
    ),
    'personal_brand': CatalogPhotoshootVisuals(
      initials: 'ЛБ',
      icon: Icons.campaign_outlined,
      gradientColors: [Color(0xFFE0E8F8), Color(0xFF90A8D8)],
      previewVariant: 2,
    ),
    'cafe_city': CatalogPhotoshootVisuals(
      initials: 'КГ',
      icon: Icons.local_cafe_outlined,
      gradientColors: [Color(0xFFE8D8C8), Color(0xFFA88868)],
      previewVariant: 0,
    ),
    'park_walk': CatalogPhotoshootVisuals(
      initials: 'ПП',
      icon: Icons.park_outlined,
      gradientColors: [Color(0xFFD8F0D8), Color(0xFF68B878)],
      previewVariant: 3,
    ),
  };

  static CatalogTemplateVisuals templateFor(String id) =>
      _templateVisuals[id] ??
      const CatalogTemplateVisuals(
        kind: TemplateVisualKind.portrait,
        placeholderColors: [Color(0xFFF5E8D8), Color(0xFFD4B896)],
      );

  static CatalogPhotoshootVisuals photoshootFor(String id) =>
      _photoshootVisuals[id] ??
      const CatalogPhotoshootVisuals(
        initials: 'ФС',
        icon: Icons.photo_camera_outlined,
        gradientColors: [Color(0xFFEDE9FF), Color(0xFFB8B0D4)],
      );
}
