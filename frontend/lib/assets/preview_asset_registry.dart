// Optional whitelist for assets that are known to exist at build time.
// PreviewAssetImage attempts to load any declared path and falls back on error;
// this set can be used elsewhere for eager checks if needed.

class PreviewAssetRegistry {
  PreviewAssetRegistry._();

  /// Paths verified to exist on disk (populate when adding bundled previews).
  static const Set<String> availableAssets = {};

  static bool isAvailable(String? assetPath) {
    if (assetPath == null || assetPath.isEmpty) return false;
    return availableAssets.contains(assetPath);
  }
}
