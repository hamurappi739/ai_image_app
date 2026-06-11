// Whitelist of preview assets that exist on disk and are safe to load.
// Image.asset is only called for paths listed here.

class PreviewAssetRegistry {
  PreviewAssetRegistry._();

  /// Paths currently bundled and ready to display.
  ///
  /// Empty until real preview files are added — UI uses Flutter placeholders.
  static const Set<String> availableAssets = {};

  static bool isAvailable(String? assetPath) {
    if (assetPath == null || assetPath.isEmpty) return false;
    return availableAssets.contains(assetPath);
  }
}
