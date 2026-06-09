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
                  height: 48,
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
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.memory(
                      photoBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: isBusy ? null : onClearPhoto,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Убрать фото'),
                    style: TextButton.styleFrom(
                      foregroundColor: _textSecondary,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _StepSection(
          stepNumber: 2,
          title: 'Опишите результат',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAEF)),
            ),
            child: CreateDescriptionTextField(
              controller: descriptionController,
              hintText:
                  'Например: сделай деловой портрет на светлом фоне',
            ),
          ),
        ),
        const SizedBox(height: 20),
        _StepSection(
          stepNumber: 3,
          title: 'Создайте фото',
          child: SizedBox(
            width: double.infinity,
            height: 54,
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
                            'Создать фото',
                            style: TextStyle(
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
        const SizedBox(height: 8),
        Text(
          'Обычно создание занимает 20–60 секунд.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            height: 1.35,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Примеры описания',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Нажмите — текст подставится в поле выше.',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
