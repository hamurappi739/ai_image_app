import 'package:ai_image_generator/models/user_balance.dart';
import 'package:ai_image_generator/main.dart';
import 'package:ai_image_generator/navigation/app_section.dart';
import 'package:ai_image_generator/services/theme_preferences_service.dart';
import 'package:ai_image_generator/theme/app_theme.dart';
import 'package:ai_image_generator/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDrawer dark theme toggle', () {
    testWidgets('shows dark theme switch', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
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

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Тёмная тема'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('toggle calls onThemeModeChanged with dark mode', (tester) async {
      ThemeMode? changedMode;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: Scaffold(
            drawer: AppDrawer(
              currentSection: AppSection.home,
              onSectionSelected: (_) {},
              themeMode: ThemeMode.light,
              onThemeModeChanged: (mode) => changedMode = mode,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(changedMode, ThemeMode.dark);
    });

    testWidgets('switch reflects dark theme mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            drawer: AppDrawer(
              currentSection: AppSection.home,
              onSectionSelected: (_) {},
              themeMode: ThemeMode.dark,
              onThemeModeChanged: (_) {},
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('dark drawer shows readable user and balance block', (tester) async {
      const balance = UserBalance(
        freeGenerationsLimit: 3,
        freeGenerationsUsed: 0,
        freeGenerationsRemaining: 2,
        paidImageGenerations: 5,
        paidPhotoshoots: 0,
        totalAvailableImages: 7,
        photoshootImageCost: 3,
        availablePhotoshootsByImages: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            drawer: AppDrawer(
              currentSection: AppSection.home,
              onSectionSelected: (_) {},
              themeMode: ThemeMode.dark,
              onThemeModeChanged: (_) {},
              showUserBalance: true,
              balance: balance,
              userEmail: 'reader@example.com',
              onBuyTap: () {},
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Здравствуйте'), findsOneWidget);
      expect(find.text('reader@example.com'), findsOneWidget);
      expect(find.text('Ваш баланс'), findsOneWidget);
      expect(find.text('Купить'), findsOneWidget);
      expect(find.textContaining('Изображения'), findsOneWidget);
      expect(find.text('7'), findsWidgets);
    });
  });

  group('ThemePreferencesService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads light theme by default', () async {
      expect(await ThemePreferencesService.loadThemeMode(), ThemeMode.light);
    });

    test('persists dark theme preference', () async {
      await ThemePreferencesService.saveThemeMode(ThemeMode.dark);
      expect(await ThemePreferencesService.loadThemeMode(), ThemeMode.dark);
    });
  });

  testWidgets('app starts with saved dark theme', (tester) async {
    SharedPreferences.setMockInitialValues({
      'app_theme_mode': 'dark',
    });

    await tester.pumpWidget(const AiImageGeneratorApp());
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
  });
}
