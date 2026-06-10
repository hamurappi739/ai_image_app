import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/home_help_dialog.dart';
import '../widgets/section_help_button.dart';

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
                  _HomeHeroPreview(isCompact: isCompact),
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

class _HomeHeroPreview extends StatelessWidget {
  const _HomeHeroPreview({required this.isCompact});

  static const _accentColor = Color(0xFF5B6CFF);

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final heroHeight = isCompact ? 200.0 : 240.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: heroHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8EEF5),
                  Color(0xFFEDE9FF),
                  Color(0xFFC5D8FF),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 20,
                  child: Icon(
                    Icons.auto_awesome_outlined,
                    size: 22,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 24,
                  child: Icon(
                    Icons.spa_outlined,
                    size: 18,
                    color: _accentColor.withValues(alpha: 0.25),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isCompact ? 88 : 100,
                        height: isCompact ? 104 : 118,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(48),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.75),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.face_retouching_natural_outlined,
                          size: isCompact ? 40 : 46,
                          color: _accentColor.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        child: const Text(
                          'Ваш новый образ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1D26),
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            _HomeFeatureBadge(
              icon: Icons.dashboard_customize_outlined,
              label: 'Шаблоны',
            ),
            _HomeFeatureBadge(
              icon: Icons.photo_camera_outlined,
              label: 'Фотосессии',
            ),
            _HomeFeatureBadge(
              icon: Icons.edit_outlined,
              label: 'Свой запрос',
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeFeatureBadge extends StatelessWidget {
  const _HomeFeatureBadge({
    required this.icon,
    required this.label,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: _accentColor.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D26),
            ),
          ),
        ],
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
