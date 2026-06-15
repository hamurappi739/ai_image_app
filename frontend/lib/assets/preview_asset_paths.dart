// Planned local preview image paths under `assets/previews/`.
// Files are not bundled until added to disk and registered in
// PreviewAssetRegistry. Until then, UI falls back to Flutter placeholders.

class PreviewAssetPaths {
  PreviewAssetPaths._();

  // —— Common ———————————————————————————————————————————————————————————————

  static const homeHero = 'assets/previews/common/home_hero.png';

  // —— Templates (planned .jpg / .png filenames) —————————————————————————

  static const templatesBeautifulPortrait =
      'assets/previews/templates/beautiful_portrait.jpg';
  static const templatesBusinessPortrait =
      'assets/previews/templates/business_portrait.jpg';
  static const templatesSocialPhoto =
      'assets/previews/templates/social_photo.jpg';
  static const templatesProductPhoto =
      'assets/previews/templates/product_photo.jpg';
  static const templatesWinterPortrait =
      'assets/previews/templates/winter_portrait.jpg';
  static const templatesSummerPortrait =
      'assets/previews/templates/summer_portrait.jpg';
  static const templatesResumePhoto =
      'assets/previews/templates/resume_photo.jpg';
  static const templatesFamilyPhoto =
      'assets/previews/templates/family_photo.jpg';
  static const templatesInteriorPhoto =
      'assets/previews/templates/interior_photo.jpg';
  static const templatesPortraitSoft =
      'assets/previews/templates/portrait_soft.png';

  // —— Photoshoot singles (legacy card hero) —————————————————————————————

  static const photoshootsStudioPortrait =
      'assets/previews/photoshoots/studio_portrait.png';
  static const photoshootsBusinessPortrait =
      'assets/previews/photoshoots/business_portrait.png';

  // —— Photoshoot triplets (planned .jpg series) ———————————————————————————

  static const photoshootsBusiness1 =
      'assets/previews/photoshoots/business_1.jpg';
  static const photoshootsBusiness2 =
      'assets/previews/photoshoots/business_2.jpg';
  static const photoshootsBusiness3 =
      'assets/previews/photoshoots/business_3.jpg';
  static const photoshootsStudio1 =
      'assets/previews/photoshoots/studio_1.jpg';
  static const photoshootsStudio2 =
      'assets/previews/photoshoots/studio_2.jpg';
  static const photoshootsStudio3 =
      'assets/previews/photoshoots/studio_3.jpg';

  /// Maps template catalog [id] → planned asset path (may be unbundled).
  static const Map<String, String> templateById = {
    'beautiful_portrait': templatesBeautifulPortrait,
    'tender_portrait': templatesPortraitSoft,
    'social_photo': templatesSocialPhoto,
    'winter_portrait': templatesWinterPortrait,
    'summer_portrait': templatesSummerPortrait,
    'business_portrait': templatesBusinessPortrait,
    'resume_photo': templatesResumePhoto,
    'family_photo': templatesFamilyPhoto,
    'photo_with_child': templatesFamilyPhoto,
    'product_photo': templatesProductPhoto,
    'clothing_photo': templatesProductPhoto,
    'jewelry_photo': templatesProductPhoto,
    'interior_photo': templatesInteriorPhoto,
    'profile_photo': templatesSocialPhoto,
    'expert_look': templatesBusinessPortrait,
    'vibrant_look': templatesBeautifulPortrait,
  };

  /// Maps photoshoot style [id] → planned hero asset (legacy / modal).
  static const Map<String, String> photoshootById = {
    'studio_portrait': photoshootsStudioPortrait,
    'business_portrait': photoshootsBusinessPortrait,
    'urban_portrait': photoshootsBusinessPortrait,
    'city_portrait': photoshootsBusinessPortrait,
    'evening_look': photoshootsStudioPortrait,
    'winter_photoshoot': photoshootsStudioPortrait,
    'home_portrait': photoshootsStudioPortrait,
    'travel_portrait': photoshootsStudioPortrait,
    'premium_portrait': photoshootsBusinessPortrait,
    'custom_photoshoot': photoshootsStudioPortrait,
  };

  /// Three result previews per photoshoot style (may be unbundled).
  static const Map<String, List<String>> photoshootTripletById = {
    'studio_portrait': [
      photoshootsStudio1,
      photoshootsStudio2,
      photoshootsStudio3,
    ],
    'business_portrait': [
      photoshootsBusiness1,
      photoshootsBusiness2,
      photoshootsBusiness3,
    ],
    'urban_portrait': [
      photoshootsBusiness1,
      photoshootsBusiness2,
      photoshootsBusiness3,
    ],
    'city_portrait': [
      photoshootsBusiness1,
      photoshootsBusiness2,
      photoshootsBusiness3,
    ],
  };

  static String templateAssetForId(String id) =>
      templateById[id] ?? 'assets/previews/templates/$id.jpg';

  static String? templatePathForId(String id) => templateAssetForId(id);

  static String? photoshootPathForId(String id) => photoshootById[id];

  static List<String> photoshootPreviewAssetsForId(String id) {
    final explicit = photoshootTripletById[id];
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return [
      'assets/previews/photoshoots/${id}_1.jpg',
      'assets/previews/photoshoots/${id}_2.jpg',
      'assets/previews/photoshoots/${id}_3.jpg',
    ];
  }
}
