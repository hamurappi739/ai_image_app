import 'package:flutter/material.dart';

import '../widgets/app_screen_header.dart';
import '../widgets/create_help_dialog.dart';
import '../widgets/packs_help_dialog.dart';
import '../widgets/photoshoots_help_dialog.dart';

class HelpHubScreen extends StatelessWidget {
  const HelpHubScreen({super.key});

  static const _scaffoldBackground = Color(0xFFF7F8FC);
  static const _textSecondary = Color(0xFF6B7280);

  void _openDialog(BuildContext context, Widget dialog) {
    showDialog<void>(context: context, builder: (_) => dialog);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _scaffoldBackground,
      body: SafeArea(
        child: Center(
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
                    icon: Icons.dashboard_customize_outlined,
                    title: 'Фото по шаблону и свой запрос',
                    subtitle: 'Как начать и что писать в описании.',
                    onTap: () => _openDialog(
                      context,
                      const CreateHelpDialog(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.photo_camera_outlined,
                    title: 'Фотосессии',
                    subtitle: 'Как выбрать стиль и загрузить фото.',
                    onTap: () => _openDialog(
                      context,
                      const PhotoshootsHelpDialog(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HelpTopicTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Купить',
                    subtitle: 'Как пополнить баланс изображений.',
                    onTap: () => _openDialog(
                      context,
                      const PacksHelpDialog(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Совет: если не знаете, с чего начать — откройте '
                    '«Главная» и выберите «Фото по шаблону».',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: _textSecondary,
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
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
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
                  color: const Color(0xFFEDE9FF),
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
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: _textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
