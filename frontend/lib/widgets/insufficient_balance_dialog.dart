import 'package:flutter/material.dart';

/// Понятные сообщения при 402 / нулевом балансе с переходом во вкладку «Пакеты».
class InsufficientBalanceDialog {
  InsufficientBalanceDialog._();

  static const _accentColor = Color(0xFF5B6CFF);

  static Future<void> showInsufficientImages(
    BuildContext context, {
    required VoidCallback onOpenPacks,
  }) {
    return _show(
      context,
      title: 'Изображения закончились',
      message:
          'У вас закончились доступные изображения. '
          'Пополните баланс, чтобы продолжить.',
      onOpenPacks: onOpenPacks,
    );
  }

  static Future<void> showInsufficientPhotoshoots(
    BuildContext context, {
    required VoidCallback onOpenPacks,
  }) {
    return _show(
      context,
      title: 'Фотосессии закончились',
      message:
          'У вас закончились доступные фотосессии. '
          'Пополните баланс, чтобы создать новую.',
      onOpenPacks: onOpenPacks,
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onOpenPacks,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
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
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Позже'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onOpenPacks();
            },
            style: FilledButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Пополнить баланс'),
          ),
        ],
      ),
    );
  }
}

/// Мягкое предупреждение над кнопкой генерации.
class InsufficientBalanceHint extends StatelessWidget {
  const InsufficientBalanceHint({
    super.key,
    required this.message,
    required this.onOpenPacks,
  });

  final String message;
  final VoidCallback onOpenPacks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5D0A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: const Color(0xFF9A5B00),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onOpenPacks,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFF5B6CFF),
              ),
              child: const Text('Пополнить баланс'),
            ),
          ),
        ],
      ),
    );
  }
}
