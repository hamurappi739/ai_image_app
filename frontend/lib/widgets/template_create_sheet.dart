import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/catalog_entries.dart';
import '../models/generated_image_item.dart';
import '../models/user_balance.dart';
import '../screens/template_photo_screen.dart';
import '../services/api_service.dart';
import '../widgets/generation_progress_dialog.dart';
import '../widgets/good_result_guide_card.dart';
import '../widgets/insufficient_balance_dialog.dart';
import '../widgets/missing_photo_dialog.dart';
import '../widgets/preview_asset_image.dart';
import '../widgets/visual_placeholder.dart';

class _SelectedPhoto {
  const _SelectedPhoto({required this.file, required this.bytes});

  final XFile file;
  final Uint8List bytes;
}

class TemplateCreateSheet extends StatefulWidget {
  const TemplateCreateSheet({
    super.key,
    required this.template,
    required this.apiService,
    required this.balance,
    required this.balanceLoading,
    required this.onImageGenerated,
    required this.onBalanceUpdated,
    required this.onRefreshBalance,
    required this.onOpenGallery,
    required this.onOpenPacks,
    required this.onShowMessage,
  });

  final PhotoTemplate template;
  final ApiService apiService;
  final UserBalance? balance;
  final bool balanceLoading;
  final ValueChanged<GeneratedImageItem> onImageGenerated;
  final ValueChanged<UserBalance> onBalanceUpdated;
  final VoidCallback onRefreshBalance;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenPacks;
  final ValueChanged<String> onShowMessage;

  static Future<void> show(
    BuildContext context, {
    required PhotoTemplate template,
    required ApiService apiService,
    required UserBalance? balance,
    required bool balanceLoading,
    required ValueChanged<GeneratedImageItem> onImageGenerated,
    required ValueChanged<UserBalance> onBalanceUpdated,
    required VoidCallback onRefreshBalance,
    required VoidCallback onOpenGallery,
    required VoidCallback onOpenPacks,
    required ValueChanged<String> onShowMessage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TemplateCreateSheet(
        template: template,
        apiService: apiService,
        balance: balance,
        balanceLoading: balanceLoading,
        onImageGenerated: onImageGenerated,
        onBalanceUpdated: onBalanceUpdated,
        onRefreshBalance: onRefreshBalance,
        onOpenGallery: onOpenGallery,
        onOpenPacks: onOpenPacks,
        onShowMessage: onShowMessage,
      ),
    );
  }

  @override
  State<TemplateCreateSheet> createState() => _TemplateCreateSheetState();
}

class _TemplateCreateSheetState extends State<TemplateCreateSheet> {
  static const _accentColor = Color(0xFF5B6CFF);

  final _imagePicker = ImagePicker();
  final _cakeDigitController = TextEditingController();
  final Map<String, _SelectedPhoto> _photosByField = {};
  String? _pickingField;
  bool _isCreating = false;

  bool get _isMultiInput => widget.template.isMultiInputTemplate;

  bool get _hasPhoto => _photosByField.containsKey('photo');

  bool get _imagesBalanceDepleted {
    final balance = widget.balance;
    return balance != null &&
        !widget.balanceLoading &&
        !balance.isImageGenerationAvailable;
  }

  bool get _generationBlocked => widget.template.generationBlocked;

  String get _generationBlockedMessage =>
      widget.template.generationBlockedMessage ??
      'Скоро здесь можно будет добавить фото питомца.';

  CatalogTemplateInputRequirements? get _inputRequirements =>
      widget.template.inputRequirements;

