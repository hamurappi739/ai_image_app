import 'package:shared_preferences/shared_preferences.dart';

class GalleryHiddenPreferences {
  GalleryHiddenPreferences._();

  static const _imageKeysKey = 'gallery_hidden_image_keys';
  static const _photoshootIdsKey = 'gallery_hidden_photoshoot_ids';

  static Future<({Set<String> imageKeys, Set<String> photoshootIds})> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      imageKeys: (prefs.getStringList(_imageKeysKey) ?? const []).toSet(),
      photoshootIds: (prefs.getStringList(_photoshootIdsKey) ?? const []).toSet(),
    );
  }

  static Future<void> save({
    required Set<String> imageKeys,
    required Set<String> photoshootIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_imageKeysKey, imageKeys.toList()..sort());
    await prefs.setStringList(_photoshootIdsKey, photoshootIds.toList()..sort());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_imageKeysKey);
    await prefs.remove(_photoshootIdsKey);
  }
}
