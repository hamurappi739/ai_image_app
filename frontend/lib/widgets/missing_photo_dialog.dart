import 'package:flutter/material.dart';

/// Центральный dialog, когда пользователь пытается создать фото без прикреплённого изображения.
class MissingPhotoDialog {
  MissingPhotoDialog._();

  static const _accentColor = Color(0xFF5B6CFF);

  static Future<void> showForTemplateOrCustom(BuildContext context) {
    return _show(
      context,
      message: 'Сначала выберите фото, с которым хотите работать.',
    );
  }

  static Future<void> showForPhotoshoot(BuildContext context) {
    return _show(
      context,
      message: 'Сначала выберите фото для фотосессии.',
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Добавьте фото',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
}
