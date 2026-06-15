import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the free-generations welcome dialog was shown.
class FreeGenerationsWelcomeService {
  FreeGenerationsWelcomeService._();

  static const _seenKey = 'free_generations_welcome_seen';

  /// In-memory guard for the current app session.
  static bool shownThisSession = false;

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> markSeen() async {
    shownThisSession = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  static Future<void> reset() async {
    shownThisSession = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, false);
  }
}
