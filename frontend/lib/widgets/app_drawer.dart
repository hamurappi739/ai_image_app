import 'package:flutter/material.dart';

import '../navigation/app_section.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentSection,
    required this.onSectionSelected,
    this.userEmail,
    this.userDisplayName,
  });

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  final AppSection currentSection;
  final ValueChanged<AppSection> onSectionSelected;
  final String? userEmail;
  final String? userDisplayName;

  static const _menuSections = [
    AppSection.home,
    AppSection.templatePhoto,
    AppSection.photoshoots,
    AppSection.customRequest,
    AppSection.gallery,
    AppSection.buy,
    AppSection.profile,
    AppSection.help,
  ];

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

  String _greetingLine() {
    final name = userDisplayName?.trim();
    if (name != null && name.isNotEmpty) {
      return 'Здравствуйте, $name';
    }
    return 'Здравствуйте';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greetingLine(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  if (userEmail != null && userEmail!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      userEmail!.trim(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final section in _menuSections)
                    ListTile(
                      leading: Icon(
                        _iconFor(section),
                        color: currentSection == section
                            ? _accentColor
                            : _textSecondary,
                      ),
                      title: Text(
                        section.drawerLabel,
                        style: TextStyle(
                          fontWeight: currentSection == section
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: currentSection == section
                              ? _accentColor
                              : _textPrimary,
                        ),
                      ),
                      selected: currentSection == section,
                      selectedTileColor: const Color(0xFFEDE9FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSectionSelected(section);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
