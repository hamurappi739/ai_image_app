import 'package:shared_preferences/shared_preferences.dart';

class PhotoshootsHelpService {
  PhotoshootsHelpService._();

  static const _seenKey = 'photoshoots_help_seen';

  static Future<bool> isSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> setSeen({bool seen = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, seen);
  }
}
