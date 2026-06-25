import 'package:flutter/material.dart';

import '../preview_asset_image.dart';
import 'onboarding_arrow.dart';

/// Flutter mockups for onboarding and section help slides.
class OnboardingMockups {
  OnboardingMockups._();

  static const _accent = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);
  static const _surface = Color(0xFFF7F8FC);

  static const _businessPortrait =
      'assets/previews/templates/business_portrait.jpg';
  static const _beautifulPortrait =
      'assets/previews/templates/beautiful_portrait.jpg';
  static const _goodPhoto = 'assets/guides/good_photo.jpg';
  static const _badPhoto = 'assets/guides/bad_photo.jpg';
  static const _studioPortrait1 =
      'assets/previews/photoshoots/studio_portrait_1.jpg';
  static const _studioPortrait2 =
      'assets/previews/photoshoots/studio_portrait_2.jpg';
  static const _studioPortrait3 =
      'assets/previews/photoshoots/studio_portrait_3.jpg';

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
    return _MockPhoneFrame(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mockHeader(compact: compact, title: 'Шаблоны фото'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _mockTemplateCard(
                  compact: compact,
                  highlightButton: true,
                  title: 'Деловой портрет',
                  previewAsset: _businessPortrait,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _mockTemplateCard(
                  compact: compact,
                  title: 'Красивый портрет',
                  previewAsset: _beautifulPortrait,
                ),
              ),
            ],
          ),
        ],
      ),
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
    return _MockPhoneFrame(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _mockTemplateCard(
                  compact: compact,
                  title: 'Деловой портрет',
                  previewAsset: _businessPortrait,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _mockTemplateCard(
                  compact: compact,
                  title: 'Красивый портрет',
                  previewAsset: _beautifulPortrait,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget templateOpen({required bool compact}) => templateCardTry(compact: compact);

  static Widget templateAddPhoto({required bool compact}) {
    return _MockPhoneFrame(
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
          const SizedBox(height: 8),
          _assetThumb(
            _businessPortrait,
            compact: compact,
            aspectRatio: 1,
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
          Row(
            children: [
              SizedBox(
                width: compact ? 52 : 60,
                child: _assetThumb(
                  _goodPhoto,
                  compact: compact,
                  aspectRatio: 1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _gradientButton(
                  'Выбрать фото',
                  compact: compact,
                  height: 40,
                ),
              ),
            ],
          ),
        ],
      ),
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
            child: _assetThumb(
              _beautifulPortrait,
              compact: compact,
              aspectRatio: 1,
              borderRadius: BorderRadius.circular(12),
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
          _photoshootThumbRow(compact: compact),
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
          _photoshootThumbRow(
            compact: compact,
            showPhotoLabels: true,
          ),
        ],
      ),
    );
  }

  // —— Building blocks ———————————————————————————————————————————————————————

  static Widget _assetThumb(
    String assetPath, {
    required bool compact,
    double aspectRatio = 4 / 3,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(10)),
    bool dimmed = false,
  }) {
    Widget image = PreviewAssetImage(
      assetPath: assetPath,
      fit: BoxFit.cover,
      placeholder: Container(
        color: const Color(0xFFE8EAEF),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          color: _textSecondary,
          size: compact ? 20 : 24,
        ),
      ),
    );
    if (dimmed) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.35),
          BlendMode.darken,
        ),
        child: image,
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(aspectRatio: aspectRatio, child: image),
    );
  }

  static Widget _photoshootThumbRow({
    required bool compact,
    bool showPhotoLabels = false,
  }) {
    const paths = [_studioPortrait1, _studioPortrait2, _studioPortrait3];
    return Row(
      children: [
        for (var i = 0; i < paths.length; i++) ...[
          if (i > 0) SizedBox(width: compact ? 4 : 6),
          Expanded(
            child: Column(
              children: [
                _assetThumb(
                  paths[i],
                  compact: compact,
                  aspectRatio: 3 / 4,
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                ),
                if (showPhotoLabels) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Фото ${i + 1}',
                    style: TextStyle(
                      fontSize: compact ? 9 : 10,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

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
    String title = 'Деловой портрет',
    String previewAsset = _businessPortrait,
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
            child: _assetThumb(
              previewAsset,
              compact: compact,
              aspectRatio: 1,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Container(
            height: compact ? 30 : 34,
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
          _photoshootThumbRow(compact: compact),
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
          _assetThumb(
            isGood ? _goodPhoto : _badPhoto,
            compact: compact,
            aspectRatio: 1,
            dimmed: !isGood,
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