  @override
  void dispose() {
    _cakeDigitController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotoForField(String field) async {
    if (_pickingField != null || _isCreating) return;
    setState(() => _pickingField = field);
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photosByField[field] = _SelectedPhoto(file: file, bytes: bytes);
      });
    } catch (_) {
      if (!mounted) return;
      widget.onShowMessage('Не удалось выбрать фото. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _pickingField = null);
    }
  }

  Future<void> _pickPhoto() => _pickPhotoForField('photo');

  void _clearPhotoForField(String field) {
    setState(() => _photosByField.remove(field));
  }

  void _clearPhoto() => _clearPhotoForField('photo');

  String _missingPhotoMessage(String field) {
    return switch (field) {
      'pet_photo' => 'Добавьте фото питомца',
      'child_photo' => 'Добавьте фото ребёнка',
      _ => 'Добавьте ваше фото',
    };
  }

  String? _validateCakeDigit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Введите цифру на торте';
    }
    if (!RegExp(r'^[1-9]\d?$').hasMatch(trimmed)) {
      return 'Введите только цифры';
    }
    return null;
  }

  Future<void> _showInsufficientImagesDialog() {
    return InsufficientBalanceDialog.showInsufficientImages(
      context,
      onOpenPacks: widget.onOpenPacks,
    );
  }

  Future<void> _onCreatePressed() async {
    if (_isCreating || _generationBlocked) return;

    if (_isMultiInput) {
      final requirements = _inputRequirements;
      if (requirements == null) return;
      for (final photoReq in requirements.photos) {
        if (!_photosByField.containsKey(photoReq.field)) {
          widget.onShowMessage(_missingPhotoMessage(photoReq.field));
          return;
        }
      }
      if (requirements.fieldByType('cake_digit') != null) {
        final validationError = _validateCakeDigit(_cakeDigitController.text);
        if (validationError != null) {
          widget.onShowMessage(validationError);
          return;
        }
      }
    } else if (!_hasPhoto) {
      await MissingPhotoDialog.showForTemplateOrCustom(context);
      return;
    }

    if (_imagesBalanceDepleted) {
      await _showInsufficientImagesDialog();
      return;
    }

    final userPhoto = _photosByField['photo'];
    if (userPhoto == null) return;

    setState(() => _isCreating = true);

    final prompt = widget.template.requestDescription;
    final cakeField = _inputRequirements?.fieldByType('cake_digit');

    try {
      final response =
          await GenerationProgressDialog.run<GenerateImageResponse>(
        context: context,
        title: 'Создаём фото…',
        subtitle: 'Обычно это занимает до минуту.',
        totalSeconds: 60,
        task: () => widget.apiService.generateImageWithPhoto(
          description: prompt,
          photoFile: userPhoto.file,
          templateId: _isMultiInput ? widget.template.id : null,
          petPhotoFile: _photosByField['pet_photo']?.file,
          childPhotoFile: _photosByField['child_photo']?.file,
          cakeDigit: cakeField != null
              ? _cakeDigitController.text.trim()
              : null,
        ),
      );

      if (!mounted) return;

      final updatedBalance = response.balance;
      if (updatedBalance != null) {
        widget.onBalanceUpdated(updatedBalance);
      } else {
        widget.onRefreshBalance();
      }

      widget.onImageGenerated(
        GeneratedImageItem(
          description: prompt,
          imageUrl: response.imageUrl,
          createdAt: DateTime.now(),
        ),
      );

      Navigator.of(context).pop();
      widget.onOpenGallery();
      widget.onShowMessage('Фото готово и сохранено в готовых фото.');
    } on InsufficientImagesException {
      if (!mounted) return;
      await _showInsufficientImagesDialog();
    } on PhotoGenerationInvalidPhotoException {
      if (!mounted) return;
      widget.onShowMessage('Выберите фото JPEG, PNG или WebP до 10 МБ');
    } catch (_) {
      if (!mounted) return;
      widget.onShowMessage('Не удалось создать фото. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Widget _buildSinglePhotoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Добавьте фото',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (!_hasPhoto)
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: _pickingField != null || _isCreating ? null : _pickPhoto,
              icon: _pickingField == 'photo'
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
                _pickingField == 'photo' ? 'Подождите…' : 'Выбрать фото',
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
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.memory(
                _photosByField['photo']!.bytes,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: _isCreating || _pickingField != null
                    ? null
                    : _pickPhoto,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Изменить фото'),
                style: TextButton.styleFrom(
                  foregroundColor: _accentColor,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              TextButton.icon(
                onPressed: _isCreating ? null : _clearPhoto,
                icon: const Icon(Icons.close, size: 17),
                label: const Text('Убрать фото'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMultiPhotoSlot(CatalogTemplatePhotoInput photoInput) {
    final field = photoInput.field;
    final selected = _photosByField[field];
    final isPicking = _pickingField == field;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selected == null)
            SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: _pickingField != null || _isCreating
                    ? null
                    : () => _pickPhotoForField(field),
                icon: isPicking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(isPicking ? 'Подождите…' : photoInput.label),
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
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.memory(selected.bytes, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _isCreating || _pickingField != null
                      ? null
                      : () => _pickPhotoForField(field),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Изменить фото'),
                  style: TextButton.styleFrom(
                    foregroundColor: _accentColor,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton.icon(
                  onPressed: _isCreating
                      ? null
                      : () => _clearPhotoForField(field),
                  icon: const Icon(Icons.close, size: 17),
                  label: const Text('Убрать фото'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
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

  Widget _buildMultiInputSection(ThemeData theme) {
    final requirements = _inputRequirements;
    if (requirements == null) {
      return const SizedBox.shrink();
    }

    final cakeField = requirements.fieldByType('cake_digit');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Добавьте фото',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final photoInput in requirements.photos)
          _buildMultiPhotoSlot(photoInput),
        if (cakeField != null) ...[
          const SizedBox(height: 4),
          Text(
            cakeField.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cakeDigitController,
            enabled: !_isCreating,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(
              hintText: 'Например, 3',
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8EAEF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8EAEF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _accentColor.withValues(alpha: 0.65),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final template = widget.template;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            maxWidth: 520,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  16 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            template.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _isCreating
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Закрыть',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final height =
                            (constraints.maxWidth * 9 / 16).clamp(0.0, 150.0);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            height: height,
                            width: double.infinity,
                            child: PreviewAssetImage(
                              assetPath: template.effectivePreviewAssetPath,
                              networkUrl: template.effectivePreviewNetworkUrl,
                              fit: BoxFit.cover,
                              placeholder: VisualPlaceholder(
                                mood: template.visualKind.placeholderMood,
                                gradientColors: template.placeholderColors,
                                caption: VisualPlaceholderPalette.theme(
                                  template.visualKind.placeholderMood,
                                ).caption,
                                variant: template.id.hashCode.abs() % 4,
                                height: height,
                                compact: true,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_generationBlocked) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF1FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _accentColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          _generationBlockedMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            height: 1.45,
                            color: const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ] else if (_isMultiInput)
                      _buildMultiInputSection(theme)
                    else
                      _buildSinglePhotoSection(theme),
                    if (!_generationBlocked) ...[
                      const SizedBox(height: 16),
                      Container(
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
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const _OutcomeLine(text: '1 готовое фото'),
                            const SizedBox(height: 4),
                            const _OutcomeLine(text: 'Стоимость: 1 изображение'),
                            const SizedBox(height: 4),
                            const _OutcomeLine(
                              text: 'Сохранится в готовых фото',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const GoodResultGuideCard(style: GoodResultGuideStyle.sheet),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _isCreating
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF7C5CFF),
                                      Color(0xFF4A7CFF),
                                    ],
                                  ),
                            color: _isCreating ? Colors.grey.shade300 : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isCreating
                                ? null
                                : [
                                    BoxShadow(
                                      color: _accentColor.withValues(alpha: 0.3),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isCreating ? null : _onCreatePressed,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: _isCreating
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Создать фото',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutcomeLine extends StatelessWidget {
  const _OutcomeLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 16,
          color: const Color(0xFF5B6CFF).withValues(alpha: 0.85),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}
