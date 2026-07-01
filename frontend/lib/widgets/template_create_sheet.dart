import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/catalog_entries.dart';
import '../models/generated_image_item.dart';
import '../theme/app_theme.dart';
import '../utils/gallery_display_title.dart';
import '../utils/template_generation_params.dart';
import '../utils/template_photo_reminders.dart';
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
  static const _sheetPreviewAspectRatio = 1.0;

  final _imagePicker = ImagePicker();
  final Map<String, TextEditingController> _fieldControllers = {};
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
  void initState() {
    super.initState();
    final fields = widget.template.inputRequirements?.fields ?? const [];
    for (final field in fields) {
      _fieldControllers.putIfAbsent(field.type, TextEditingController.new);
    }
  }

  @override
  void dispose() {
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
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

  String _missingPhotoMessage(CatalogTemplatePhotoInput photoInput) {
    if (photoInput.field == 'baby_photo') {
      return 'Добавьте фото ребёнка в детстве';
    }
    if (photoInput.field == 'child_photo') {
      if (photoInput.label.contains('сейчас')) {
        return 'Добавьте фото ребёнка сейчас';
      }
      return 'Добавьте фото ребёнка';
    }
    return switch (photoInput.field) {
      'pet_photo' => 'Добавьте фото питомца',
      _ => 'Добавьте ваше фото',
    };
  }

  String? _validateAgeNumber(String value, {required String emptyMessage}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return emptyMessage;
    }
    if (!RegExp(r'^[1-9]\d?$').hasMatch(trimmed)) {
      return 'Введите только цифры';
    }
    return null;
  }

  String? _validateChildName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Введите имя ребёнка';
    }
    if (trimmed.length > 20) {
      return 'В имени должны быть только буквы';
    }
    if (!RegExp(r"^[A-Za-zА-Яа-яЁё\- ]+$").hasMatch(trimmed)) {
      return 'В имени должны быть только буквы';
    }
    return null;
  }

  String? _validateField(CatalogTemplateFieldInput field, String value) {
    return switch (field.type) {
      'cake_digit' => _validateAgeNumber(
          value,
          emptyMessage: 'Введите цифру на торте',
        ),
      'age_number' => _validateAgeNumber(
          value,
          emptyMessage: field.label.contains('Цифра')
              ? 'Введите цифру на торте'
              : 'Введите возраст',
        ),
      'child_name' => _validateChildName(value),
      _ => null,
    };
  }

  String? _fieldControllerText(String type) {
    return _fieldControllers[type]?.text.trim();
  }

  XFile? _optionalPhotoFile(String field, {required String primaryField}) {
    if (field == primaryField) return null;
    return _photosByField[field]?.file;
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
          widget.onShowMessage(_missingPhotoMessage(photoReq));
          return;
        }
      }
      for (final fieldReq in requirements.fields) {
        final controller = _fieldControllers[fieldReq.type];
        final validationError = _validateField(
          fieldReq,
          controller?.text ?? '',
        );
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

    final primaryField = templateGenerationPrimaryPhotoField(widget.template);
    final primaryPhoto = _photosByField[primaryField];
    if (primaryPhoto == null) return;

    final templateId = templateGenerationTemplateId(widget.template);
    final extraInputCount = templateGenerationExtraInputCount(
      template: widget.template,
      populatedPhotoFields: _photosByField.keys,
    );
    debugLogTemplateGeneration(
      templateId: templateId,
      templateTitle: widget.template.title,
      primaryPhotoField: primaryField,
      extraInputCount: extraInputCount,
    );

    setState(() => _isCreating = true);

    final prompt = widget.template.requestDescription;

    try {
      final response =
          await GenerationProgressDialog.run<GenerateImageResponse>(
        context: context,
        title: 'Создаём фото…',
        subtitle: 'Обычно это занимает 1–3 минуты.',
        totalSeconds: 180,
        task: () => widget.apiService.generateImageWithPhoto(
          description: prompt,
          primaryPhotoFile: primaryPhoto.file,
          primaryPhotoField: primaryField,
          templateId: templateId,
          petPhotoFile: _optionalPhotoFile('pet_photo', primaryField: primaryField),
          childPhotoFile:
              _optionalPhotoFile('child_photo', primaryField: primaryField),
          babyPhotoFile: _optionalPhotoFile('baby_photo', primaryField: primaryField),
          cakeDigit: _fieldControllerText('cake_digit'),
          ageNumber: _fieldControllerText('age_number'),
          childName: _fieldControllerText('child_name'),
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
          description: '$galleryTemplatePrefix${widget.template.title}',
          imageUrl: response.imageUrl,
          thumbnailUrl: response.thumbnailUrl,
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
    } on PhotoGenerationServiceUnavailableException {
      if (!mounted) return;
      widget.onShowMessage(
        'Сервис временно не ответил. Попробуйте ещё раз через минуту.',
      );
    } catch (_) {
      if (!mounted) return;
      widget.onShowMessage('Не удалось создать фото. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Widget _buildPhotoUploadReminder(ThemeData theme) {
    final reminder = templatePhotoUploadReminder(widget.template.id);
    if (reminder == null) return const SizedBox.shrink();

    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: colors.infoBannerFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: context.appAccent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reminder,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.35,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinglePhotoSection(ThemeData theme) {
    final colors = context.appColors;
    final textPrimary = context.appTextPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Добавьте фото',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _buildPhotoUploadReminder(theme),
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
                  foregroundColor: colors.textSecondary,
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
    final colors = context.appColors;
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
                    foregroundColor: colors.textSecondary,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Добавьте фото',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _buildPhotoUploadReminder(theme),
        for (final photoInput in requirements.photos)
          _buildMultiPhotoSlot(photoInput),
        for (final fieldInput in requirements.fields) ...[
          const SizedBox(height: 4),
          Text(
            fieldInput.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _fieldControllers[fieldInput.type],
            enabled: !_isCreating,
            keyboardType: switch (fieldInput.type) {
              'child_name' => TextInputType.name,
              'cake_digit' || 'age_number' => TextInputType.number,
              _ => TextInputType.text,
            },
            inputFormatters: switch (fieldInput.type) {
              'child_name' => [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-zА-Яа-яЁё\- ]'),
                ),
                LengthLimitingTextInputFormatter(20),
              ],
              'cake_digit' || 'age_number' => [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              _ => const [],
            },
            decoration: InputDecoration(
              hintText: switch (fieldInput.type) {
                'child_name' => 'Например, Маша',
                'cake_digit' || 'age_number' => 'Например, 3',
                _ => null,
              },
              filled: true,
              fillColor: context.appColors.subtleFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.appColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.appColors.borderColor),
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
    final colors = context.appColors;
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
            color: colors.cardBackground,
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
                          color: colors.borderColor,
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
                              color: context.appTextPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _isCreating
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: context.appTextPrimary),
                          tooltip: 'Закрыть',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: _sheetPreviewAspectRatio,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return PreviewAssetImage(
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
                                height: constraints.maxHeight,
                                compact: true,
                              ),
                            );
                          },
                        ),
                      ),
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
                            color: colors.textSecondary,
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
                          color: colors.subtleFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Что получится',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const _OutcomeLine(text: '1 готовое фото'),
                            const SizedBox(height: 4),
                            const _OutcomeLine(text: 'Стоимость: 1 фото'),
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
    final colors = context.appColors;
    final accent = context.appAccent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 16,
          color: accent.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
