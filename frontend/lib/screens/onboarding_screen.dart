import 'package:flutter/material.dart';

import '../widgets/ui_preview_placeholders.dart';

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
    required this.previewBuilder,
  });

  final String title;
  final String body;
  final Widget Function({required bool compact}) previewBuilder;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _accentColor = Color(0xFF5B6CFF);

  static final _pages = [
    _OnboardingPage(
      title: 'Добро пожаловать',
      body:
          'Здесь можно создавать красивые фото, '
          'фотосессии и фото по своей идее.',
      previewBuilder: ({required compact}) =>
          HelpWelcomePreview(compact: compact),
    ),
    _OnboardingPage(
      title: 'Начните с шаблона',
      body:
          'Выберите готовый вариант — приложение '
          'само подготовит описание.',
      previewBuilder: ({required compact}) =>
          HelpTemplatePreview(compact: compact),
    ),
    _OnboardingPage(
      title: 'Попробуйте фотосессию',
      body: 'Фотосессия создаёт серию из 3 фото в одном стиле.',
      previewBuilder: ({required compact}) =>
          HelpPhotoshootTripletPreview(compact: compact),
    ),
    _OnboardingPage(
      title: 'Свой запрос',
      body:
          'Добавьте фото и напишите, '
          'какой результат хотите получить.',
      previewBuilder: ({required compact}) =>
          HelpCustomRequestFlowPreview(compact: compact),
    ),
    _OnboardingPage(
      title: 'Меню всегда слева сверху',
      body:
          'Нажмите значок меню, чтобы открыть все разделы: '
          'готовые фото, раздел «Купить», профиль и помощь.',
      previewBuilder: ({required compact}) =>
          HelpDrawerMenuPreview(compact: compact),
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

  bool get _isFirstPage => _pageIndex == 0;
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

  void _goBack() {
    if (_isFirstPage || _isCompleting) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.height < 720 || screenSize.width < 400;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, isCompact ? 16 : 24),
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
                          isCompact: isCompact,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_pageIndex + 1} из ${_pages.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D26),
                ),
              ),
              const SizedBox(height: 10),
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
              SizedBox(height: isCompact ? 16 : 20),
              Row(
                children: [
                  if (!_isFirstPage) ...[
                    SizedBox(
                      height: 54,
                      child: TextButton(
                        onPressed: _isCompleting ? null : _goBack,
                        child: const Text(
                          'Назад',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _isCompleting
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF7C5CFF),
                                    Color(0xFF4A7CFF),
                                  ],
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({
    required this.page,
    required this.theme,
    required this.isCompact,
  });

  final _OnboardingPage page;
  final ThemeData theme;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          isCompact ? 20 : 28,
          isCompact ? 24 : 32,
          isCompact ? 20 : 28,
          isCompact ? 24 : 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: isCompact ? 22 : 24,
              ),
            ),
            SizedBox(height: isCompact ? 12 : 16),
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isCompact ? 15 : 16,
                height: 1.45,
                color: const Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: isCompact ? 16 : 20),
            page.previewBuilder(compact: isCompact),
          ],
        ),
      ),
    );
  }
}
