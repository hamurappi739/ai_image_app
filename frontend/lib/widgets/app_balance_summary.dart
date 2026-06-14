import 'package:flutter/material.dart';

import '../models/user_balance.dart';

/// Shared balance copy for drawer, header, and profile-aligned labels.
class AppBalanceSummary {
  const AppBalanceSummary._();

  static const accentColor = Color(0xFF5B6CFF);
  static const textPrimary = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF6B7280);

  static int imageCount(UserBalance balance) => balance.totalAvailableImages;

  static int freePhotoCount(UserBalance balance) =>
      balance.freeGenerationsRemaining;

  static bool showFreePhotos(UserBalance balance) =>
      balance.freeGenerationsRemaining > 0;

  static String photoshootCostNote(UserBalance balance) =>
      'Фотосессия = ${balance.photoshootImageCost} изображения';
}

class AppDrawerBalanceBlock extends StatelessWidget {
  const AppDrawerBalanceBlock({
    super.key,
    required this.balance,
    required this.isLoading,
    required this.loadFailed,
    this.onBuyTap,
  });

  final UserBalance? balance;
  final bool isLoading;
  final bool loadFailed;
  final VoidCallback? onBuyTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20, thickness: 1, color: Color(0xFFE5E7EB)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Ваш баланс',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppBalanceSummary.textPrimary,
                ),
              ),
            ),
            if (onBuyTap != null)
              TextButton(
                onPressed: onBuyTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppBalanceSummary.accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Купить',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          Text(
            'Загружаем баланс…',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: AppBalanceSummary.textSecondary,
            ),
          )
        else if (loadFailed)
          Text(
            'Баланс пока не загружен',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: AppBalanceSummary.textSecondary,
            ),
          )
        else if (balance != null) ...[
          _DrawerBalanceLine(
            label: 'Изображения',
            value: '${AppBalanceSummary.imageCount(balance!)}',
          ),
          if (AppBalanceSummary.showFreePhotos(balance!)) ...[
            const SizedBox(height: 4),
            _DrawerBalanceLine(
              label: 'Бесплатные',
              value: '${AppBalanceSummary.freePhotoCount(balance!)}',
            ),
          ],
          const SizedBox(height: 6),
          Text(
            AppBalanceSummary.photoshootCostNote(balance!),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.35,
              color: AppBalanceSummary.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _DrawerBalanceLine extends StatelessWidget {
  const _DrawerBalanceLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppBalanceSummary.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: AppBalanceSummary.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Calm balance block for section screens (not header).
class AppScreenBalanceCard extends StatelessWidget {
  const AppScreenBalanceCard({
    super.key,
    required this.balance,
    required this.isLoading,
    this.showPhotoshootCostHint = false,
  });

  final UserBalance? balance;
  final bool isLoading;
  final bool showPhotoshootCostHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ваш баланс',
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppBalanceSummary.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (isLoading && balance == null)
            Text(
              'Загружаем баланс…',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: AppBalanceSummary.textSecondary,
              ),
            )
          else if (balance != null) ...[
            _ScreenBalanceLine(
              label: 'Изображения',
              value: '${AppBalanceSummary.imageCount(balance!)}',
            ),
            if (AppBalanceSummary.showFreePhotos(balance!)) ...[
              const SizedBox(height: 4),
              _ScreenBalanceLine(
                label: 'Бесплатные',
                value: '${AppBalanceSummary.freePhotoCount(balance!)}',
              ),
            ],
            if (showPhotoshootCostHint) ...[
              const SizedBox(height: 8),
              Text(
                AppBalanceSummary.photoshootCostNote(balance!),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  height: 1.35,
                  color: AppBalanceSummary.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Доступно изображений: ${AppBalanceSummary.imageCount(balance!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  height: 1.35,
                  color: AppBalanceSummary.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ScreenBalanceLine extends StatelessWidget {
  const _ScreenBalanceLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppBalanceSummary.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: AppBalanceSummary.textPrimary,
          ),
        ),
      ],
    );
  }
}

class AppHeaderBalanceIndicator extends StatelessWidget {
  const AppHeaderBalanceIndicator({
    super.key,
    required this.balance,
    required this.isLoading,
    required this.loadFailed,
    this.compact = false,
    this.ultraCompact = false,
  });

  final UserBalance? balance;
  final bool isLoading;
  final bool loadFailed;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    if (loadFailed || (balance == null && !isLoading)) {
      return const SizedBox.shrink();
    }

    if (isLoading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final images = AppBalanceSummary.imageCount(balance!);
    final label = ultraCompact ? '$images' : 'Изображения: $images';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ultraCompact ? 8 : 10,
        vertical: ultraCompact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppBalanceSummary.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_outlined,
            size: ultraCompact ? 14 : 15,
            color: AppBalanceSummary.accentColor,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppBalanceSummary.textPrimary,
              ),
            ),
          ] else ...[
            const SizedBox(width: 3),
            Text(
              '$images',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppBalanceSummary.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
