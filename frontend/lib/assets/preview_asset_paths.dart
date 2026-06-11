// Planned local preview image paths under `assets/previews/`.
// Files are not bundled until added to disk and registered in
// PreviewAssetRegistry. Until then, UI falls back to Flutter placeholders.

class PreviewAssetPaths {
  PreviewAssetPaths._();

  // —— Common ———————————————————————————————————————————————————————————————

  static const homeHero = 'assets/previews/common/home_hero.png';

  // —— Templates (planned filenames) ——————————————————————————————————————

  static const templatesPortraitSoft =
      'assets/previews/templates/portrait_soft.png';
  static const templatesSocialProfile =
      'assets/previews/templates/social_profile.png';
  static const templatesWinterPortrait =
      'assets/previews/templates/winter_portrait.png';
  static const templatesSummerPortrait =
      'assets/previews/templates/summer_portrait.png';
  static const templatesBusinessPortrait =
      'assets/previews/templates/business_portrait.png';
  static const templatesResumePhoto =
      'assets/previews/templates/resume_photo.png';
  static const templatesFamilyPhoto =
      'assets/previews/templates/family_photo.png';
  static const templatesProductPhoto =
      'assets/previews/templates/product_photo.png';
  static const templatesInteriorPhoto =
      'assets/previews/templates/interior_photo.png';

  // —— Photoshoots (planned filenames) —————————————————————————————————————

  static const photoshootsStudioPortrait =
      'assets/previews/photoshoots/studio_portrait.png';
  static const photoshootsBusinessPortrait =
      'assets/previews/photoshoots/business_portrait.png';
  static const photoshootsCityPortrait =
      'assets/previews/photoshoots/city_portrait.png';
  static const photoshootsEveningStyle =
      'assets/previews/photoshoots/evening_style.png';
  static const photoshootsWinterPhotoshoot =
      'assets/previews/photoshoots/winter_photoshoot.png';
  static const photoshootsHomePortrait =
      'assets/previews/photoshoots/home_portrait.png';
  static const photoshootsTravelPortrait =
      'assets/previews/photoshoots/travel_portrait.png';
  static const photoshootsPremiumPortrait =
      'assets/previews/photoshoots/premium_portrait.png';
  static const photoshootsCustomPhotoshoot =
      'assets/previews/photoshoots/custom_photoshoot.png';

  /// Maps template catalog [id] → planned asset path (may be unbundled).
  static const Map<String, String> templateById = {
    'beautiful_portrait': templatesPortraitSoft,
    'tender_portrait': templatesPortraitSoft,
    'social_photo': templatesSocialProfile,
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
  };

  /// Maps photoshoot style [id] → planned asset path (may be unbundled).
  static const Map<String, String> photoshootById = {
    'studio_portrait': photoshootsStudioPortrait,
    'business_portrait': photoshootsBusinessPortrait,
    'urban_portrait': photoshootsCityPortrait,
    'city_portrait': photoshootsCityPortrait,
    'evening_look': photoshootsEveningStyle,
    'winter_photoshoot': photoshootsWinterPhotoshoot,
    'home_portrait': photoshootsHomePortrait,
    'travel_portrait': photoshootsTravelPortrait,
    'premium_portrait': photoshootsPremiumPortrait,
    'custom_photoshoot': photoshootsCustomPhotoshoot,
  };

  // TODO(preview-assets): when illustration files are added, register each path
  // in [PreviewAssetRegistry.availableAssets]. Planned catalog:
  //
  // Templates: portrait_soft, social_profile, winter_portrait, summer_portrait,
  //   business_portrait, resume_photo, family_photo, product_photo, interior_photo
  //
  // Photoshoots: studio_portrait, business_portrait, city_portrait, evening_style,
  //   winter_photoshoot, home_portrait, travel_portrait, premium_portrait,
  //   custom_photoshoot
  //
  // Home: home_hero

  static String? templatePathForId(String id) => templateById[id];

  static String? photoshootPathForId(String id) => photoshootById[id];
}
