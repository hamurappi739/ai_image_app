import 'package:flutter/material.dart';

class CreateHelpDialog extends StatefulWidget {
  const CreateHelpDialog({
    super.key,
    this.onDismissed,
  });

  final Future<void> Function()? onDismissed;

  @override
  State<CreateHelpDialog> createState() => _CreateHelpDialogState();
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

class _CreateHelpDialogState extends State<CreateHelpDialog> {
  static const _accentColor = Color(0xFF5B6CFF);
  static const _blocks = [
    _HelpBlock(
      title: 'Бесплатный старт',
      body:
          'На старте доступны 3 бесплатные генерации, '
          'чтобы попробовать приложение.',
      icon: Icons.auto_awesome_outlined,
    ),
    _HelpBlock(
      title: 'Готовые идеи',
      body: 'Нажмите на готовую идею, чтобы быстро заполнить описание.',
      icon: Icons.lightbulb_outline,
    ),
    _HelpBlock(
      title: 'Описание',
      body:
          'Напишите, что хотите увидеть на изображении. '
          'Чем понятнее описание, тем лучше результат.',
      icon: Icons.edit_outlined,
    ),
    _HelpBlock(
      title: 'Фото для образа',
      body:
          'Здесь можно выбрать фото для будущего одиночного образа. '
          'Сейчас создание по фото будет добавлено позже.',
      icon: Icons.add_photo_alternate_outlined,
    ),
    _HelpBlock(
      title: 'Где результат',
      body:
          'После создания изображение появится в Галерее. '
          'Создание может занять до минуты — это нормально.',
      icon: Icons.photo_library_outlined,
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
