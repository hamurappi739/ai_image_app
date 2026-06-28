import 'package:flutter/material.dart';

import '../models/user_balance.dart';
import '../navigation/app_section.dart';
import '../theme/app_theme.dart';
import 'app_balance_summary.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentSection,
    required this.onSectionSelected,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.onTrendingPhotoshootsTap,
    this.onShowOnboardingAgain,
    this.onOpenHelpGuides,
    this.userEmail,
    this.userDisplayName,
    this.showUserBalance = false,
    this.balance,
    this.balanceLoading = false,
    this.balanceLoadFailed = false,
    this.onBuyTap,
  });

  final AppSection currentSection;
  final ValueChanged<AppSection> onSectionSelected;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback? onTrendingPhotoshootsTap;
  final VoidCallback? onShowOnboardingAgain;
  final VoidCallback? onOpenHelpGuides;
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

  void _onShowOnboardingAgain(BuildContext context) {
    Navigator.of(context).pop();
    onShowOnboardingAgain?.call();
  }

  void _onOpenHelpGuides(BuildContext context) {
    Navigator.of(context).pop();
    onOpenHelpGuides?.call();
  }

  void _onDarkThemeChanged(bool enabled) {
    onThemeModeChanged(enabled ? ThemeMode.dark : ThemeMode.light);
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
    final colors = context.appColors;
    final accent = context.appAccent;
    final textPrimary = context.appTextPrimary;
    final selected = currentSection == section;
    return ListTile(
      leading: Icon(
        icon ?? _iconFor(section),
        color: selected ? accent : colors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? accent : textPrimary,
        ),
      ),
      selected: selected,
      selectedTileColor: colors.selectedTile,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: () => _goTo(context, section),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final accent = context.appAccent;
    final textPrimary = context.appTextPrimary;
    final email = userEmail?.trim();
    final isDark = themeMode == ThemeMode.dark;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.drawerGradientStart,
                      colors.drawerGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.15),
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
                            color: colors.cardBackground.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _greetingLine(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
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
                          color: colors.textSecondary,
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
            Divider(height: 1, color: colors.borderColor),
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
                      color: colors.textSecondary,
                    ),
                    title: Text(
                      'Трендовые фотосессии',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.mutedBadgeFill,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'В разработке',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    onTap: () {
                      Navigator.of(context).pop();
                      onTrendingPhotoshootsTap?.call();
                    },
                  ),
                  _menuTile(
                    context,
                    section: AppSection.customRequest,
                    label: 'Своя идея',
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
            Divider(height: 1, color: colors.borderColor),
            ListTile(
              leading: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: colors.textSecondary,
              ),
              title: Text(
                'Тёмная тема',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              trailing: Switch.adaptive(
                value: isDark,
                onChanged: _onDarkThemeChanged,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              onTap: () => _onDarkThemeChanged(!isDark),
            ),
            if (onShowOnboardingAgain != null)
              ListTile(
                leading: Icon(
                  Icons.replay_outlined,
                  color: colors.textSecondary,
                ),
                title: Text(
                  'Показать обучалку снова',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                onTap: () => _onShowOnboardingAgain(context),
              ),
            if (onOpenHelpGuides != null)
              ListTile(
                leading: Icon(
                  Icons.menu_book_outlined,
                  color: colors.textSecondary,
                ),
                title: Text(
                  'Обучалки и подсказки',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                onTap: () => _onOpenHelpGuides(context),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
