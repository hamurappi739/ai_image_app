import 'package:flutter/material.dart';

const _accentColor = Color(0xFF5B6CFF);

/// Returns `true` when the user confirms clearing the local gallery.
Future<bool> showGalleryClearConfirmDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final screenWidth = MediaQuery.sizeOf(dialogContext).width;
      final horizontalInset = screenWidth < 360 ? 16.0 : 24.0;

      return AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: horizontalInset,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Очистить галерею?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Все фото и фотосессии будут убраны из галереи приложения. '
            'Это действие нельзя отменить.',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 14 : 15,
              height: 1.45,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Очистить'),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}
