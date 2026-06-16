import 'package:flutter/material.dart';

/// User-facing auth dialogs (no technical terms).
class ProfileAuthDialogs {
  ProfileAuthDialogs._();

  static const _accentColor = Color(0xFF5B6CFF);

  static Future<void> _showOkDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Color(0xFF6B7280),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Хорошо'),
          ),
        ],
      ),
    );
  }

  static Future<void> showVkComingSoon(BuildContext context) {
    return _showOkDialog(
      context,
      title: 'VK ID скоро появится',
      message: 'Мы добавим вход через VK ID в одной из следующих версий.',
    );
  }

  static Future<void> showYandexComingSoon(BuildContext context) {
    return _showOkDialog(
      context,
      title: 'Яндекс ID скоро появится',
      message: 'Мы добавим вход через Яндекс ID в одной из следующих версий.',
    );
  }

  static Future<void> showEmailUnavailable(BuildContext context) {
    return _showOkDialog(
      context,
      title: 'Вход недоступен',
      message: 'В этой демо-сборке вход по почте пока не настроен.',
    );
  }
}
