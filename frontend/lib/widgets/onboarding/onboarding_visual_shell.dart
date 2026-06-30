import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'onboarding_mockup_palette.dart';
import 'onboarding_step.dart';

enum OnboardingPresentation {
  fullscreen,
  dialog,
}

/// Shared visual shell: title, large mock card, dots, Back/Next.
class OnboardingVisualShell extends StatefulWidget {
  const OnboardingVisualShell({
    super.key,
    required this.steps,
    this.presentation = OnboardingPresentation.fullscreen,
    this.onComplete,
    this.lastActionLabel = 'Начать',
    this.showSkip = false,
    this.dialogTitle = 'Помощь',
  });

  final List<OnboardingStep> steps;
  final OnboardingPresentation presentation;
  final Future<void> Function()? onComplete;
  final String lastActionLabel;
  final bool showSkip;
  final String dialogTitle;

  @override
  State<OnboardingVisualShell> createState() => _OnboardingVisualShellState();
}

class _OnboardingVisualShellState extends State<OnboardingVisualShell> {
  final _pageController = PageController();
  int _pageIndex = 0;
  bool _isBusy = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isFirstPage => _pageIndex == 0;
  bool get _isLastPage => _pageIndex == widget.steps.length - 1;
  bool get _isFullscreen =>
      widget.presentation == OnboardingPresentation.fullscreen;

  Future<void> _finish() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await widget.onComplete?.call();
      if (mounted && !_isFullscreen) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
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
    if (_isFirstPage || _isBusy) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.height < 720 || screenSize.width < 400;
    final content = _buildContent(context, isCompact, colors);

    if (_isFullscreen) return content;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: isCompact ? 12 : 20,
      ),
      backgroundColor: colors.subtleFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: screenSize.height * 0.92,
        ),
        child: content,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isCompact,
    AppThemeColors colors,
  ) {
    final theme = Theme.of(context);
    final textPrimary = context.appTextPrimary;
    final accent = context.appAccent;
    final horizontalPadding = isCompact ? 16.0 : 20.0;
    final verticalPadding = _isFullscreen
        ? (isCompact ? 16.0 : 24.0)
        : (isCompact ? 14.0 : 18.0);

    return ColoredBox(
      color: colors.subtleFill,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            _isFullscreen ? 8 : 14,
            horizontalPadding,
            verticalPadding,
          ),
          child: Column(
            children: [
              if (!_isFullscreen)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.dialogTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isBusy ? null : _finish,
                      icon: const Icon(Icons.close, size: 22),
                      tooltip: 'Закрыть',
                      color: colors.textSecondary,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
              if (widget.showSkip && _isFullscreen)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isBusy ? null : _finish,
                    child: Text(
                      'Пропустить',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.steps.length,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemBuilder: (context, index) {
                    final step = widget.steps[index];
                    return _OnboardingSlide(
                      step: step,
                      isCompact: isCompact,
                      isFullscreen: _isFullscreen,
                    );
                  },
                ),
              ),
              if (widget.steps.length > 1) ...[
                const SizedBox(height: 10),
                _ProgressDots(
                  count: widget.steps.length,
                  index: _pageIndex,
                  accent: accent,
                ),
              ],
              SizedBox(height: isCompact ? 12 : 16),
              _NavigationRow(
                isFirstPage: _isFirstPage,
                isLastPage: _isLastPage,
                isBusy: _isBusy,
                lastLabel: widget.lastActionLabel,
                onBack: _goBack,
                onNext: _goNext,
                buttonHeight: isCompact ? 50.0 : 54.0,
                accent: accent,
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.step,
    required this.isCompact,
    required this.isFullscreen,
  });

  final OnboardingStep step;
  final bool isCompact;
  final bool isFullscreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final textPrimary = context.appTextPrimary;
    final palette = OnboardingMockupPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: isCompact ? 22 : 26,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            height: 1.15,
          ),
        ),
        SizedBox(height: isCompact ? 8 : 10),
        Text(
          step.body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: isCompact ? 14 : 16,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
        SizedBox(height: isCompact ? 12 : 16),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.elevatedSurface,
                    borderRadius:
                        BorderRadius.circular(isFullscreen ? 24 : 20),
                    border: Border.all(color: colors.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: theme.brightness == Brightness.dark ? 0.35 : 0.07,
                        ),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: OnboardingMockupPaletteScope(
                    palette: palette,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.all(isCompact ? 14 : 20),
                      child: step.mockupBuilder(compact: isCompact),
                    ),
                  ),
                ),
              ),
              if (step.footerNote != null) ...[
                SizedBox(height: isCompact ? 8 : 10),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 12,
                    vertical: isCompact ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.infoBannerFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Text(
                    step.footerNote!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: isCompact ? 11 : 12,
                      height: 1.35,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.count,
    required this.index,
    required this.accent,
  });

  final int count;
  final int index;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? accent : accent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.isFirstPage,
    required this.isLastPage,
    required this.isBusy,
    required this.lastLabel,
    required this.onBack,
    required this.onNext,
    required this.buttonHeight,
    required this.accent,
    required this.colors,
  });

  final bool isFirstPage;
  final bool isLastPage;
  final bool isBusy;
  final String lastLabel;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final double buttonHeight;
  final Color accent;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.appTextPrimary;

    return Row(
      children: [
        if (!isFirstPage) ...[
          SizedBox(
            height: buttonHeight,
            child: TextButton(
              onPressed: isBusy ? null : onBack,
              child: Text(
                'Назад',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isBusy
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
                      ),
                color: isBusy ? colors.mutedBadgeFill : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isBusy
                    ? null
                    : [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: isBusy ? null : onNext,
                  child: Center(
                    child: isBusy
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: colors.textSecondary,
                            ),
                          )
                        : Text(
                            isLastPage ? lastLabel : 'Далее',
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
    );
  }
}
