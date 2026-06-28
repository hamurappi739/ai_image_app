import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../navigation/app_section.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/home_help_dialog.dart';
import '../widgets/section_help_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onNavigate,
  });

  final ValueChanged<AppSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppScreenHeader(
                    title: 'Создавайте красивые фото',
                    subtitle: 'Выберите, с чего хотите начать.',
                    trailing: SectionHelpButton(
                      onPressed: () => HomeHelpDialog.show(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _HomeActionCard(
                    title: 'Фото по шаблону',
                    subtitle: 'Выберите шаблон и добавьте своё фото',
                    icon: Icons.dashboard_customize_outlined,
                    emphasized: true,
                    onTap: () => onNavigate(AppSection.templatePhoto),
                  ),
                  const SizedBox(height: 12),
                  _HomeActionCard(
                    title: 'Сделать фотосессию',
                    subtitle: 'Серия из 3 фото в одном стиле',
                    icon: Icons.photo_camera_outlined,
                    onTap: () => onNavigate(AppSection.photoshoots),
                  ),
                  const SizedBox(height: 12),
                  _HomeActionCard(
                    title: 'Посмотреть готовые фото',
                    subtitle: 'Ваши созданные результаты',
                    icon: Icons.photo_library_outlined,
                    onTap: () => onNavigate(AppSection.gallery),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Все разделы находятся в меню слева сверху.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      color: colors.textSecondary,
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

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.emphasized = false,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textPrimary = context.appTextPrimary;

    return Material(
      color: emphasized ? _accentColor : colors.cardBackground,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: emphasized
                ? null
                : Border.all(color: _accentColor.withValues(alpha: 0.22)),
            boxShadow: emphasized
                ? [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.2
                            : 0.04,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: emphasized
                      ? Colors.white.withValues(alpha: 0.18)
                      : _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: emphasized ? Colors.white : _accentColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: emphasized ? Colors.white : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: emphasized
                            ? Colors.white.withValues(alpha: 0.88)
                            : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: emphasized
                    ? Colors.white.withValues(alpha: 0.9)
                    : _accentColor.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
