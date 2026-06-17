import 'package:flutter/material.dart';

/// Центральный dialog при временной ошибке генерации фотосессии.
class PhotoshootGenerationFailedDialog {
  PhotoshootGenerationFailedDialog._();

  static const _accentColor = Color(0xFF5B6CFF);

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Не удалось создать фотосессию',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Генерация временно не получилась. Попробуйте ещё раз через минуту.',
          style: TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF6B7280)),
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
}
