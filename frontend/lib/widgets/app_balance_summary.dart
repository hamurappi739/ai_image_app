import 'package:flutter/material.dart';

import '../models/user_balance.dart';
import '../theme/app_theme.dart';

/// Shared balance copy for drawer, header, and profile-aligned labels.
class AppBalanceSummary {
  const AppBalanceSummary._();

  static const accentColor = Color(0xFF5B6CFF);

  static int imageCount(UserBalance balance) => balance.totalAvailableImages;

  static int freePhotoCount(UserBalance balance) =>
      balance.freeGenerationsRemaining;

  static bool showFreePhotos(UserBalance balance) =>
      balance.freeGenerationsRemaining > 0;

  static String photoshootCostNote(UserBalance balance) =>
      'Фотосессия = ${balance.photoshootImageCost} фото';
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
    final colors = context.appColors;
    final textPrimary = context.appTextPrimary;
    final accent = context.appAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 20, thickness: 1, color: colors.borderColor),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Ваш баланс',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
            if (onBuyTap != null)
              TextButton(
                onPressed: onBuyTap,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  backgroundColor: accent.withValues(alpha: 0.16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Купить',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
              color: colors.textSecondary,
            ),
          )
        else if (loadFailed)
          Text(
            'Баланс пока не загружен',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          )
        else if (balance != null) ...[
          _DrawerBalanceLine(
            label: 'Фото',
            value: '${AppBalanceSummary.imageCount(balance!)}',
          ),
          if (AppBalanceSummary.showFreePhotos(balance!)) ...[
            const SizedBox(height: 4),
            _DrawerBalanceLine(
              label: 'Бесплатные генерации',
              value: '${AppBalanceSummary.freePhotoCount(balance!)}',
            ),
          ],
          const SizedBox(height: 6),
          Text(
            AppBalanceSummary.photoshootCostNote(balance!),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.35,
              color: colors.textSecondary,
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
    final colors = context.appColors;
    final textPrimary = context.appTextPrimary;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: textPrimary,
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
    final colors = context.appColors;
    final textPrimary = context.appTextPrimary;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ваш баланс',
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (isLoading && balance == null)
            Text(
              'Загружаем баланс…',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            )
          else if (balance != null) ...[
            _ScreenBalanceLine(
              label: 'Фото',
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
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Доступно фото: ${AppBalanceSummary.imageCount(balance!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  height: 1.35,
                  color: colors.textSecondary,
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
    final colors = context.appColors;
    final textPrimary = context.appTextPrimary;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: textPrimary,
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

    final colors = context.appColors;
    final textPrimary = context.appTextPrimary;
    final accent = context.appAccent;
    final images = AppBalanceSummary.imageCount(balance!);
    final label = ultraCompact ? '$images' : 'Фото: $images';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ultraCompact ? 8 : 10,
        vertical: ultraCompact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: colors.accentTintFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_outlined,
            size: ultraCompact ? 14 : 15,
            color: accent,
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ] else ...[
            const SizedBox(width: 3),
            Text(
              '$images',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
