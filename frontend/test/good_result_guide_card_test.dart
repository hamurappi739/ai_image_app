import 'package:ai_image_generator/screens/template_photo_screen.dart';
import 'package:ai_image_generator/services/api_service.dart';
import 'package:ai_image_generator/theme/app_theme.dart';
import 'package:ai_image_generator/widgets/good_result_guide_card.dart';
import 'package:ai_image_generator/widgets/template_create_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PhotoTemplate _testTemplate({required String title}) {
  return PhotoTemplate(
    id: 'test-template',
    title: title,
    description: 'Short',
    requestDescription: 'Prompt text',
    visualKind: TemplateVisualKind.vibrant,
    placeholderColors: const [Color(0xFFEEF1FF), Color(0xFF5B6CFF)],
  );
}

void main() {
  testWidgets('GoodResultGuideCard shows readable labels in dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 360,
              child: GoodResultGuideCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Хорошее фото'), findsOneWidget);
    expect(find.text('Плохое фото'), findsOneWidget);
    expect(
      find.textContaining('Лицо хорошо видно'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('TemplateCreateSheet smoke test in dark theme', (tester) async {
    final template = _testTemplate(title: 'Деловой портрет');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: TemplateCreateSheet(
            template: template,
            apiService: ApiService(),
            balance: null,
            balanceLoading: false,
            onImageGenerated: (_) {},
            onBalanceUpdated: (_) {},
            onRefreshBalance: () {},
            onOpenGallery: () {},
            onOpenPacks: () {},
            onShowMessage: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Деловой портрет'), findsOneWidget);
    expect(find.text('Добавьте фото'), findsOneWidget);
    expect(find.text('Что получится'), findsOneWidget);
    expect(find.text('Как получить хороший результат'), findsOneWidget);
  });
}
