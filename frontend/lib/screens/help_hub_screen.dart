import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/create_help_dialog.dart';
import '../widgets/gallery_help_dialog.dart';
import '../widgets/good_photo_help_dialog.dart';
import '../widgets/photoshoots_help_dialog.dart';
import '../widgets/quick_start_help_dialog.dart';
import '../widgets/template_help_dialog.dart';

class HelpHubScreen extends StatelessWidget {
  const HelpHubScreen({
    super.key,
    this.onRestartOnboarding,
  });

  final VoidCallback? onRestartOnboarding;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppScreenHeader(
                    title: 'Помощь',
                    subtitle:
                        'Обучалки и подсказки по всем разделам приложения.',
                  ),
                  const SizedBox(height: 20),
                  _HelpTopicTile(
                    icon: Icons.rocket_launch_outlined,
                    title: 'Быстрый старт',
                    subtitle:
                        'Полная обучалка: шаблоны, фотосессии, галерея и баланс.',
                    onTap: () => QuickStartHelpDialog.show(context),
                  ),
                  if (onRestartOnboarding != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onRestartOnboarding,
                        icon: const Icon(Icons.replay_outlined, size: 18),
                        label: const Text('Пройти заново'),
                        style: TextButton.styleFrom(
                          foregroundColor: context.appAccent,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.dashboard_customize_outlined,
                    title: 'Фото по шаблону',
                    subtitle: 'Как выбрать шаблон и создать фото.',
                    onTap: () => TemplateHelpDialog.show(context),
                  ),
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.photo_camera_outlined,
                    title: 'Фотосессии',
                    subtitle: 'Как выбрать стиль и получить 3 фото.',
                    onTap: () => PhotoshootsHelpDialog.show(context),
                  ),
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.edit_outlined,
                    title: 'Своя идея',
                    subtitle: 'Как описать свою идею и добавить фото.',
                    onTap: () => CreateHelpDialog.show(context),
                  ),
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.face_retouching_natural_outlined,
                    title: 'Как выбрать хорошее фото',
                    subtitle: 'Примеры удачных и неудачных исходников.',
                    onTap: () => GoodPhotoHelpDialog.show(context),
                  ),
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.photo_library_outlined,
                    title: 'Галерея и скачивание',
                    subtitle: 'Где найти результаты и как сохранить на устройство.',
                    onTap: () => GalleryHelpDialog.show(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Совет: если не знаете, с чего начать — на главной '
                    'нажмите «Начать создавать».',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
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

class _HelpTopicTile extends StatelessWidget {
  const _HelpTopicTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final textPrimary = context.appTextPrimary;
    final accent = context.appAccent;

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
                child: Icon(icon, color: accent),
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
