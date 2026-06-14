import 'package:flutter/material.dart';

/// Понятные сообщения при 402 / нулевом балансе с переходом в раздел «Купить».
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
      message: 'Чтобы создать новое фото, пополните баланс.',
      buyButtonLabel: 'Купить изображения',
      onOpenPacks: onOpenPacks,
    );
  }

  static Future<void> showInsufficientPhotoshoots(
    BuildContext context, {
    required VoidCallback onOpenPacks,
  }) {
    return _show(
      context,
      title: 'Нужно 3 изображения',
      message:
          'Фотосессия создаёт 3 фото, поэтому для неё нужно 3 изображения '
          'на балансе.',
      buyButtonLabel: 'Купить изображения',
      onOpenPacks: onOpenPacks,
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String title,
    required String message,
    required String buyButtonLabel,
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
            child: Text(buyButtonLabel),
          ),
        ],
      ),
    );
  }
}

/// Распознаёт технические тексты ошибок баланса для замены на понятные сообщения.
class InsufficientBalanceMessages {
  InsufficientBalanceMessages._();

  static bool looksLikeInsufficientImages(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.contains('insufficient_images') ||
        normalized.contains('insufficient images') ||
        normalized == '402' ||
        normalized.contains('payment required') ||
        (normalized.contains('insufficient') &&
            !normalized.contains('photoshoot'));
  }

  static bool looksLikeInsufficientPhotoshoots(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.contains('insufficient_photoshoots') ||
        normalized.contains('insufficient photoshoots') ||
        (normalized.contains('insufficient') && normalized.contains('photoshoot'));
  }

  static bool looksLikePaymentRequired(String message) {
    final normalized = message.trim().toLowerCase();
    return normalized.contains('payment required') ||
        normalized.contains('credits') ||
        normalized == '402';
  }
}

/// Мягкое предупреждение при нулевом балансе.
class InsufficientBalanceHint extends StatelessWidget {
  const InsufficientBalanceHint({
    super.key,
    required this.message,
    required this.onOpenPacks,
    this.actionLabel = 'Купить изображения',
  });

  final String message;
  final VoidCallback onOpenPacks;
  final String actionLabel;

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
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
