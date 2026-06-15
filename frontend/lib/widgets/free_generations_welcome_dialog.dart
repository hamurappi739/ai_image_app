import 'package:flutter/material.dart';

/// Welcome dialog about 3 free image generations for new / demo users.
class FreeGenerationsWelcomeDialog {
  FreeGenerationsWelcomeDialog._();

  static const _accentColor = Color(0xFF5B6CFF);

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Вам доступны 3 бесплатные генерации',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Попробуйте создать первые фото бесплатно. '
          'Для обычного фото нужна 1 генерация, для фотосессии — 3.',
          style: TextStyle(
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
            child: const Text('Начать'),
          ),
        ],
      ),
    );
  }
}
