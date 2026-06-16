// Planned local preview image paths under `assets/previews/`.
// Add .jpg files under assets/previews/templates/ or photoshoots/ and
// restart the app — PreviewAssetImage loads them with placeholder fallback.

class PreviewAssetPaths {
  PreviewAssetPaths._();

  static const _templatesDir = 'assets/previews/templates';
  static const _photoshootsDir = 'assets/previews/photoshoots';

  // —— Common ———————————————————————————————————————————————————————————————

  static const homeHero = 'assets/previews/common/home_hero.png';

  // —— Templates (.jpg) — catalog id → filename on disk ————————————————————

  static const Map<String, String> templateById = {
    'beautiful_portrait': '$_templatesDir/beautiful_portrait.jpg',
    'business_portrait': '$_templatesDir/business_portrait.jpg',
    'social_photo': '$_templatesDir/social_photo.jpg',
    'winter_portrait': '$_templatesDir/winter_portrait.jpg',
    'summer_portrait': '$_templatesDir/summer_portrait.jpg',
    'tender_portrait': '$_templatesDir/gentle_portrait.jpg',
    'vibrant_look': '$_templatesDir/bright_look.jpg',
    'resume_photo': '$_templatesDir/resume_photo.jpg',
    'profile_photo': '$_templatesDir/profile_photo.jpg',
    'expert_look': '$_templatesDir/expert_look.jpg',
    'family_photo': '$_templatesDir/family_photo.jpg',
    'photo_with_child': '$_templatesDir/child_photo.jpg',
    'festive_look': '$_templatesDir/holiday_look.jpg',
    'product_photo': '$_templatesDir/product_photo.jpg',
    'clothing_photo': '$_templatesDir/clothes_photo.jpg',
    'jewelry_photo': '$_templatesDir/jewelry_photo.jpg',
    'interior_photo': '$_templatesDir/interior_photo.jpg',
  };

  // —— Photoshoots — catalog id → asset slug (triplet: slug_1..3.jpg) ———————

  static const Map<String, String> photoshootAssetSlugById = {
    'studio_portrait': 'studio',
    'business_portrait': 'business',
    'home_portrait': 'home',
    'premium_portrait': 'premium',
    'winter_photoshoot': 'winter',
    'urban_portrait': 'city',
    'evening_look': 'evening',
    'travel_portrait': 'travel',
    'tender_photoshoot': 'tender',
    'summer_photoshoot': 'summer',
    'expert_photoshoot': 'expert',
    'business_brand': 'business_brand',
    'personal_brand': 'personal_brand',
    'cafe_city': 'cafe_city',
    'park_walk': 'park_walk',
    'custom_photoshoot': 'custom_photoshoot',
  };

  /// Three result previews per photoshoot style.
  static const Map<String, List<String>> photoshootTripletById = {
    'studio_portrait': [
      '$_photoshootsDir/studio_1.jpg',
      '$_photoshootsDir/studio_2.jpg',
      '$_photoshootsDir/studio_3.jpg',
    ],
    'business_portrait': [
      '$_photoshootsDir/business_1.jpg',
      '$_photoshootsDir/business_2.jpg',
      '$_photoshootsDir/business_3.jpg',
    ],
    'home_portrait': [
      '$_photoshootsDir/home_1.jpg',
      '$_photoshootsDir/home_2.jpg',
      '$_photoshootsDir/home_3.jpg',
    ],
    'premium_portrait': [
      '$_photoshootsDir/premium_1.jpg',
      '$_photoshootsDir/premium_2.jpg',
      '$_photoshootsDir/premium_3.jpg',
    ],
    'winter_photoshoot': [
      '$_photoshootsDir/winter_1.jpg',
      '$_photoshootsDir/winter_2.jpg',
      '$_photoshootsDir/winter_3.jpg',
    ],
    'urban_portrait': [
      '$_photoshootsDir/city_1.jpg',
      '$_photoshootsDir/city_2.jpg',
      '$_photoshootsDir/city_3.jpg',
    ],
    'evening_look': [
      '$_photoshootsDir/evening_1.jpg',
      '$_photoshootsDir/evening_2.jpg',
      '$_photoshootsDir/evening_3.jpg',
    ],
    'travel_portrait': [
      '$_photoshootsDir/travel_1.jpg',
      '$_photoshootsDir/travel_2.jpg',
      '$_photoshootsDir/travel_3.jpg',
    ],
    'tender_photoshoot': [
      '$_photoshootsDir/tender_1.jpg',
      '$_photoshootsDir/tender_2.jpg',
      '$_photoshootsDir/tender_3.jpg',
    ],
    'summer_photoshoot': [
      '$_photoshootsDir/summer_1.jpg',
      '$_photoshootsDir/summer_2.jpg',
      '$_photoshootsDir/summer_3.jpg',
    ],
    'expert_photoshoot': [
      '$_photoshootsDir/expert_1.jpg',
      '$_photoshootsDir/expert_2.jpg',
      '$_photoshootsDir/expert_3.jpg',
    ],
    'business_brand': [
      '$_photoshootsDir/business_brand_1.jpg',
      '$_photoshootsDir/business_brand_2.jpg',
      '$_photoshootsDir/business_brand_3.jpg',
    ],
    'personal_brand': [
      '$_photoshootsDir/personal_brand_1.jpg',
      '$_photoshootsDir/personal_brand_2.jpg',
      '$_photoshootsDir/personal_brand_3.jpg',
    ],
    'cafe_city': [
      '$_photoshootsDir/cafe_city_1.jpg',
      '$_photoshootsDir/cafe_city_2.jpg',
      '$_photoshootsDir/cafe_city_3.jpg',
    ],
    'park_walk': [
      '$_photoshootsDir/park_walk_1.jpg',
      '$_photoshootsDir/park_walk_2.jpg',
      '$_photoshootsDir/park_walk_3.jpg',
    ],
    'custom_photoshoot': [
      '$_photoshootsDir/custom_photoshoot_1.jpg',
      '$_photoshootsDir/custom_photoshoot_2.jpg',
      '$_photoshootsDir/custom_photoshoot_3.jpg',
    ],
  };

  static String templateAssetForId(String id) =>
      templateById[id] ?? '$_templatesDir/$id.jpg';

  static String? templatePathForId(String id) => templateAssetForId(id);

  static String photoshootAssetSlugForId(String id) =>
      photoshootAssetSlugById[id] ?? id;

  static List<String> photoshootTripletPathsForSlug(String slug) => [
        '$_photoshootsDir/${slug}_1.jpg',
        '$_photoshootsDir/${slug}_2.jpg',
        '$_photoshootsDir/${slug}_3.jpg',
      ];

  static List<String> photoshootPreviewAssetsForId(String id) {
    final explicit = photoshootTripletById[id];
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return photoshootTripletPathsForSlug(photoshootAssetSlugForId(id));
  }

  /// Hero preview for modals (first image of the triplet).
  static String? photoshootPathForId(String id) {
    final assets = photoshootPreviewAssetsForId(id);
    return assets.isEmpty ? null : assets.first;
  }

  // —— Photo quality guides ———————————————————————————————————————————————

  static const guidesGoodPhoto = 'assets/guides/good_photo.jpg';
  static const guidesBadPhoto = 'assets/guides/bad_photo.jpg';
}
