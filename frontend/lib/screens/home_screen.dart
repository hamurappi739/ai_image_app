import 'package:flutter/material.dart';

import '../navigation/app_section.dart';
import '../widgets/app_screen_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onNavigate,
  });

  static const _scaffoldBackground = Color(0xFFF7F8FC);
  static const _textSecondary = Color(0xFF6B7280);

  final ValueChanged<AppSection> onNavigate;

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
                  AppScreenHeader(
                    title: 'Что хотите сделать?',
                    subtitle:
                        'Начните с простого варианта. Потом можно перейти '
                        'к фотосессии или своему запросу.',
                  ),
                  const SizedBox(height: 24),
                  _HomeActionCard(
                    icon: Icons.dashboard_customize_outlined,
                    iconColors: const [Color(0xFFEDE9FF), Color(0xFFD4CCFF)],
                    title: 'Фото по шаблону',
                    description:
                        'Самый простой способ. Выберите готовый вариант — '
                        'приложение само подготовит описание.',
                    buttonLabel: 'Выбрать шаблон',
                    onPressed: () => onNavigate(AppSection.templatePhoto),
                  ),
                  const SizedBox(height: 16),
                  _HomeActionCard(
                    icon: Icons.photo_camera_outlined,
                    iconColors: const [Color(0xFFE8F0FF), Color(0xFFC5D8FF)],
                    title: 'Фотосессии',
                    description: 'Получите серию из 3 фото в одном стиле.',
                    buttonLabel: 'Сделать фотосессию',
                    onPressed: () => onNavigate(AppSection.photoshoots),
                  ),
                  const SizedBox(height: 16),
                  _HomeActionCard(
                    icon: Icons.edit_outlined,
                    iconColors: const [Color(0xFFF0F2F8), Color(0xFFDDE2EE)],
                    title: 'Свой запрос',
                    description:
                        'Опишите свою идею, если не нашли подходящий шаблон.',
                    buttonLabel: 'Написать запрос',
                    onPressed: () => onNavigate(AppSection.customRequest),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Подсказка: если не знаете, с чего начать — '
                    'откройте «Фото по шаблону».',
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

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.iconColors,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  final IconData icon;
  final List<Color> iconColors;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: iconColors,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: _accentColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.45,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
