import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/create_help_dialog.dart';
import '../widgets/home_help_dialog.dart';
import '../widgets/packs_help_dialog.dart';
import '../widgets/photoshoots_help_dialog.dart';
import '../widgets/template_help_dialog.dart';
import '../widgets/welcome_showcase_help_dialog.dart';

class HelpHubScreen extends StatelessWidget {
  const HelpHubScreen({super.key});

  void _openDialog(BuildContext context, Widget dialog) {
    showDialog<void>(context: context, builder: (_) => dialog);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppScreenHeader(
                    title: 'Помощь',
                    subtitle: 'Краткие подсказки по разделам приложения.',
                  ),
                  const SizedBox(height: 20),
                  _HelpTopicTile(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Что можно сделать в приложении',
                    subtitle:
                        'Коротко покажем шаблоны, фотосессии и свои идеи.',
                    onTap: () => _openDialog(
                      context,
                      const WelcomeShowcaseHelpDialog(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.home_outlined,
                    title: 'Главная',
                    subtitle: 'Меню и кнопка «Начать создавать».',
                    onTap: () => _openDialog(context, const HomeHelpDialog()),
                  ),
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.dashboard_customize_outlined,
                    title: 'Фото по шаблону',
                    subtitle: 'Как выбрать шаблон и создать фото.',
                    onTap: () =>
                        _openDialog(context, const TemplateHelpDialog()),
                  ),
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.photo_camera_outlined,
                    title: 'Фотосессии',
                    subtitle: 'Как выбрать стиль и получить 3 фото.',
                    onTap: () =>
                        _openDialog(context, const PhotoshootsHelpDialog()),
                  ),
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.edit_outlined,
                    title: 'Своя идея',
                    subtitle: 'Как описать свою идею и добавить фото.',
                    onTap: () =>
                        _openDialog(context, const CreateHelpDialog()),
                  ),
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Купить',
                    subtitle: 'Как пополнить баланс фото и фотосессий.',
                    onTap: () => _openDialog(context, const PacksHelpDialog()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Совет: если не знаете, с чего начать — на главной '
                    'нажмите «Начать создавать».',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: context.appColors.textSecondary,
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

class _HelpTopicTile extends StatelessWidget {
  const _HelpTopicTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final textPrimary = context.appTextPrimary;

    return Material(
      color: colors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.selectedTile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
