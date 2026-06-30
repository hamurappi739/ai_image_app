/// Optional upload hints for specific catalog templates (by stable id).
String? templatePhotoUploadReminder(String templateId) {
  switch (templateId) {
    case 'family_photo':
      return 'Загрузите одну фотографию, где хорошо видны все члены семьи. '
          'По одному отдельному фото каждого человека добавлять не нужно.';
    case 'photo_with_child':
      return 'Загрузите одну фотографию, где хорошо видны вы и ребёнок вместе.';
    default:
      return null;
  }
}
