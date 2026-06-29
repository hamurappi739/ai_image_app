import 'package:ai_image_generator/main.dart';
import 'package:ai_image_generator/services/api_service.dart';
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

    await tester.enterText(
      find.byType(TextField).at(0),
      'reader@example.com',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'secret123',
    );
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
}
