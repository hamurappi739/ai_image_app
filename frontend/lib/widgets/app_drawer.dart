import 'package:flutter/material.dart';

import '../models/user_balance.dart';
import '../navigation/app_section.dart';
import 'app_balance_summary.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentSection,
    required this.onSectionSelected,
    this.onTrendingPhotoshootsTap,
    this.userEmail,
    this.userDisplayName,
    this.showUserBalance = false,
    this.balance,
    this.balanceLoading = false,
    this.balanceLoadFailed = false,
    this.onBuyTap,
  });

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  final AppSection currentSection;
  final ValueChanged<AppSection> onSectionSelected;
  final VoidCallback? onTrendingPhotoshootsTap;
  final String? userEmail;
  final String? userDisplayName;
  final bool showUserBalance;
  final UserBalance? balance;
  final bool balanceLoading;
  final bool balanceLoadFailed;
  final VoidCallback? onBuyTap;

  String _greetingLine() {
    final name = userDisplayName?.trim();
    if (name != null && name.isNotEmpty) {
      return 'Здравствуйте, $name';
    }
    return 'Здравствуйте';
  }

  void _goTo(BuildContext context, AppSection section) {
    Navigator.of(context).pop();
    onSectionSelected(section);
  }

  void _goToBuy(BuildContext context) {
    Navigator.of(context).pop();
    if (onBuyTap != null) {
      onBuyTap!();
      return;
    }
    onSectionSelected(AppSection.buy);
  }

  IconData _iconFor(AppSection section) => switch (section) {
        AppSection.home => Icons.home_outlined,
        AppSection.templatePhoto => Icons.dashboard_customize_outlined,
        AppSection.photoshoots => Icons.photo_camera_outlined,
        AppSection.customRequest => Icons.edit_outlined,
        AppSection.gallery => Icons.photo_library_outlined,
        AppSection.buy => Icons.shopping_bag_outlined,
        AppSection.profile => Icons.person_outline,
        AppSection.help => Icons.help_outline,
      };

  Widget _menuTile(
    BuildContext context, {
    required AppSection section,
    required String label,
    IconData? icon,
  }) {
    final selected = currentSection == section;
    return ListTile(
      leading: Icon(
        icon ?? _iconFor(section),
        color: selected ? _accentColor : _textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? _accentColor : _textPrimary,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFFEDE9FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: () => _goTo(context, section),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = userEmail?.trim();

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF5F7FF), Color(0xFFEDE9FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: _accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _greetingLine(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (showUserBalance)
                      AppDrawerBalanceBlock(
                        balance: balance,
                        isLoading: balanceLoading,
                        loadFailed: balanceLoadFailed,
                        onBuyTap: onBuyTap != null
                            ? () => _goToBuy(context)
                            : null,
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _menuTile(context, section: AppSection.home, label: 'Главная'),
                  _menuTile(
                    context,
                    section: AppSection.templatePhoto,
                    label: 'Фото по шаблону',
                  ),
                  _menuTile(
                    context,
                    section: AppSection.photoshoots,
                    label: 'Фотосессии',
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.trending_up,
                      color: currentSection == AppSection.photoshoots
                          ? _accentColor
                          : _textSecondary,
                    ),
                    title: Text(
                      'Трендовые фотосессии',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    onTap: () {
                      Navigator.of(context).pop();
                      if (onTrendingPhotoshootsTap != null) {
                        onTrendingPhotoshootsTap!();
                      } else {
                        onSectionSelected(AppSection.photoshoots);
                      }
                    },
                  ),
                  _menuTile(
                    context,
                    section: AppSection.customRequest,
                    label: 'Свой запрос',
                  ),
                  _menuTile(
                    context,
                    section: AppSection.gallery,
                    label: 'Готовые фото',
                  ),
                  _menuTile(context, section: AppSection.buy, label: 'Купить'),
                  _menuTile(
                    context,
                    section: AppSection.profile,
                    label: 'Профиль',
                  ),
                  _menuTile(context, section: AppSection.help, label: 'Помощь'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
