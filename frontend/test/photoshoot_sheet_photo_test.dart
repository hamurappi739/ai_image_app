import 'package:ai_image_generator/main.dart';
import 'package:ai_image_generator/models/user_balance.dart';
import 'package:ai_image_generator/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TrackingApiService extends ApiService {
  bool generatePhotoshootCalled = false;

  @override
  Future<PhotoshootGenerateResponse> generatePhotoshootWithProgress({
    required String styleId,
    required String styleTitle,
    required XFile photoFile,
    String? description,
    void Function(PhotoshootJobStatusResponse status)? onStatus,
  }) async {
    generatePhotoshootCalled = true;
    throw StateError('generatePhotoshootWithProgress should not be called');
  }
}

const _testBalance = UserBalance(
  freeGenerationsLimit: 3,
  freeGenerationsUsed: 3,
  freeGenerationsRemaining: 0,
  paidImageGenerations: 10,
  paidPhotoshoots: 0,
  totalAvailableImages: 10,
  photoshootImageCost: 3,
  availablePhotoshootsByImages: 3,
  consumptionEnabled: true,
);

Future<void> _pumpFrames(WidgetTester tester, [int count = 3]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openFirstFreePhotoshootSheet(
  WidgetTester tester,
  ApiService apiService,
) async {
  SharedPreferences.setMockInitialValues({
    'photoshoots_help_seen': true,
  });

  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: PhotoshootsScreen(
        isActive: true,
        apiService: apiService,
        balance: _testBalance,
        balanceLoading: false,
        onPhotoshootGenerated: (_) {},
        onBalanceUpdated: (_) {},
        onRefreshBalance: () {},
        onOpenGallery: () {},
        onOpenPacks: () {},
      ),
    ),
  );
  await _pumpFrames(tester, 5);

  final tryButton = find.text('Попробовать').first;
  await tester.scrollUntilVisible(
    tryButton,
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await _pumpFrames(tester);
  await tester.tap(tryButton);
  await _pumpFrames(tester, 5);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('photoshoot sheet without photo shows MissingPhotoDialog and skips API', (
    WidgetTester tester,
  ) async {
    final apiService = _TrackingApiService();
    await _openFirstFreePhotoshootSheet(tester, apiService);

    final createButton = find.text('Создать фотосессию');
    await tester.scrollUntilVisible(
      createButton,
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await _pumpFrames(tester);
    await tester.tap(createButton);
    await _pumpFrames(tester, 5);

    expect(find.text('Сначала выберите фото для фотосессии.'), findsOneWidget);
    expect(find.text('Хорошо'), findsOneWidget);
    expect(apiService.generatePhotoshootCalled, isFalse);
  });

  testWidgets('debug Android photoshoot sheet does not auto-select mock photo', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    try {
      await _openFirstFreePhotoshootSheet(tester, _TrackingApiService());

      expect(
        find.text('Для проверки на эмуляторе используется тестовое фото.'),
        findsNothing,
      );
      expect(find.text('Убрать фото'), findsNothing);
      expect(find.text('Выбрать фото'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
