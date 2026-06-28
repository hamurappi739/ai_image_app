import 'package:flutter/material.dart';

import 'create_help_dialog.dart';
import 'gallery_help_dialog.dart';
import 'good_photo_help_dialog.dart';
import 'photoshoots_help_dialog.dart';
import 'quick_start_help_dialog.dart';
import 'template_help_dialog.dart';

class HelpGuidesSheet extends StatelessWidget {
  const HelpGuidesSheet({super.key});

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const HelpGuidesSheet(),
    );
  }

  void _openGuide(BuildContext context, VoidCallback showGuide) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showGuide();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Обучалки и подсказки',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Краткие инструкции по разделам приложения.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _GuideTile(
              icon: Icons.rocket_launch_outlined,
              title: 'Быстрый старт',
              onTap: () => _openGuide(context, () => QuickStartHelpDialog.show(context)),
            ),
            _GuideTile(
              icon: Icons.dashboard_customize_outlined,
              title: 'Фото по шаблону',
              onTap: () => _openGuide(context, () => TemplateHelpDialog.show(context)),
            ),
            _GuideTile(
              icon: Icons.photo_camera_outlined,
              title: 'Фотосессии',
              onTap: () =>
                  _openGuide(context, () => showDialog<void>(
                        context: context,
                        builder: (_) => const PhotoshootsHelpDialog(),
                      )),
            ),
            _GuideTile(
              icon: Icons.edit_outlined,
              title: 'Своя идея',
              onTap: () => _openGuide(context, () => showDialog<void>(
                    context: context,
                    builder: (_) => const CreateHelpDialog(),
                  )),
            ),
            _GuideTile(
              icon: Icons.face_retouching_natural_outlined,
              title: 'Хорошее фото',
              onTap: () => _openGuide(context, () => GoodPhotoHelpDialog.show(context)),
            ),
            _GuideTile(
              icon: Icons.photo_library_outlined,
              title: 'Галерея / готовые фото',
              onTap: () => _openGuide(context, () => GalleryHelpDialog.show(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: HelpGuidesSheet._accentColor),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: HelpGuidesSheet._textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: HelpGuidesSheet._textSecondary),
      onTap: onTap,
    );
  }
}
