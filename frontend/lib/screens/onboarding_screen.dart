import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _accentColor = Color(0xFF5B6CFF);
  static const _pages = [
    _OnboardingPage(
      title: 'Добро пожаловать',
      body:
          'Создавайте изображения и фотосессии из своих идей и фотографий.',
      icon: Icons.auto_awesome_outlined,
    ),
    _OnboardingPage(
      title: 'Раздел «Создать»',
      body:
          'Опишите идею словами, и приложение подготовит изображение. '
          'Позже здесь можно будет добавлять фото для одиночных образов.',
      icon: Icons.edit_outlined,
    ),
    _OnboardingPage(
      title: 'Фотосессии',
      body:
          'Выберите стиль, загрузите своё фото и получите несколько '
          'готовых изображений в одном образе.',
      icon: Icons.photo_camera_outlined,
    ),
    _OnboardingPage(
      title: 'Хорошее исходное фото',
      body:
          'Лучше всего подходят чёткие фото, где хорошо видно лицо. '
          'Размытые или тёмные фото могут ухудшить результат.',
      icon: Icons.face_retouching_natural_outlined,
    ),
    _OnboardingPage(
      title: 'Галерея',
      body:
          'Готовые изображения и фотосессии сохраняются в Галерее. '
          'Там их удобно просматривать.',
      icon: Icons.photo_library_outlined,
    ),
  ];

  final _pageController = PageController();
  int _pageIndex = 0;
  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _pageIndex == _pages.length - 1;

  Future<void> _finish() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    try {
      await widget.onComplete();
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  void _goNext() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final panelHeight = (constraints.maxHeight * 0.58)
                .clamp(320.0, 520.0)
                .toDouble();

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isCompleting ? null : _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Пропустить',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: SizedBox(
                          height: panelHeight,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _pages.length,
                            onPageChanged: (index) {
                              setState(() => _pageIndex = index);
                            },
                            itemBuilder: (context, index) {
                              final page = _pages[index];
                              return _OnboardingPanel(
                                page: page,
                                theme: theme,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_pageIndex + 1} из ${_pages.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final active = index == _pageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? _accentColor
                              : _accentColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _isCompleting
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
                              ),
                        color: _isCompleting ? Colors.grey.shade300 : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isCompleting ? null : _goNext,
                          child: Center(
                            child: _isCompleting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLastPage ? 'Начать' : 'Далее',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({
    required this.page,
    required this.theme,
  });

  final _OnboardingPage page;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(page.icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 28),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              height: 1.5,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
