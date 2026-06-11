import 'package:flutter/material.dart';

import '../assets/preview_asset_paths.dart';
import '../navigation/app_section.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/home_help_dialog.dart';
import '../widgets/section_help_button.dart';
import '../widgets/visual_placeholder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onNavigate,
  });

  static const _scaffoldBackground = Color(0xFFF7F8FC);
  static const _accentColor = Color(0xFF5B6CFF);
  static const _textSecondary = Color(0xFF6B7280);

  final ValueChanged<AppSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenHeight < 720;

    return Scaffold(
      backgroundColor: _scaffoldBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                12,
                isCompact ? 4 : 8,
                20,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppScreenHeader(
                    title: 'Создавайте красивые фото',
                    subtitle:
                        'Выберите шаблон, добавьте своё фото — '
                        'и получите новый образ.',
                    trailing: SectionHelpButton(
                      onPressed: () => HomeHelpDialog.show(context),
                    ),
                  ),
                  SizedBox(height: isCompact ? 16 : 20),
                  VisualPlaceholderHero(
                    isCompact: isCompact,
                    previewAssetPath: PreviewAssetPaths.homeHero,
                  ),
                  SizedBox(height: isCompact ? 18 : 22),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: () =>
                          onNavigate(AppSection.templatePhoto),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Начать создавать'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackChips = constraints.maxWidth < 340;

                      final chips = [
                        _HomeQuickActionChip(
                          label: 'Сделать фотосессию',
                          icon: Icons.photo_camera_outlined,
                          onTap: () => onNavigate(AppSection.photoshoots),
                        ),
                        _HomeQuickActionChip(
                          label: 'Посмотреть готовые фото',
                          icon: Icons.photo_library_outlined,
                          onTap: () => onNavigate(AppSection.gallery),
                        ),
                      ];

                      if (stackChips) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            chips[0],
                            const SizedBox(height: 8),
                            chips[1],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: chips[0]),
                          const SizedBox(width: 10),
                          Expanded(child: chips[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE8EAEF),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.menu,
                            size: 20,
                            color: _accentColor.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Все разделы — в меню слева сверху.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 1.4,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeQuickActionChip extends StatelessWidget {
  const _HomeQuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _accentColor.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: _accentColor.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: Color(0xFF1A1D26),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
