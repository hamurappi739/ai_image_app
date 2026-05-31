import 'package:shared_preferences/shared_preferences.dart';

class CreateHelpService {
  CreateHelpService._();

  static const _seenKey = 'create_help_seen';

  static Future<bool> isSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> setSeen({bool seen = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, seen);
  }
}
