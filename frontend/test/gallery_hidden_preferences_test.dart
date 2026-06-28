import 'package:ai_image_generator/services/gallery_hidden_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and load hidden gallery keys', () async {
    await GalleryHiddenPreferences.save(
      imageKeys: {'id:img-1', 'url:https://example.com/a.jpg'},
      photoshootIds: {'ps-1'},
    );

    final loaded = await GalleryHiddenPreferences.load();

    expect(loaded.imageKeys, {'id:img-1', 'url:https://example.com/a.jpg'});
    expect(loaded.photoshootIds, {'ps-1'});
  });

  test('clear removes persisted hidden keys', () async {
    await GalleryHiddenPreferences.save(
      imageKeys: {'id:img-1'},
      photoshootIds: {'ps-1'},
    );

    await GalleryHiddenPreferences.clear();
    final loaded = await GalleryHiddenPreferences.load();

    expect(loaded.imageKeys, isEmpty);
    expect(loaded.photoshootIds, isEmpty);
  });
}
