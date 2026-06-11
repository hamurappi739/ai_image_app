import 'package:flutter/material.dart';

import 'app_balance_summary.dart';
import 'app_navigation_scope.dart';

class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBalanceIndicator = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBalanceIndicator;

  static const _textPrimary = Color(0xFF1A1D26);

  Widget? _buildBalanceIndicator(BuildContext context, double maxWidth) {
    if (!showBalanceIndicator) return null;
    final scope = AppNavigationScope.maybeOf(context);
    if (scope == null || !scope.showUserBalance) return null;
    if (maxWidth < 300) return null;

    final hasTrailing = trailing != null;
    final ultraCompact = maxWidth < 360;
    final compact = maxWidth < 420 || hasTrailing;

    return AppHeaderBalanceIndicator(
      balance: scope.userBalance,
      isLoading: scope.balanceLoading,
      loadFailed: scope.balanceLoadFailed,
      compact: compact,
      ultraCompact: ultraCompact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = MediaQuery.sizeOf(context).width;
    final balanceIndicator = _buildBalanceIndicator(context, maxWidth);

    Widget? trailingRow;
    if (balanceIndicator != null || trailing != null) {
      trailingRow = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?balanceIndicator,
          if (balanceIndicator != null && trailing != null)
            const SizedBox(width: 6),
          ?trailing,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: AppNavigationScope.openDrawerOf(context),
          icon: const Icon(Icons.menu, size: 26),
          color: _textPrimary,
          tooltip: 'Меню',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.only(left: 0, right: 8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ...?switch (subtitle) {
                null => null,
                final subtitleText => [
                  const SizedBox(height: 6),
                  Text(
                    subtitleText,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              },
            ],
          ),
        ),
        ?trailingRow,
      ],
    );
  }
}
