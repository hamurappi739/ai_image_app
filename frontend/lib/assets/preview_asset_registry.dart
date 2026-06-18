// Auxiliary whitelist of bundled preview files known to exist on disk.
// Not the catalog source — cards use `previewAsset` / `previewAssets` from JSON.
// PreviewAssetImage still attempts any declared path and falls back on error.

class PreviewAssetRegistry {
  PreviewAssetRegistry._();

  /// Paths verified under `frontend/assets/previews/` (update when adding jpg/png).
  static const Set<String> availableAssets = {
    'assets/previews/photoshoots/business_portrait_1.jpg',
    'assets/previews/photoshoots/business_portrait_2.jpg',
    'assets/previews/photoshoots/business_portrait_3.jpg',
    'assets/previews/photoshoots/cafe_city_1.jpg',
    'assets/previews/photoshoots/cafe_city_2.jpg',
    'assets/previews/photoshoots/cafe_city_3.jpg',
    'assets/previews/photoshoots/evening_look_1.jpg',
    'assets/previews/photoshoots/evening_look_2.jpg',
    'assets/previews/photoshoots/evening_look_3.jpg',
    'assets/previews/photoshoots/home_portrait_1.jpg',
    'assets/previews/photoshoots/home_portrait_2.jpg',
    'assets/previews/photoshoots/home_portrait_3.jpg',
    'assets/previews/photoshoots/premium_portrait_1.jpg',
    'assets/previews/photoshoots/premium_portrait_2.jpg',
    'assets/previews/photoshoots/premium_portrait_3.jpg',
    'assets/previews/photoshoots/studio_portrait_1.jpg',
    'assets/previews/photoshoots/studio_portrait_2.jpg',
    'assets/previews/photoshoots/studio_portrait_3.jpg',
    'assets/previews/photoshoots/tender_photoshoot_1.jpg',
    'assets/previews/photoshoots/tender_photoshoot_2.jpg',
    'assets/previews/photoshoots/tender_photoshoot_3.jpg',
    'assets/previews/photoshoots/urban_portrait_1.jpg',
    'assets/previews/photoshoots/urban_portrait_2.jpg',
    'assets/previews/photoshoots/urban_portrait_3.jpg',
    'assets/previews/templates/beautiful_portrait.jpg',
    'assets/previews/templates/bright_look.jpg',
    'assets/previews/templates/business_portrait.jpg',
    'assets/previews/templates/expert_look.jpg',
    'assets/previews/templates/gentle_portrait.jpg',
    'assets/previews/templates/product_photo.jpg',
    'assets/previews/templates/resume_photo.jpg',
    'assets/previews/templates/social_photo.jpg',
    'assets/previews/templates/summer_portrait.jpg',
    'assets/previews/templates/winter_portrait.jpg',
  };

  static bool isAvailable(String? assetPath) {
    if (assetPath == null || assetPath.isEmpty) return false;
    return availableAssets.contains(assetPath);
  }
}
