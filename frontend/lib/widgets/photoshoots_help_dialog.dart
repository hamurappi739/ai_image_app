import 'package:flutter/material.dart';

class PhotoshootsHelpDialog extends StatefulWidget {
  const PhotoshootsHelpDialog({
    super.key,
    this.onDismissed,
  });

  final Future<void> Function()? onDismissed;

  @override
  State<PhotoshootsHelpDialog> createState() => _PhotoshootsHelpDialogState();
}

class _HelpBlock {
  const _HelpBlock({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

class _PhotoshootsHelpDialogState extends State<PhotoshootsHelpDialog> {
  static const _accentColor = Color(0xFF5B6CFF);
  static const _blocks = [
    _HelpBlock(
      title: 'Выберите стиль',
      body:
          'Каждая карточка — это готовый образ для фотосессии. '
          'Нажмите на стиль, который вам нравится.',
      icon: Icons.style_outlined,
    ),
    _HelpBlock(
      title: 'Загрузите хорошее фото',
      body:
          'Лучше всего подходят чёткие фото, где хорошо видно лицо. '
          'Размытые или тёмные фото могут ухудшить результат.',
      icon: Icons.face_retouching_natural_outlined,
    ),
    _HelpBlock(
      title: 'Что получится',
      body:
          'Фотосессия создаёт несколько готовых изображений '
          'в выбранном стиле. Фотосессия может занять 20–60 секунд.',
      icon: Icons.collections_outlined,
    ),
    _HelpBlock(
      title: 'Где смотреть результат',
      body: 'Готовая фотосессия появится в Галерее одной карточкой.',
      icon: Icons.photo_library_outlined,
    ),
    _HelpBlock(
      title: 'Своя фотосессия',
      body:
          'Позже здесь появится своя фотосессия: можно будет загрузить фото '
          'и описать желаемый образ своими словами.',
      icon: Icons.auto_awesome_outlined,
    ),
  ];

  final _pageController = PageController();
  int _pageIndex = 0;
  bool _isClosing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _pageIndex == _blocks.length - 1;

  Future<void> _close() async {
    if (_isClosing) return;
    setState(() => _isClosing = true);
    try {
      await widget.onDismissed?.call();
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _goNext() {
    if (_isLastPage) {
      _close();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Помощь',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isClosing ? null : _close,
                    icon: const Icon(Icons.close, size: 22),
                    tooltip: 'Закрыть',
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _blocks.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) {
                    final block = _blocks[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            block.icon,
                            color: _accentColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          block.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          block.body,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_pageIndex + 1} из ${_blocks.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D26),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_blocks.length, (index) {
                  final active = index == _pageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? _accentColor
                          : _accentColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _isClosing
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
                          ),
                    color: _isClosing ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _isClosing ? null : _goNext,
                      child: Center(
                        child: Text(
                          _isLastPage ? 'Понятно' : 'Далее',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
        ),
      ),
    );
  }
}
