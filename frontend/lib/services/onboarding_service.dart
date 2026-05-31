import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  OnboardingService._();

  static const _completedKey = 'onboarding_completed';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<void> setCompleted({bool completed = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, completed);
  }

  static Future<void> reset() => setCompleted(completed: false);
}
