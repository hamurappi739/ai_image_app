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
      body:
          'Идеи разделены по категориям: «Без фото» и «С фото» '
          '(для будущего режима с фото). Нажмите идею — '
          'описание заполнится автоматически.',
      icon: Icons.lightbulb_outline,
    ),
    _HelpBlock(
      title: 'Описание',
      body:
          'В блоке подсказок переключайте «Без фото» и «С фото» — '
          'там разные примеры. Укажите объект, место, стиль и настроение.',
      icon: Icons.edit_outlined,
    ),
    _HelpBlock(
      title: 'Фото для образа',
      body:
          'Фото можно выбрать заранее — это подготовка к будущему сценарию. '
          'Создание по фото подключим позже; сейчас изображение создаётся '
          'по описанию.',
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
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.height < 720 || screenSize.width < 400;
    final dialogPadding = isCompact
        ? const EdgeInsets.fromLTRB(20, 14, 20, 18)
        : const EdgeInsets.fromLTRB(24, 20, 24, 24);
    final iconBoxSize = isCompact ? 48.0 : 56.0;
    final iconSize = isCompact ? 24.0 : 28.0;
    final titleFontSize = isCompact ? 17.0 : 18.0;
    final bodyFontSize = isCompact ? 14.0 : 15.0;
    final iconTitleGap = isCompact ? 14.0 : 20.0;
    final titleBodyGap = isCompact ? 8.0 : 10.0;
    final maxDialogHeight = screenSize.height - 48;
    final pageAreaHeight = (maxDialogHeight * 0.38).clamp(168.0, 240.0);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: isCompact ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: maxDialogHeight,
        ),
        child: Padding(
          padding: dialogPadding,
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
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: pageAreaHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _blocks.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) {
                    final block = _blocks[index];
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: iconBoxSize,
                            height: iconBoxSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              block.icon,
                              color: _accentColor,
                              size: iconSize,
                            ),
                          ),
                          SizedBox(height: iconTitleGap),
                          Text(
                            block.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: titleFontSize,
                            ),
                          ),
                          SizedBox(height: titleBodyGap),
                          Text(
                            block.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: bodyFontSize,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: isCompact ? 6 : 8),
              Text(
                '${_pageIndex + 1} из ${_blocks.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D26),
                ),
              ),
              SizedBox(height: isCompact ? 8 : 10),
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
              SizedBox(height: isCompact ? 14 : 20),
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
