import 'package:flutter/foundation.dart';

import '../screens/template_photo_screen.dart';

/// Catalog template id sent to POST /generate-with-photo.
String templateGenerationTemplateId(PhotoTemplate template) => template.id;

/// Multipart field name for the primary user photo.
String templateGenerationPrimaryPhotoField(PhotoTemplate template) {
  final requirements = template.inputRequirements;
  if (template.isMultiInputTemplate &&
      requirements != null &&
      requirements.photos.isNotEmpty) {
    return requirements.photos.first.field;
  }
  return 'photo';
}

/// Additional photo inputs beyond the primary field (pet, child, etc.).
int templateGenerationExtraInputCount({
  required PhotoTemplate template,
  required Iterable<String> populatedPhotoFields,
}) {
  final primaryField = templateGenerationPrimaryPhotoField(template);
  return populatedPhotoFields.where((field) => field != primaryField).length;
}

/// Custom «Своя идея» flow must not send template_id.
bool shouldSendTemplateGenerationId({String? templateId}) {
  final trimmed = templateId?.trim();
  return trimmed != null && trimmed.isNotEmpty;
}

void debugLogTemplateGeneration({
  required String templateId,
  required String templateTitle,
  required String primaryPhotoField,
  required int extraInputCount,
}) {
  if (!kDebugMode) return;
  debugPrint(
    'Template generate: id=$templateId '
    'title=$templateTitle '
    'primaryPhotoField=$primaryPhotoField '
    'extraInputCount=$extraInputCount',
  );
}
