import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/create_description_text_field.dart';

/// Step-based UI for «Свой запрос» — photo first, then description, then create.
class CustomRequestFlow extends StatelessWidget {
  const CustomRequestFlow({
    super.key,
    required this.descriptionController,
    required this.photoBytes,
    required this.isPickingPhoto,
    required this.isBusy,
    required this.onPickPhoto,
    required this.onClearPhoto,
    required this.onCreate,
    required this.isCreating,
    required this.onIdeaSelected,
  });

  final TextEditingController descriptionController;
  final Uint8List? photoBytes;
  final bool isPickingPhoto;
  final bool isBusy;
  final VoidCallback onPickPhoto;
  final VoidCallback onClearPhoto;
  final VoidCallback? onCreate;
  final bool isCreating;
  final ValueChanged<String> onIdeaSelected;

  static const _accentColor = Color(0xFF5B6CFF);
  static const _textPrimary = Color(0xFF1A1D26);
  static const _textSecondary = Color(0xFF6B7280);

  static const _photoIdeas = [
    (
      label: 'Деловой портрет',
      text: 'Сделай деловой портрет на светлом фоне, мягкий свет',
    ),
    (
      label: 'Фото для соцсетей',
      text: 'Сделай фото для соцсетей, светлый фон, естественная улыбка',
    ),
    (
      label: 'Светлый портрет',
      text: 'Сделай светлый портрет с мягким освещением и чистым фоном',
    ),
    (
      label: 'Образ для резюме',
      text: 'Сделай образ для резюме: спокойный фон, уверенный вид',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = photoBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepSection(
          stepNumber: 1,
          title: 'Добавьте фото',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!hasPhoto)
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: isPickingPhoto || isBusy ? null : onPickPhoto,
                    icon: isPickingPhoto
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      isPickingPhoto ? 'Подождите…' : 'Выбрать фото',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 132,
                    width: double.infinity,
                    child: Image.memory(
                      photoBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 0,
                  children: [
                    TextButton.icon(
                      onPressed: isBusy || isPickingPhoto ? null : onPickPhoto,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Изменить фото'),
                      style: TextButton.styleFrom(
                        foregroundColor: _accentColor,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: isBusy ? null : onClearPhoto,
                      icon: const Icon(Icons.close, size: 17),
                      label: const Text('Убрать фото'),
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
                      'Например: сделай деловой портрет на светлом фоне',
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
        Text(
          'Примеры идей',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Нажмите — идея подставится в поле выше.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: _textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final idea in _photoIdeas)
              ActionChip(
                label: Text(idea.label),
                onPressed: isBusy ? null : () => onIdeaSelected(idea.text),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE8EAEF)),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
          ],
        ),
      ],
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
