import 'package:ai_image_generator/navigation/app_section.dart';
import 'package:ai_image_generator/screens/help_hub_screen.dart';
import 'package:ai_image_generator/screens/onboarding_screen.dart';
import 'package:ai_image_generator/theme/app_theme.dart';
import 'package:ai_image_generator/widgets/app_drawer.dart';
import 'package:ai_image_generator/widgets/good_photo_help_dialog.dart';
import 'package:ai_image_generator/widgets/paged_help_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AppDrawer does not show removed help onboarding items',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          drawer: AppDrawer(
            currentSection: AppSection.home,
            onSectionSelected: (_) {},
            themeMode: ThemeMode.light,
            onThemeModeChanged: (_) {},
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Помощь', skipOffstage: false), findsOneWidget);
    expect(find.text('Показать обучалку снова'), findsNothing);
    expect(find.text('Обучалки и подсказки'), findsNothing);
  });

  testWidgets('HelpHubScreen dark theme renders all help items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const HelpHubScreen(onRestartOnboarding: _noop),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Быстрый старт'), findsOneWidget);
    expect(find.text('Фото по шаблону'), findsOneWidget);
    expect(find.text('Фотосессии'), findsOneWidget);
    expect(find.text('Своя идея'), findsOneWidget);
    expect(find.text('Как выбрать хорошее фото'), findsOneWidget);
    expect(find.text('Галерея и скачивание'), findsOneWidget);
    expect(find.text('Пройти заново'), findsOneWidget);
  });

  testWidgets('PagedHelpDialog renders in dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => PagedHelpDialog(
                    blocks: OnboardingScreen.tutorialSteps.take(1).toList(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Ваши фото — в красивые образы'), findsOneWidget);
    expect(find.text('Понятно'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GoodPhotoHelpDialog dark theme smoke test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => GoodPhotoHelpDialog.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Добавляйте хорошее фото'), findsOneWidget);
    expect(find.text('Хорошее фото'), findsOneWidget);
    expect(find.text('Плохое фото'), findsOneWidget);
  });
}

void _noop() {}
