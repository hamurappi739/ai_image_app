// Fallback local preview paths under `assets/previews/`.
//
// Primary source for catalog cards: `previewAsset` / `previewAssets` from
// `assets/catalog/templates.json` and `assets/catalog/photoshoots.json`
// (or the same fields from GET /catalog/*). This file is used only when those
// JSON fields are missing — e.g. embedded fallback catalog or incomplete entries.
//
// PreviewAssetImage loads bundled assets and shows VisualPlaceholder on error.

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
    'volcanic_gray_rock': '$_templatesDir/volcanic_gray_rock.jpg',
    'ocean_portrait': '$_templatesDir/ocean_portrait.jpg',
    'beach_sand_portrait': '$_templatesDir/beach_sand_portrait.jpg',
    'white_dress_yellow_meadow': '$_templatesDir/white_dress_yellow_meadow.jpg',
    'woman_with_cat': '$_templatesDir/woman_with_cat.jpg',
  };

  static String templateAssetForId(String id) =>
      templateById[id] ?? '$_templatesDir/$id.jpg';

  static String? templatePathForId(String id) => templateAssetForId(id);

  /// Fallback triplet when catalog JSON has no `previewAssets`.
  /// Matches catalog naming: `{style_id}_1.jpg` … `_3.jpg`.
  static List<String> photoshootPreviewAssetsForId(String id) => [
        '$_photoshootsDir/${id}_1.jpg',
        '$_photoshootsDir/${id}_2.jpg',
        '$_photoshootsDir/${id}_3.jpg',
      ];

  /// Hero preview for modals (first image of the triplet).
  static String? photoshootPathForId(String id) {
    final assets = photoshootPreviewAssetsForId(id);
    return assets.isEmpty ? null : assets.first;
  }

  // —— Photo quality guides ———————————————————————————————————————————————

  static const guidesGoodPhoto = 'assets/guides/good_photo.jpg';
  static const guidesBadPhoto = 'assets/guides/bad_photo.jpg';
}
