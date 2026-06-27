import 'package:flutter/material.dart';
import 'package:ai_image_generator/models/catalog_entries.dart';
import 'package:ai_image_generator/screens/template_photo_screen.dart';
import 'package:ai_image_generator/utils/template_generation_params.dart';
import 'package:flutter_test/flutter_test.dart';

PhotoTemplate _template({
  required String id,
  CatalogTemplateInputRequirements? inputRequirements,
}) {
  return PhotoTemplate(
    id: id,
    title: 'Test template',
    description: 'Short',
    requestDescription: 'Prompt text',
    visualKind: TemplateVisualKind.vibrant,
    placeholderColors: const [Color(0xFFEEF1FF), Color(0xFF5B6CFF)],
  ).copyWithInputRequirements(inputRequirements);
}

extension _PhotoTemplateTestHelpers on PhotoTemplate {
  PhotoTemplate copyWithInputRequirements(
    CatalogTemplateInputRequirements? inputRequirements,
  ) {
    return PhotoTemplate(
      id: id,
      title: title,
      description: description,
      requestDescription: requestDescription,
      visualKind: visualKind,
      placeholderColors: placeholderColors,
      previewLabel: previewLabel,
      previewAssetPath: previewAssetPath,
      previewUrl: previewUrl,
      generationBlocked: generationBlocked,
      generationBlockedMessage: generationBlockedMessage,
      inputRequirements: inputRequirements,
    );
  }
}

void main() {
  test('single-input vibrant_look sends template_id vibrant_look', () {
    final template = _template(id: 'vibrant_look');

    expect(templateGenerationTemplateId(template), 'vibrant_look');
    expect(shouldSendTemplateGenerationId(templateId: template.id), isTrue);
    expect(templateGenerationPrimaryPhotoField(template), 'photo');
  });

  test('normal catalog template always resolves template id', () {
    final template = _template(id: 'beautiful_portrait');

    expect(templateGenerationTemplateId(template), 'beautiful_portrait');
    expect(shouldSendTemplateGenerationId(templateId: template.id), isTrue);
  });

  test('custom idea omits template_id when null or empty', () {
    expect(shouldSendTemplateGenerationId(templateId: null), isFalse);
    expect(shouldSendTemplateGenerationId(templateId: ''), isFalse);
    expect(shouldSendTemplateGenerationId(templateId: '   '), isFalse);
  });

  test('multi-input woman_with_cat keeps template_id and pet extra input', () {
    final template = _template(
      id: 'woman_with_cat',
      inputRequirements: const CatalogTemplateInputRequirements(
        photos: [
          CatalogTemplatePhotoInput(
            id: 'user_photo',
            field: 'photo',
            label: 'User',
          ),
          CatalogTemplatePhotoInput(
            id: 'pet_photo',
            field: 'pet_photo',
            label: 'Pet',
          ),
        ],
        fields: [],
      ),
    );

    expect(templateGenerationTemplateId(template), 'woman_with_cat');
    expect(templateGenerationPrimaryPhotoField(template), 'photo');
    expect(
      templateGenerationExtraInputCount(
        template: template,
        populatedPhotoFields: const ['photo', 'pet_photo'],
      ),
      1,
    );
  });

  test('child birthday template uses child_photo as primary field', () {
    final template = _template(
      id: 'child_birthday_number',
      inputRequirements: const CatalogTemplateInputRequirements(
        photos: [
          CatalogTemplatePhotoInput(
            id: 'child_photo',
            field: 'child_photo',
            label: 'Child',
          ),
        ],
        fields: [
          CatalogTemplateFieldInput(
            id: 'age_number',
            label: 'Age',
            type: 'age_number',
          ),
        ],
      ),
    );

    expect(templateGenerationTemplateId(template), 'child_birthday_number');
    expect(templateGenerationPrimaryPhotoField(template), 'child_photo');
  });

  test('vibrant_look catalog entry maps id and primary photo field', () {
    final template = PhotoTemplate.fromCatalog(
      CatalogTemplateEntry(
        id: 'vibrant_look',
        title: 'Яркий образ',
        category: 'Для себя',
        shortDescription: 'Стильный образ с выразительными цветами.',
        prompt: 'Создай яркий стильный образ…',
        previewAsset: 'assets/previews/templates/bright_look.jpg',
        referenceAsset: 'assets/previews/templates/bright_look.jpg',
        priceImages: 1,
        isActive: true,
        sortOrder: 60,
      ),
    );

    expect(template.id, 'vibrant_look');
    expect(template.title, 'Яркий образ');
    expect(templateGenerationTemplateId(template), 'vibrant_look');
    expect(templateGenerationPrimaryPhotoField(template), 'photo');
    expect(template.isMultiInputTemplate, isFalse);
  });
}
