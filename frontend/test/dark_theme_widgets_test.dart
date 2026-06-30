import 'package:ai_image_generator/main.dart';
import 'package:ai_image_generator/models/user_balance.dart';
import 'package:ai_image_generator/services/api_service.dart';
import 'package:ai_image_generator/services/payment_service.dart';
import 'package:ai_image_generator/services/auth_service.dart';
import 'package:ai_image_generator/theme/app_theme.dart';
import 'package:ai_image_generator/widgets/profile/profile_email_auth_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ProfileEmailAuthSheet renders in dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: ProfileEmailAuthSheet(authService: AuthService()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Вход по почте'), findsOneWidget);
    expect(find.text('Введите email и пароль от вашего аккаунта.'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Пароль'), findsOneWidget);
    expect(find.text('Забыли пароль?'), findsOneWidget);
    expect(find.text('Создать аккаунт'), findsWidgets);

    await tester.tap(find.text('Забыли пароль?'));
    await tester.pumpAndSettle();

    expect(find.text('Восстановить пароль'), findsOneWidget);
    expect(find.text('Отправить ссылку'), findsOneWidget);
    expect(find.text('Пароль'), findsNothing);

    await tester.enterText(find.byType(TextField), 'reader@example.com');
    await tester.pump();

    expect(find.text('reader@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PhotoshootsScreen promo banner has no overflow in dark theme',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'photoshoots_help_seen': true,
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: PhotoshootsScreen(
                isActive: true,
                apiService: ApiService(),
                balance: null,
                balanceLoading: false,
                onPhotoshootGenerated: (_) {},
                onBalanceUpdated: (_) {},
                onRefreshBalance: () {},
                onOpenGallery: () {},
                onOpenPacks: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('Не нашли подходящий стиль?'), findsOneWidget);
    expect(find.text('Создать свой образ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PacksScreen renders in dark theme at narrow width', (tester) async {
    const balance = UserBalance(
      freeGenerationsLimit: 3,
      freeGenerationsUsed: 1,
      freeGenerationsRemaining: 0,
      paidImageGenerations: 55,
      paidPhotoshoots: 0,
      totalAvailableImages: 55,
      photoshootImageCost: 3,
      availablePhotoshootsByImages: 18,
      consumptionEnabled: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: PacksScreen(
                paymentService: PaymentService(apiService: ApiService()),
                balance: balance,
                balanceLoading: false,
                balanceLoadFailed: false,
                onRefreshBalance: () {},
                onBalanceUpdated: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ваш баланс'), findsOneWidget);
    expect(find.text('1 генерация = 1 фото'), findsOneWidget);
    expect(find.textContaining('Фотосессия = 3 фото'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
