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
                        'Начните с простого шаблона, сделайте фотосессию '
                        'или создайте фото по своей идее.',
                    trailing: SectionHelpButton(
                      onPressed: () => HomeHelpDialog.show(context),
                    ),
                  ),
                  SizedBox(height: isCompact ? 16 : 20),
                  AspectRatio(
                    aspectRatio: isCompact ? 16 / 10 : 4 / 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFEDE9FF),
                            Color(0xFFC5D8FF),
                            Color(0xFF9BB0FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.photo_outlined,
                            size: isCompact ? 56 : 72,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          Positioned(
                            bottom: isCompact ? 14 : 20,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Ваше новое фото будет здесь',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 16 : 20),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: () =>
                          onNavigate(AppSection.templatePhoto),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.menu,
                        size: 20,
                        color: _accentColor.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Все разделы находятся в меню слева сверху.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            height: 1.4,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                    ],
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
