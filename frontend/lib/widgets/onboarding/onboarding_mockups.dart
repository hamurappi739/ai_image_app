import 'package:flutter/material.dart';

import '../visual_placeholder.dart';
import 'onboarding_arrow.dart';

/// Flutter mockups for onboarding and section help slides.
class OnboardingMockups {
  OnboardingMockups._();

  static const _accent = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);
  static const _surface = Color(0xFFF7F8FC);

  // —— First-run ———————————————————————————————————————————————————————————

  static Widget welcomeHome({required bool compact}) {
    return _MockPhoneFrame(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mockHeader(compact: compact, title: 'Главная'),
          const SizedBox(height: 10),
          _gradientButton('Начать создавать', compact: compact),
          SizedBox(height: compact ? 8 : 10),
          _outlineButton('Сделать фотосессию', compact: compact),
          SizedBox(height: compact ? 8 : 10),
          _outlineButton('Готовые фото', compact: compact),
        ],
      ),
    );
  }

  static Widget templateCardTry({required bool compact}) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _MockPhoneFrame(
          compact: compact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mockHeader(compact: compact, title: 'Шаблоны фото'),
              const SizedBox(height: 8),
              _mockTemplateCard(compact: compact, highlightButton: true),
            ],
          ),
        ),
        Positioned(
          right: compact ? 4 : 12,
          bottom: compact ? 8 : 16,
          child: OnboardingPointer(
            label: 'Попробовать',
            direction: OnboardingArrowDirection.downRight,
            compact: compact,
          ),
        ),
      ],
    );
  }

  static Widget photoshootTriplet({required bool compact}) {
    return _MockPhoneFrame(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mockHeader(compact: compact, title: 'Фотосессии'),
          const SizedBox(height: 8),
          _mockPhotoshootCard(compact: compact),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Стоимость: 3 изображения',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget goodBadPhoto({required bool compact}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _photoQualityTile(isGood: true, compact: compact)),
            SizedBox(width: compact ? 8 : 12),
            Expanded(child: _photoQualityTile(isGood: false, compact: compact)),
          ],
        ),
        Positioned(
          top: compact ? -4 : 0,
          left: compact ? 8 : 16,
          child: OnboardingPointer(
            label: 'Выберите чёткое фото',
            direction: OnboardingArrowDirection.downLeft,
            compact: compact,
          ),
        ),
      ],
    );
  }

  static Widget drawerMenu({required bool compact}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _MockPhoneFrame(
          compact: compact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _burgerIcon(compact: compact, highlighted: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Раздел',
                      style: TextStyle(
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Помощь',
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...['Главная', 'Фото по шаблону', 'Фотосессии', 'Готовые фото']
                  .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: compact ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8EAEF)),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: compact ? -2 : 4,
          top: compact ? 28 : 36,
          child: OnboardingPointer(
            label: 'Меню',
            direction: OnboardingArrowDirection.right,
            compact: compact,
          ),
        ),
      ],
    );
  }

  static Widget freeBalance({required bool compact}) {
    return _MockPhoneFrame(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mockHeader(compact: compact, title: 'Ваш баланс'),
          const SizedBox(height: 10),
          _balanceTile(
            label: 'Бесплатные генерации',
            value: '3',
            accent: true,
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 10),
          _balanceTile(
            label: 'Фотосессия',
            value: '= 3 изображения',
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 10),
          _balanceTile(
            label: 'Обычное фото',
            value: '= 1 изображение',
            compact: compact,
          ),
        ],
      ),
    );
  }

  // —— Template help ————————————————————————————————————————————————————————

  static Widget templateCategories({required bool compact}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _MockPhoneFrame(
          compact: compact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mockHeader(compact: compact, title: 'Шаблоны фото'),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Для себя', selected: true, compact: compact),
                    const SizedBox(width: 6),
                    _chip('Для работы', compact: compact),
                    const SizedBox(width: 6),
                    _chip('Для семьи', compact: compact),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _mockTemplateCard(compact: compact),
            ],
          ),
        ),
        Positioned(
          left: compact ? 12 : 24,
          top: compact ? 52 : 60,
          child: OnboardingPointer(
            label: 'Категория',
            direction: OnboardingArrowDirection.down,
            compact: compact,
          ),
        ),
      ],
    );
  }

  static Widget templateOpen({required bool compact}) => templateCardTry(compact: compact);

  static Widget templateAddPhoto({required bool compact}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _MockPhoneFrame(
          compact: compact,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Деловой портрет',
                style: TextStyle(
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Добавьте фото',
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _gradientButton('Выбрать фото', compact: compact, height: 40),
            ],
          ),
        ),
        Positioned(
          right: compact ? 8 : 16,
          bottom: compact ? 4 : 8,
          child: OnboardingPointer(
            label: 'Выбрать фото',
            direction: OnboardingArrowDirection.downRight,
            compact: compact,
          ),
        ),
      ],
    );
  }

  static Widget templateResult({required bool compact}) {
    return _MockPhoneFrame(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mockHeader(compact: compact, title: 'Готовые фото'),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: VisualPlaceholder(
              mood: VisualPlaceholderMood.business,
              gradientColors: const [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
              height: compact ? 100 : 120,
              compact: true,
              caption: 'Готовое фото',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Сохранится в готовых фото',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E9B66),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // —— Photoshoot help ——————————————————————————————————————————————————————

  static Widget photoshootStylePick({required bool compact}) {
    return _MockPhoneFrame(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mockHeader(compact: compact, title: 'Фотосессии'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Популярное', selected: true, compact: compact),
                const SizedBox(width: 6),
                _chip('Для себя', compact: compact),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _mockPhotoshootCard(compact: compact),
        ],
      ),
    );
  }

  static Widget photoshootThreeResults({required bool compact}) {
    return _MockPhoneFrame(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VisualPlaceholderSeries(
            mood: VisualPlaceholderMood.photoshoot,
            height: compact ? 72 : 88,
            gradientColors: const [Color(0xFFEDE9FF), Color(0xFFB8B0D4)],
            icon: Icons.photo_camera_outlined,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          Text(
            '3 готовых фото в одном стиле',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Стоимость: 3 изображения',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget photoshootAddPhoto({required bool compact}) =>
      templateAddPhoto(compact: compact);

  static Widget photoshootGallery({required bool compact}) {
    return _MockPhoneFrame(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mockHeader(compact: compact, title: 'Готовые фото'),
          const SizedBox(height: 8),
          Text(
            'Фотосессия · 3 фото',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          VisualPlaceholderSeries(
            mood: VisualPlaceholderMood.photoshoot,
            height: compact ? 72 : 88,
            gradientColors: const [Color(0xFFC0ECE0), Color(0xFF58B8A8)],
            icon: Icons.collections_outlined,
            borderRadius: BorderRadius.circular(12),
            showPhotoLabels: true,
          ),
        ],
      ),
    );
  }

  // —— Building blocks ———————————————————————————————————————————————————————

  static Widget _mockHeader({
    required bool compact,
    required String title,
  }) {
    return Row(
      children: [
        _burgerIcon(compact: compact),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _burgerIcon({
    required bool compact,
    bool highlighted = false,
  }) {
    return Container(
      width: compact ? 32 : 36,
      height: compact ? 32 : 36,
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFEDE9FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? _accent : const Color(0xFFE8EAEF),
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.menu,
        size: compact ? 18 : 20,
        color: highlighted ? _accent : _textPrimary,
      ),
    );
  }

  static Widget _gradientButton(
    String label, {
    required bool compact,
    double? height,
  }) {
    return Container(
      height: height ?? (compact ? 38 : 42),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget _outlineButton(String label, {required bool compact}) {
    return Container(
      height: compact ? 36 : 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _accent,
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget _chip(
    String label, {
    required bool compact,
    bool selected = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEDE9FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? _accent.withValues(alpha: 0.45) : const Color(0xFFE8EAEF),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? _accent : _textPrimary,
        ),
      ),
    );
  }

  static Widget _mockTemplateCard({
    required bool compact,
    bool highlightButton = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: VisualPlaceholder(
              mood: VisualPlaceholderMood.business,
              gradientColors: const [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
              height: compact ? 56 : 68,
              compact: true,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            'Деловой портрет',
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Container(
            height: compact ? 32 : 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: highlightButton ? _accent : _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: highlightButton
                  ? null
                  : Border.all(color: _accent.withValues(alpha: 0.3)),
              boxShadow: highlightButton
                  ? [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              'Попробовать',
              style: TextStyle(
                color: highlightButton ? Colors.white : _accent,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _mockPhotoshootCard({required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VisualPlaceholderSeries(
            mood: VisualPlaceholderMood.photoshoot,
            height: compact ? 52 : 64,
            gradientColors: const [Color(0xFFEDE9FF), Color(0xFFB8B0D4)],
            icon: Icons.photo_camera_outlined,
            borderRadius: BorderRadius.circular(10),
            showPhotoLabels: false,
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            'Студийный портрет',
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _photoQualityTile({
    required bool isGood,
    required bool compact,
  }) {
    final statusColor = isGood ? const Color(0xFF2E9B66) : const Color(0xFFC45C5C);
    final statusBg = isGood ? const Color(0xFFE8F7EF) : const Color(0xFFFCEEEE);

    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGood ? const Color(0xFFB8E6CF) : const Color(0xFFF0CACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isGood ? 'Хорошее фото' : 'Плохое фото',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          AspectRatio(
            aspectRatio: 1,
            child: VisualPlaceholder(
              mood: VisualPlaceholderMood.portrait,
              gradientColors: isGood
                  ? const [Color(0xFFD4E0EE), Color(0xFF8EA4BE)]
                  : const [Color(0xFF3A3F4B), Color(0xFF6B7280)],
              height: 80,
              compact: true,
              dimmed: !isGood,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _balanceTile({
    required String label,
    required String value,
    required bool compact,
    bool accent = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFEDE9FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent ? _accent.withValues(alpha: 0.3) : const Color(0xFFE8EAEF),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: accent ? _accent : _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockPhoneFrame extends StatelessWidget {
  const _MockPhoneFrame({
    required this.compact,
    required this.child,
  });

  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: OnboardingMockups._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAEF)),
      ),
      child: child,
    );
  }
}
