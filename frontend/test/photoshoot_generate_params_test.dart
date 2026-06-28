import 'package:ai_image_generator/utils/gallery_display_title.dart';
import 'package:ai_image_generator/utils/photoshoot_generate_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog photoshoot omits description field', () {
    expect(
      photoshootGenerateDescription(styleId: 'summer_photoshoot'),
      isNull,
    );
    expect(
      photoshootGenerateDescription(
        styleId: 'studio_portrait',
        userDescription: 'Long catalog style prompt that must not be sent',
      ),
      isNull,
    );
  });

  test('custom photoshoot sends trimmed user description', () {
    expect(
      photoshootGenerateDescription(
        styleId: customPhotoshootStyleId,
        userDescription: '  Деловой образ в светлой студии  ',
      ),
      'Деловой образ в светлой студии',
    );
    expect(
      photoshootGenerateDescription(
        styleId: customPhotoshootStyleId,
        userDescription: '   ',
      ),
      isNull,
    );
  });

  test('template gallery local label uses Шаблон prefix', () {
    expect(
      templateGalleryDescription('Яркий образ'),
      '$galleryTemplatePrefixЯркий образ',
    );
    expect(
      gallerySinglePhotoTitle('$galleryTemplatePrefixЯркий образ'),
      'Яркий образ',
    );
  });
}
