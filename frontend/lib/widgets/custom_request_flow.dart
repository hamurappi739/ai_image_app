import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/create_description_text_field.dart';

/// Step-based UI for «Свой запрос» — photos first, then description, then create.
class CustomRequestFlow extends StatelessWidget {
  const CustomRequestFlow({
    super.key,
    required this.descriptionController,
    required this.primaryPhotoBytes,
    required this.optionalPhoto2Bytes,
    required this.optionalPhoto3Bytes,
    required this.pickingPhotoSlot,
    required this.isBusy,
    required this.onPickPhoto,
    required this.onClearPhoto,
    required this.onCreate,
    required this.isCreating,
    required this.onIdeaSelected,
  });

  final TextEditingController descriptionController;
  final Uint8List? primaryPhotoBytes;
  final Uint8List? optionalPhoto2Bytes;
  final Uint8List? optionalPhoto3Bytes;
  final String? pickingPhotoSlot;
  final bool isBusy;
  final ValueChanged<String> onPickPhoto;
  final ValueChanged<String> onClearPhoto;
  final VoidCallback? onCreate;
  final bool isCreating;
  final ValueChanged<String> onIdeaSelected;

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  static const _photoIdeas = [
    (
      label: 'Постер фильма',
      text:
          'Сделай из моего фото кинематографичный постер фильма: '
          'драматичный свет, выразительный фон, стильная композиция, '
          'как обложка современного кино.',
      suggestExtraPhotos: false,
    ),
    (
      label: 'Обложка журнала',
      text:
          'Сделай фото как обложку глянцевого журнала: красивый свет, '
          'уверенная поза, аккуратный фон, модная editorial-обработка.',
      suggestExtraPhotos: false,
    ),
    (
      label: 'Сказочный образ',
      text:
          'Создай сказочный образ по моему фото: мягкий волшебный свет, '
          'красивый фон, нежная атмосфера, реалистично и без мультяшности.',
      suggestExtraPhotos: false,
    ),
    (
      label: 'Фото с 3 людьми',
      text:
          'Создай общее фото с тремя людьми по загруженным фотографиям: '
          'все выглядят естественно, стоят рядом, одинаковый свет '
          'и единый фон.',
      suggestExtraPhotos: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepSection(
          stepNumber: 1,
          title: 'Добавьте фото',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Добавьте одно фото. Если на результате должно быть несколько '
                'людей или важный объект, можно добавить ещё 1–2 фото. '
                'Это необязательно.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: _textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              _PhotoSlot(
                title: 'Главное фото',
                subtitle: 'Добавьте ваше фото',
                optionalHint: null,
                photoBytes: primaryPhotoBytes,
                isPicking: pickingPhotoSlot == 'primary',
                isBusy: isBusy,
                onPick: () => onPickPhoto('primary'),
                onClear: () => onClearPhoto('primary'),
              ),
              const SizedBox(height: 12),
              _PhotoSlot(
                title: 'Фото 2',
                subtitle: 'По желанию',
                optionalHint: 'Можно не добавлять',
                photoBytes: optionalPhoto2Bytes,
                isPicking: pickingPhotoSlot == 'photo2',
                isBusy: isBusy,
                onPick: () => onPickPhoto('photo2'),
                onClear: () => onClearPhoto('photo2'),
              ),
              const SizedBox(height: 12),
              _PhotoSlot(
                title: 'Фото 3',
                subtitle: 'По желанию',
                optionalHint: 'Можно не добавлять',
                photoBytes: optionalPhoto3Bytes,
                isPicking: pickingPhotoSlot == 'photo3',
                isBusy: isBusy,
                onPick: () => onPickPhoto('photo3'),
                onClear: () => onClearPhoto('photo3'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _StepSection(
          stepNumber: 2,
          title: 'Опишите свою идею',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Опишите, что хотите получить.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: _textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: CreateDescriptionTextField(
                  controller: descriptionController,
                  hintText:
                      'Например: сделай кинематографичный постер из моего фото',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _WhatYouGetBlock(),
        const SizedBox(height: 14),
        _StepSection(
          stepNumber: 3,
          title: 'Создайте фото',
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: onCreate == null
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
                      ),
                color: onCreate == null ? Colors.grey.shade300 : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: onCreate == null
                    ? null
                    : [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCreate,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: isCreating
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Создать по моей идее',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
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
        const SizedBox(height: 20),
        _PhotoIdeaExamples(
          ideas: _photoIdeas,
          isBusy: isBusy,
          onIdeaSelected: onIdeaSelected,
        ),
      ],
    );
  }
}

class _PhotoIdeaExamples extends StatefulWidget {
  const _PhotoIdeaExamples({
    required this.ideas,
    required this.isBusy,
    required this.onIdeaSelected,
  });

  final List<({String label, String text, bool suggestExtraPhotos})> ideas;
  final bool isBusy;
  final ValueChanged<String> onIdeaSelected;

  @override
  State<_PhotoIdeaExamples> createState() => _PhotoIdeaExamplesState();
}

class _PhotoIdeaExamplesState extends State<_PhotoIdeaExamples> {
  bool _showMultiPhotoHint = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Примеры идей',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            color: CustomRequestFlow._textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Нажмите — идея подставится в поле выше.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: CustomRequestFlow._textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final idea in widget.ideas)
              ActionChip(
                label: Text(idea.label),
                onPressed: widget.isBusy
                    ? null
                    : () {
                        widget.onIdeaSelected(idea.text);
                        setState(
                          () => _showMultiPhotoHint = idea.suggestExtraPhotos,
                        );
                      },
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE8EAEF)),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CustomRequestFlow._textPrimary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
          ],
        ),
        if (_showMultiPhotoHint) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF1FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF5B6CFF).withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              'Для этой идеи добавьте фото 2 и фото 3 — по одному снимку '
              'на каждого человека.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                height: 1.4,
                color: CustomRequestFlow._textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.title,
    required this.subtitle,
    required this.optionalHint,
    required this.photoBytes,
    required this.isPicking,
    required this.isBusy,
    required this.onPick,
    required this.onClear,
  });

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  final String title;
  final String subtitle;
  final String? optionalHint;
  final Uint8List? photoBytes;
  final bool isPicking;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = photoBytes != null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: _textSecondary,
                        height: 1.3,
                      ),
                    ),
                    if (optionalHint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        optionalHint!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: _textSecondary.withValues(alpha: 0.85),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasPhoto)
            SizedBox(
              height: 40,
              child: FilledButton.icon(
                onPressed: isBusy || isPicking ? null : onPick,
                icon: isPicking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(isPicking ? 'Подождите…' : 'Выбрать фото'),
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.memory(
                  photoBytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: isBusy || isPicking ? null : onPick,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Изменить'),
                  style: TextButton.styleFrom(
                    foregroundColor: _accentColor,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton.icon(
                  onPressed: isBusy ? null : onClear,
                  icon: const Icon(Icons.close, size: 17),
                  label: const Text('Убрать'),
                  style: TextButton.styleFrom(
                    foregroundColor: _textSecondary,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WhatYouGetBlock extends StatelessWidget {
  const _WhatYouGetBlock();

  static const _textPrimary = Color(0xFF1A1D26);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Что получится',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          const _WhatYouGetLine(
            icon: Icons.photo_outlined,
            text: '1 готовое фото',
          ),
          const SizedBox(height: 4),
          const _WhatYouGetLine(
            icon: Icons.collections_outlined,
            text: 'Сохранится в готовых фото',
          ),
          const SizedBox(height: 4),
          const _WhatYouGetLine(
            icon: Icons.schedule_outlined,
            text: 'Обычно 20–60 секунд',
          ),
        ],
      ),
    );
  }
}

class _WhatYouGetLine extends StatelessWidget {
  const _WhatYouGetLine({
    required this.icon,
    required this.text,
  });

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textSecondary = Color(0xFF6B7280);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _accentColor.withValues(alpha: 0.85)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: _textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepSection extends StatelessWidget {
  const _StepSection({
    required this.stepNumber,
    required this.title,
    required this.child,
  });

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);

  final int stepNumber;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
