import 'package:flutter/material.dart';

import 'ui_preview_placeholders.dart';

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
    required this.previewBuilder,
  });

  final String title;
  final String body;
  final Widget Function({required bool compact}) previewBuilder;
}

class _CreateHelpDialogState extends State<CreateHelpDialog> {
  static const _accentColor = Color(0xFF5B6CFF);

  static final _blocks = [
    _HelpBlock(
      title: 'Начните с шаблона',
      body: 'Самый простой путь — выберите готовый вариант. '
          'Текст подставится сам.',
      previewBuilder: ({required compact}) =>
          HelpTemplatePreview(compact: compact),
    ),
    _HelpBlock(
      title: 'Напишите описание',
      body: 'Если нужна своя идея — коротко опишите, что хотите увидеть.',
      previewBuilder: ({required compact}) =>
          HelpDescriptionPreview(compact: compact),
    ),
    _HelpBlock(
      title: 'Добавьте фото',
      body: 'По желанию можно загрузить своё фото. '
          'Лицо должно быть хорошо видно.',
      previewBuilder: ({required compact}) =>
          HelpPhotoUploadPreview(compact: compact),
    ),
    _HelpBlock(
      title: 'Нажмите «Создать фото»',
      body: 'Кнопка внизу экрана. Обычно ждать 20–60 секунд.',
      previewBuilder: ({required compact}) =>
          HelpCreateButtonPreview(compact: compact),
    ),
    _HelpBlock(
      title: 'Смотрите результат',
      body: 'Готовое фото появится в разделе «Готовые фото».',
      previewBuilder: ({required compact}) =>
          HelpGalleryPreview(compact: compact),
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

  bool get _isFirstPage => _pageIndex == 0;
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

  void _goBack() {
    if (_isFirstPage || _isClosing) return;
    _pageController.previousPage(
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
    final titleFontSize = isCompact ? 17.0 : 18.0;
    final bodyFontSize = isCompact ? 13.0 : 14.0;
    final maxDialogHeight = screenSize.height - 48;
    final pageAreaHeight = (maxDialogHeight * 0.42).clamp(180.0, 280.0);

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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            block.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: isCompact ? 8 : 10),
                          Text(
                            block.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: bodyFontSize,
                              height: 1.35,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          SizedBox(height: isCompact ? 12 : 16),
                          block.previewBuilder(compact: isCompact),
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
              SizedBox(height: isCompact ? 12 : 16),
              Row(
                children: [
                  if (!_isFirstPage) ...[
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: _isClosing ? null : _goBack,
                        child: const Text(
                          'Назад',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _isClosing
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF7C5CFF),
                                    Color(0xFF4A7CFF),
                                  ],
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
