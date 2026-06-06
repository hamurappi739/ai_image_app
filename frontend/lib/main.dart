import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/gallery_display_item.dart';
import 'models/generated_image_item.dart';
import 'models/user_balance.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/create_help_service.dart';
import 'services/onboarding_service.dart';
import 'services/photoshoots_help_service.dart';
import 'utils/mock_photoshoot_photo.dart';
import 'widgets/create_help_dialog.dart';
import 'widgets/generation_progress_dialog.dart';
import 'widgets/insufficient_balance_dialog.dart';
import 'widgets/packs_help_dialog.dart';
import 'widgets/photoshoots_help_dialog.dart';
import 'widgets/section_help_button.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final url = supabaseUrl.trim();
  final anonKey = supabaseAnonKey.trim();

  if (url.isNotEmpty && anonKey.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: anonKey);
  } else if (kDebugMode) {
    // ignore: avoid_print
    print('Supabase is not configured for Flutter; auth disabled');
  }

  runApp(const AiImageGeneratorApp());
}

class AiImageGeneratorApp extends StatelessWidget {
  const AiImageGeneratorApp({super.key});

  static const Color scaffoldBackground = Color(0xFFF7F8FC);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Фотогенератор',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: scaffoldBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B6CFF),
          brightness: Brightness.light,
          surface: cardColor,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            color: textSecondary,
            height: 1.4,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ),
      home: const AppEntry(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.onResetOnboarding});

  final VoidCallback? onResetOnboarding;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _accentColor = Color(0xFF5B6CFF);

  final _apiService = ApiService();
  final _authService = AuthService();

  int _selectedIndex = 0;
  final List<GeneratedImageItem> _generatedImages = [];
  bool _backendHistoryUnavailable = false;
  UserBalance? _userBalance;
  bool _balanceLoading = false;
  bool _balanceLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _syncAccessTokenFromAuth();
    _loadGenerationsFromBackend();
    _loadBalance();
  }

  void _syncAccessTokenFromAuth() {
    if (_authService.isConfigured && _authService.isSignedIn) {
      _apiService.setAccessToken(_authService.accessToken);
    } else {
      _apiService.setAccessToken(null);
    }
  }

  void _onProfileAuthChanged() {
    _syncAccessTokenFromAuth();
    _loadGenerationsFromBackend();
    _loadBalance();
    setState(() {});
  }

  Future<void> _loadBalance() async {
    if (!mounted) return;
    setState(() {
      _balanceLoading = true;
      _balanceLoadFailed = false;
    });
    try {
      final balance = await _apiService.fetchBalance();
      if (!mounted) return;
      setState(() {
        _userBalance = balance;
        _balanceLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _balanceLoading = false;
        _balanceLoadFailed = true;
      });
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0 || index == 3 || index == 4) {
      _loadBalance();
    }
  }

  void _updateBalance(UserBalance balance) {
    setState(() => _userBalance = balance);
  }

  Future<void> _loadGenerationsFromBackend() async {
    try {
      final history = await _apiService.fetchGenerations();
      if (!mounted) return;
      setState(() {
        _backendHistoryUnavailable = false;
        _generatedImages
          ..clear()
          ..addAll(history.map((item) => item.toGalleryItem()));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _backendHistoryUnavailable = true);
    }
  }

  void _goToCreateTab() => setState(() => _selectedIndex = 0);

  void _goToGalleryTab() => setState(() => _selectedIndex = 2);

  void _goToPacksTab() {
    setState(() => _selectedIndex = 3);
    _loadBalance();
  }

  void _onImageGenerated(GeneratedImageItem item) {
    setState(() {
      if (item.id != null) {
        _generatedImages.removeWhere((existing) => existing.id == item.id);
      }
      _generatedImages.insert(0, item);
    });
  }

  void _onPhotoshootGenerated(List<GeneratedImageItem> items) {
    setState(() {
      _generatedImages.insertAll(0, items);
    });
  }

  void _clearGallery() {
    setState(() => _generatedImages.clear());
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      CreateScreen(
        isActive: _selectedIndex == 0,
        apiService: _apiService,
        balance: _userBalance,
        balanceLoading: _balanceLoading,
        onImageGenerated: _onImageGenerated,
        onBalanceUpdated: _updateBalance,
        onOpenGallery: _goToGalleryTab,
        onOpenPacks: _goToPacksTab,
      ),
      PhotoshootsScreen(
        isActive: _selectedIndex == 1,
        apiService: _apiService,
        balance: _userBalance,
        balanceLoading: _balanceLoading,
        onPhotoshootGenerated: _onPhotoshootGenerated,
        onBalanceUpdated: _updateBalance,
        onOpenGallery: _goToGalleryTab,
        onOpenPacks: _goToPacksTab,
      ),
      GalleryScreen(
        images: _generatedImages,
        onCreateFirst: _goToCreateTab,
        onClearGallery: _clearGallery,
        backendHistoryUnavailable: _backendHistoryUnavailable,
      ),
      PacksScreen(
        balance: _userBalance,
        balanceLoading: _balanceLoading,
        balanceLoadFailed: _balanceLoadFailed,
        onRefreshBalance: _loadBalance,
      ),
      ProfileScreen(
        authService: _authService,
        apiService: _apiService,
        onAuthChanged: _onProfileAuthChanged,
        onResetOnboarding: widget.onResetOnboarding,
        balance: _userBalance,
        balanceLoading: _balanceLoading,
        balanceLoadFailed: _balanceLoadFailed,
        onRefreshBalance: _loadBalance,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: _accentColor,
        unselectedItemColor: AiImageGeneratorApp.textSecondary,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Создать',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera),
            label: 'Фотосессии',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Галерея',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Пакеты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final completed = await OnboardingService.isCompleted();
    if (!mounted) return;
    setState(() => _onboardingCompleted = completed);
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.setCompleted(completed: true);
    if (!mounted) return;
    setState(() => _onboardingCompleted = true);
  }

  Future<void> _resetOnboardingForDebug() async {
    await OnboardingService.reset();
    if (!mounted) return;
    setState(() => _onboardingCompleted = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingCompleted == null) {
      return const Scaffold(
        backgroundColor: AiImageGeneratorApp.scaffoldBackground,
        body: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (!_onboardingCompleted!) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    return MainShell(
      onResetOnboarding: kDebugMode ? _resetOnboardingForDebug : null,
    );
  }
}

class _PackOffering {
  const _PackOffering({
    required this.priceRub,
    required this.imageCount,
    required this.subtitle,
    this.photoshootCount = 0,
    this.featured = false,
  });

  final int priceRub;
  final int imageCount;
  final int photoshootCount;
  final String subtitle;
  final bool featured;

  String get priceLabel => '$priceRub ₽';
}

enum _PackCatalogMode { withPhotoshoots, imagesOnly }

String _packPhotoshootLabel(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'фотосессий';
  if (mod10 == 1) return 'фотосессия';
  if (mod10 >= 2 && mod10 <= 4) return 'фотосессии';
  return 'фотосессий';
}

String _packImageLabel(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'изображений';
  if (mod10 == 1) return 'изображение';
  if (mod10 >= 2 && mod10 <= 4) return 'изображения';
  return 'изображений';
}

void _showPackPaymentSoonDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Оплата скоро появится',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      content: const Text(
        'Сейчас это демонстрационный режим. Позже здесь будет подключена '
        'оплата и автоматическое пополнение баланса.',
        style: TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF6B7280)),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5B6CFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Понятно'),
        ),
      ],
    ),
  );
}

String _formatPackReceiveSummary(int images, int photoshoots) {
  if (photoshoots > 0 && images > 0) {
    return 'Вы получите: $images ${_packImageLabel(images)} '
        'и $photoshoots ${_packPhotoshootLabel(photoshoots)}';
  }
  if (photoshoots > 0) {
    return 'Вы получите: $photoshoots ${_packPhotoshootLabel(photoshoots)}';
  }
  if (images > 0) {
    return 'Вы получите: $images ${_packImageLabel(images)}';
  }
  return 'Увеличьте сумму или уменьшите число фотосессий';
}

class PacksScreen extends StatefulWidget {
  const PacksScreen({
    super.key,
    required this.balance,
    required this.balanceLoading,
    required this.balanceLoadFailed,
    required this.onRefreshBalance,
  });

  final UserBalance? balance;
  final bool balanceLoading;
  final bool balanceLoadFailed;
  final VoidCallback onRefreshBalance;

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  static const _breakpointMedium = 560.0;
  static const _breakpointWide = 900.0;

  static const _imageUnitRub = 10;
  static const _photoshootUnitRub = 100;
  static const _customAmountMin = 10;
  static const _customAmountMax = 100000;

  static const _mixedPackages = <_PackOffering>[
    _PackOffering(
      priceRub: 199,
      photoshootCount: 1,
      imageCount: 9,
      subtitle: 'Для первого теста',
    ),
    _PackOffering(
      priceRub: 499,
      photoshootCount: 3,
      imageCount: 19,
      subtitle: 'Оптимальный вариант',
      featured: true,
    ),
    _PackOffering(
      priceRub: 999,
      photoshootCount: 8,
      imageCount: 19,
      subtitle: 'Для активного использования',
    ),
  ];

  static const _imagesOnlyPackages = <_PackOffering>[
    _PackOffering(
      priceRub: 199,
      imageCount: 19,
      subtitle: 'Для первого теста',
    ),
    _PackOffering(
      priceRub: 499,
      imageCount: 49,
      subtitle: 'Оптимальный вариант',
      featured: true,
    ),
    _PackOffering(
      priceRub: 999,
      imageCount: 99,
      subtitle: 'Для активного использования',
    ),
  ];

  _PackCatalogMode _catalogMode = _PackCatalogMode.withPhotoshoots;
  int _customPhotoshootCount = 8;
  late final TextEditingController _customAmountController;

  @override
  void initState() {
    super.initState();
    _customAmountController = TextEditingController(text: '1000');
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  List<_PackOffering> get _activePackages => _catalogMode == _PackCatalogMode.withPhotoshoots
      ? _mixedPackages
      : _imagesOnlyPackages;

  int? _parseCustomAmount(String text) {
    final trimmed = text.replaceAll(RegExp(r'\s'), '');
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  String? _customAmountErrorFor(String text) {
    final trimmed = text.replaceAll(RegExp(r'\s'), '');
    if (trimmed.isEmpty) {
      return 'Минимальная сумма — 10 ₽.';
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < _customAmountMin) {
      return 'Минимальная сумма — 10 ₽.';
    }
    if (parsed > _customAmountMax) {
      return 'Максимальная сумма пополнения — 100 000 ₽';
    }
    return null;
  }

  int? get _validCustomAmount {
    final parsed = _parseCustomAmount(_customAmountController.text);
    if (parsed == null) return null;
    if (parsed < _customAmountMin || parsed > _customAmountMax) return null;
    return parsed;
  }

  bool get _isCustomAmountValid => _validCustomAmount != null;

  int get _maxCustomPhotoshoots =>
      (_validCustomAmount ?? 0) ~/ _photoshootUnitRub;

  int get _customImageCount {
    final amount = _validCustomAmount;
    if (amount == null) return 0;
    final remainder =
        amount - (_customPhotoshootCount * _photoshootUnitRub);
    if (remainder <= 0) return 0;
    return remainder ~/ _imageUnitRub;
  }

  static int _columnCount(double width) {
    if (width >= _breakpointWide) return 3;
    if (width >= _breakpointMedium) return 2;
    return 1;
  }

  _PackCardLayout _packCardLayout(BuildContext context, int columns) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final scaleBump = textScale > 1.0 ? (textScale - 1) * 20 : 0.0;

    return switch (columns) {
      1 => _PackCardLayout(
          rowHeight: 272 + scaleBump,
          priceFontSize: 30,
          badgeFontSize: 14,
          statRowHeight: 30,
          subtitleFontSize: 14,
          buttonHeight: 42,
          buttonFontSize: 14,
          featuredBannerHeight: 30,
          featuredBannerFontSize: 13,
          contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        ),
      2 => _PackCardLayout(
          rowHeight: 238 + scaleBump,
          priceFontSize: 28,
          badgeFontSize: 13,
          statRowHeight: 28,
          subtitleFontSize: 13,
          buttonHeight: 38,
          buttonFontSize: 13,
          featuredBannerHeight: 28,
          featuredBannerFontSize: 12,
          contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        ),
      _ => _PackCardLayout(
          rowHeight: 226 + scaleBump,
          priceFontSize: 26,
          badgeFontSize: 12,
          statRowHeight: 26,
          subtitleFontSize: 12,
          buttonHeight: 36,
          buttonFontSize: 13,
          featuredBannerHeight: 28,
          featuredBannerFontSize: 12,
          contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        ),
    };
  }

  Widget _buildPackCardsGrid({
    required BuildContext context,
    required int columns,
    required bool showPhotoshoots,
    required VoidCallback onPaymentSoon,
  }) {
    const spacing = 16.0;
    final packages = _activePackages;
    final layout = _packCardLayout(context, columns);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent: layout.rowHeight,
      ),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        return Align(
          alignment: Alignment.topCenter,
          child: _PackOfferingCard(
            layout: layout,
            offering: packages[index],
            showPhotoshoots: showPhotoshoots,
            onPaymentSoon: onPaymentSoon,
          ),
        );
      },
    );
  }

  void _onCustomPaymentPressed() {
    if (!_isCustomAmountValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Минимальная сумма — 10 ₽.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    _showPackPaymentSoonDialog(context);
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => const PacksHelpDialog(),
    );
  }

  void _onCustomAmountChanged(String value) {
    setState(() {
      final valid = _parseCustomAmount(value);
      if (valid != null &&
          valid >= _customAmountMin &&
          valid <= _customAmountMax) {
        final maxSessions = valid ~/ _photoshootUnitRub;
        if (_customPhotoshootCount > maxSessions) {
          _customPhotoshootCount = maxSessions;
        }
      }
    });
  }

  void _setCustomPhotoshootCount(int count) {
    if (!_isCustomAmountValid) return;
    setState(() {
      _customPhotoshootCount = count.clamp(0, _maxCustomPhotoshoots);
    });
  }

  void _adjustCustomPhotoshoots(int delta) {
    _setCustomPhotoshootCount(_customPhotoshootCount + delta);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showPhotoshoots = _catalogMode == _PackCatalogMode.withPhotoshoots;

    return Scaffold(
      backgroundColor: AiImageGeneratorApp.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _columnCount(constraints.maxWidth);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Пакеты',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Пополните баланс изображений и фотосессий',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          SectionHelpButton(onPressed: _showHelp),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _UserBalancePacksBanner(
                        balance: widget.balance,
                        isLoading: widget.balanceLoading,
                        hasError: widget.balanceLoadFailed,
                        onRefresh: widget.onRefreshBalance,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Выберите тип пакета',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<_PackCatalogMode>(
                        segments: const [
                          ButtonSegment(
                            value: _PackCatalogMode.withPhotoshoots,
                            label: Text('С фотосессиями'),
                          ),
                          ButtonSegment(
                            value: _PackCatalogMode.imagesOnly,
                            label: Text('Только изображения'),
                          ),
                        ],
                        selected: {_catalogMode},
                        onSelectionChanged: (selection) {
                          setState(
                            () => _catalogMode = selection.first,
                          );
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          backgroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF5B6CFF);
                            }
                            return Colors.white;
                          }),
                          foregroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return AiImageGeneratorApp.textPrimary;
                          }),
                          side: WidgetStateProperty.all(
                            BorderSide(
                              color: const Color(0xFF5B6CFF)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        showPhotoshoots
                            ? 'Подходит, если нужны готовые серии фото '
                                'и отдельные изображения.'
                            : 'Подходит, если нужны только отдельные генерации.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          height: 1.35,
                          color: AiImageGeneratorApp.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        showPhotoshoots
                            ? 'Готовые пакеты с фотосессиями'
                            : 'Готовые пакеты — только изображения',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      _buildPackCardsGrid(
                        context: context,
                        columns: columns,
                        showPhotoshoots: showPhotoshoots,
                        onPaymentSoon: () =>
                            _showPackPaymentSoonDialog(context),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Своя сумма',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Выберите сумму и распределите её между изображениями '
                        'и фотосессиями.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CustomAmountSection(
                        amountController: _customAmountController,
                        amountError: _customAmountErrorFor(
                          _customAmountController.text,
                        ),
                        isAmountValid: _isCustomAmountValid,
                        validAmount: _validCustomAmount,
                        photoshootCount: _customPhotoshootCount,
                        maxPhotoshoots: _maxCustomPhotoshoots,
                        imageCount: _customImageCount,
                        onAmountChanged: _onCustomAmountChanged,
                        onPhotoshootCountChanged: _setCustomPhotoshootCount,
                        onPhotoshootsDecrease: _isCustomAmountValid &&
                                _customPhotoshootCount > 0
                            ? () => _adjustCustomPhotoshoots(-1)
                            : null,
                        onPhotoshootsIncrease: _isCustomAmountValid &&
                                _customPhotoshootCount < _maxCustomPhotoshoots
                            ? () => _adjustCustomPhotoshoots(1)
                            : null,
                        onPaymentPressed: _onCustomPaymentPressed,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PackCardLayout {
  const _PackCardLayout({
    required this.rowHeight,
    required this.priceFontSize,
    required this.badgeFontSize,
    required this.statRowHeight,
    required this.subtitleFontSize,
    required this.buttonHeight,
    required this.buttonFontSize,
    required this.featuredBannerHeight,
    required this.featuredBannerFontSize,
    required this.contentPadding,
  });

  final double rowHeight;
  final double priceFontSize;
  final double badgeFontSize;
  final double statRowHeight;
  final double subtitleFontSize;
  final double buttonHeight;
  final double buttonFontSize;
  final double featuredBannerHeight;
  final double featuredBannerFontSize;
  final EdgeInsets contentPadding;
}

class _PackOfferingCard extends StatelessWidget {
  const _PackOfferingCard({
    required this.layout,
    required this.offering,
    required this.showPhotoshoots,
    required this.onPaymentSoon,
  });

  final _PackCardLayout layout;
  final _PackOffering offering;
  final bool showPhotoshoots;
  final VoidCallback onPaymentSoon;

  static const _accentColor = Color(0xFF5B6CFF);
  static const _featuredGradient = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhotoshootLine =
        showPhotoshoots && offering.photoshootCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: offering.featured
            ? Border.all(color: const Color(0xFF6B5CFF), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: (offering.featured ? _accentColor : Colors.black)
                .withValues(alpha: offering.featured ? 0.1 : 0.05),
            blurRadius: offering.featured ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (offering.featured)
            Container(
              height: layout.featuredBannerHeight,
              alignment: Alignment.center,
              decoration: const BoxDecoration(gradient: _featuredGradient),
              child: Text(
                'Популярно',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: layout.featuredBannerFontSize,
                ),
              ),
            ),
          Padding(
            padding: layout.contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  offering.priceLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: layout.priceFontSize,
                    fontWeight: FontWeight.w800,
                    color: _accentColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: layout.statRowHeight,
                  child: hasPhotoshootLine
                      ? _PackStatRow(
                          label:
                              '${offering.photoshootCount} ${_packPhotoshootLabel(offering.photoshootCount)}',
                          backgroundColor: const Color(0xFFEDE9FF),
                          textColor: _accentColor,
                          fontSize: layout.badgeFontSize,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: layout.statRowHeight,
                  child: _PackStatRow(
                    label:
                        '${offering.imageCount} ${_packImageLabel(offering.imageCount)}',
                    backgroundColor: const Color(0xFFF0F2FF),
                    textColor: AiImageGeneratorApp.textPrimary,
                    fontSize: layout.badgeFontSize,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  offering.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: layout.subtitleFontSize,
                    height: 1.25,
                    color: AiImageGeneratorApp.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _PackPaymentButton(
                  featured: offering.featured,
                  height: layout.buttonHeight,
                  fontSize: layout.buttonFontSize,
                  onPressed: onPaymentSoon,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackPaymentButton extends StatelessWidget {
  const _PackPaymentButton({
    required this.featured,
    required this.height,
    required this.fontSize,
    required this.onPressed,
  });

  final bool featured;
  final double height;
  final double fontSize;
  final VoidCallback onPressed;

  static const _accentColor = Color(0xFF5B6CFF);
  static const _featuredGradient = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
  );

  @override
  Widget build(BuildContext context) {
    if (featured) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _featuredGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(10),
              child: Center(
                child: Text(
                  'Выбрать пакет',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: BorderSide(
            color: _accentColor.withValues(alpha: 0.45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Выбрать пакет',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

class _PackStatRow extends StatelessWidget {
  const _PackStatRow({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.fontSize,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _CustomAmountSection extends StatelessWidget {
  const _CustomAmountSection({
    required this.amountController,
    required this.amountError,
    required this.isAmountValid,
    required this.validAmount,
    required this.photoshootCount,
    required this.maxPhotoshoots,
    required this.imageCount,
    required this.onAmountChanged,
    required this.onPhotoshootCountChanged,
    required this.onPhotoshootsDecrease,
    required this.onPhotoshootsIncrease,
    required this.onPaymentPressed,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final TextEditingController amountController;
  final String? amountError;
  final bool isAmountValid;
  final int? validAmount;
  final int photoshootCount;
  final int maxPhotoshoots;
  final int imageCount;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<int> onPhotoshootCountChanged;
  final VoidCallback? onPhotoshootsDecrease;
  final VoidCallback? onPhotoshootsIncrease;
  final VoidCallback onPaymentPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Правила распределения',
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Минимум 10 ₽ · 1 изображение = 10 ₽ · 1 фотосессия = 100 ₽',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              height: 1.35,
              color: AiImageGeneratorApp.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Сумма, ₽',
              hintText: 'От 10 до 100 000',
              errorText: amountError,
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: amountError != null
                      ? theme.colorScheme.error
                      : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: amountError != null
                      ? theme.colorScheme.error
                      : _accentColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.colorScheme.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: onAmountChanged,
          ),
          const SizedBox(height: 20),
          Text(
            'Сколько фотосессий включить',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 15,
              color: isAmountValid
                  ? null
                  : AiImageGeneratorApp.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Остаток суммы после фотосессий идёт на изображения.',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onPhotoshootsDecrease,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Text(
                  '$photoshootCount',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onPhotoshootsIncrease,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (isAmountValid && maxPhotoshoots > 0)
            Slider(
              value: photoshootCount.toDouble(),
              min: 0,
              max: maxPhotoshoots.toDouble(),
              divisions: maxPhotoshoots,
              label: '$photoshootCount',
              onChanged: (value) =>
                  onPhotoshootCountChanged(value.round()),
            ),
          const SizedBox(height: 16),
          if (isAmountValid && validAmount != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'К оплате: $validAmount ₽',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPackReceiveSummary(imageCount, photoshootCount),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: isAmountValid ? onPaymentPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: AiImageGeneratorApp.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Пополнить баланс',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoshootStyle {
  const _PhotoshootStyle({
    required this.id,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.initials,
    required this.icon,
    required this.gradientColors,
    required this.isFree,
    this.previewVariant = 0,
  });

  final String id;
  final String title;
  final String description;
  final String recommendation;
  final String initials;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isFree;
  final int previewVariant;

  String get priceLabel => isFree ? 'Бесплатно' : '100 ₽';
}

class PhotoshootsScreen extends StatefulWidget {
  const PhotoshootsScreen({
    super.key,
    required this.isActive,
    required this.apiService,
    required this.balance,
    required this.balanceLoading,
    required this.onPhotoshootGenerated,
    required this.onBalanceUpdated,
    required this.onOpenGallery,
    required this.onOpenPacks,
  });

  final bool isActive;
  final ApiService apiService;
  final UserBalance? balance;
  final bool balanceLoading;
  final void Function(List<GeneratedImageItem> items) onPhotoshootGenerated;
  final ValueChanged<UserBalance> onBalanceUpdated;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenPacks;

  @override
  State<PhotoshootsScreen> createState() => _PhotoshootsScreenState();
}

class _PhotoshootsScreenState extends State<PhotoshootsScreen> {
  bool _isHelpDialogVisible = false;

  static const _gridBreakpoint = 560.0;

  static const _photoshoots = <_PhotoshootStyle>[
    _PhotoshootStyle(
      id: 'studio_portrait',
      title: 'Студийный портрет',
      description: 'Чистый фон, мягкий свет, универсальный портрет.',
      recommendation: 'Для аватара',
      initials: 'СП',
      icon: Icons.portrait_outlined,
      gradientColors: [Color(0xFFE8E4F4), Color(0xFFB8B0D4)],
      isFree: true,
      previewVariant: 0,
    ),
    _PhotoshootStyle(
      id: 'business_portrait',
      title: 'Деловой портрет',
      description: 'Аккуратный образ для резюме, сайта или профиля.',
      recommendation: 'Для работы',
      initials: 'ДП',
      icon: Icons.business_center_outlined,
      gradientColors: [Color(0xFFD4E0EE), Color(0xFF8EA4BE)],
      isFree: true,
      previewVariant: 1,
    ),
    _PhotoshootStyle(
      id: 'home_portrait',
      title: 'Домашний портрет',
      description: 'Тёплая атмосфера и естественный свет.',
      recommendation: 'Для личного профиля',
      initials: 'ДМ',
      icon: Icons.home_outlined,
      gradientColors: [Color(0xFFF5E8D8), Color(0xFFD4B896)],
      isFree: true,
      previewVariant: 2,
    ),
    _PhotoshootStyle(
      id: 'premium_portrait',
      title: 'Премиум-портрет',
      description: 'Более выразительный свет и дорогой визуальный стиль.',
      recommendation: 'Премиум',
      initials: 'ПР',
      icon: Icons.diamond_outlined,
      gradientColors: [Color(0xFFD8C8F8), Color(0xFF9070D8)],
      isFree: false,
      previewVariant: 3,
    ),
    _PhotoshootStyle(
      id: 'winter_photoshoot',
      title: 'Зимняя фотосессия',
      description: 'Зимняя атмосфера, мягкий свет и уютный образ.',
      recommendation: 'Для сезона',
      initials: 'ЗМ',
      icon: Icons.ac_unit,
      gradientColors: [Color(0xFFD0ECFA), Color(0xFF6CB8E8)],
      isFree: false,
      previewVariant: 1,
    ),
    _PhotoshootStyle(
      id: 'urban_portrait',
      title: 'Городской портрет',
      description: 'Современный городской фон и стильная подача.',
      recommendation: 'Для соцсетей',
      initials: 'ГР',
      icon: Icons.location_city_outlined,
      gradientColors: [Color(0xFFC8D4F8), Color(0xFF6878D0)],
      isFree: false,
      previewVariant: 0,
    ),
    _PhotoshootStyle(
      id: 'evening_look',
      title: 'Вечерний образ',
      description: 'Элегантный свет, вечернее настроение и выразительность.',
      recommendation: 'Для образа',
      initials: 'ВЧ',
      icon: Icons.nightlife_outlined,
      gradientColors: [Color(0xFF7A5898), Color(0xFF3A2868)],
      isFree: false,
      previewVariant: 2,
    ),
    _PhotoshootStyle(
      id: 'travel_portrait',
      title: 'Портрет в путешествии',
      description: 'Атмосфера поездки и красивый фон.',
      recommendation: 'Для истории',
      initials: 'ПТ',
      icon: Icons.flight_outlined,
      gradientColors: [Color(0xFFC0ECE0), Color(0xFF58B8A8)],
      isFree: false,
      previewVariant: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scheduleFirstVisitHelp();
  }

  @override
  void didUpdateWidget(PhotoshootsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleFirstVisitHelp();
    }
  }

  void _scheduleFirstVisitHelp() {
    if (!widget.isActive) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowFirstVisitHelp();
    });
  }

  Future<void> _maybeShowFirstVisitHelp() async {
    if (!mounted || !widget.isActive || _isHelpDialogVisible) return;
    final seen = await PhotoshootsHelpService.isSeen();
    if (!mounted || !widget.isActive || seen) return;
    await _showHelp();
  }

  Future<void> _showHelp() async {
    if (!mounted || _isHelpDialogVisible) return;
    _isHelpDialogVisible = true;
    var dismissed = false;

    Future<void> markSeenOnDismiss() async {
      if (dismissed) return;
      dismissed = true;
      await PhotoshootsHelpService.setSeen();
    }

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => PhotoshootsHelpDialog(
          onDismissed: markSeenOnDismiss,
        ),
      );
      await markSeenOnDismiss();
    } finally {
      _isHelpDialogVisible = false;
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openCustomPhotoshootDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _CustomPhotoshootDialog(
        onShowMessage: (message) => _showSnackBar(context, message),
      ),
    );
  }

  void _showPaidStyleDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Оплата скоро',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Оплата скоро появится. Пока можно протестировать бесплатные стили.',
          style: TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF6B7280)),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5B6CFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  void _onStyleSelected(BuildContext context, _PhotoshootStyle style) {
    if (!style.isFree) {
      _showPaidStyleDialog(context);
      return;
    }
    _openPhotoshootSheet(context, style);
  }

  void _openPhotoshootSheet(BuildContext context, _PhotoshootStyle style) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PhotoshootDetailSheet(
        style: style,
        apiService: widget.apiService,
        balance: widget.balance,
        balanceLoading: widget.balanceLoading,
        onShowMessage: (message) => _showSnackBar(context, message),
        onPhotoshootGenerated: widget.onPhotoshootGenerated,
        onBalanceUpdated: widget.onBalanceUpdated,
        onOpenGallery: widget.onOpenGallery,
        onOpenPacks: widget.onOpenPacks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPhotoshootDepleted = widget.balance != null &&
        !widget.balanceLoading &&
        widget.balance!.showPhotoshootDepletedWarning;

    return Scaffold(
      backgroundColor: AiImageGeneratorApp.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >= _gridBreakpoint ? 2 : 1;
                final previewHeight = columns == 2 ? 168.0 : 152.0;
                final cardWidth =
                    (constraints.maxWidth - (columns - 1) * 16) / columns;
                final cardHeight = columns == 2 ? 390.0 : 410.0;
                final gridAspectRatio = cardWidth / cardHeight;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PhotoshootsIntroHeader(
                        balance: widget.balance,
                        balanceLoading: widget.balanceLoading,
                        showDepletedWarning: showPhotoshootDepleted,
                        onShowHelp: _showHelp,
                        helpEnabled: !_isHelpDialogVisible,
                        onOpenPacks: widget.onOpenPacks,
                      ),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: gridAspectRatio,
                        ),
                        itemCount: _photoshoots.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Align(
                              alignment: Alignment.topCenter,
                              child: _CustomPhotoshootCatalogCard(
                                previewHeight: previewHeight,
                                onAction: () =>
                                    _openCustomPhotoshootDialog(context),
                              ),
                            );
                          }
                          final style = _photoshoots[index - 1];
                          return Align(
                            alignment: Alignment.topCenter,
                            child: _PhotoshootCard(
                              style: style,
                              previewHeight: previewHeight,
                              onAction: () =>
                                  _onStyleSelected(context, style),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoshootsIntroHeader extends StatelessWidget {
  const _PhotoshootsIntroHeader({
    required this.balance,
    required this.balanceLoading,
    required this.showDepletedWarning,
    required this.onShowHelp,
    required this.helpEnabled,
    required this.onOpenPacks,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final UserBalance? balance;
  final bool balanceLoading;
  final bool showDepletedWarning;
  final VoidCallback onShowHelp;
  final bool helpEnabled;
  final VoidCallback onOpenPacks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDemoMode = balance != null && !balance!.consumptionEnabled;
    final photoshootCount = balance?.paidPhotoshoots;

    String balanceLine;
    if (balanceLoading && balance == null) {
      balanceLine = 'Загружаем баланс…';
    } else if (balance == null) {
      balanceLine = 'Баланс фотосессий: —';
    } else if (isDemoMode) {
      balanceLine =
          'Баланс фотосессий: ${photoshootCount ?? 0} · демо-режим';
    } else {
      balanceLine = 'Баланс фотосессий: ${photoshootCount ?? 0}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Фотосессии',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SectionHelpButton(
              onPressed: onShowHelp,
              enabled: helpEnabled,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Выберите стиль, загрузите фото — приложение создаст '
          'готовые изображения в выбранном образе.',
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: AiImageGeneratorApp.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAEF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.collections_outlined,
                    size: 18,
                    color: _accentColor.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '1 фотосессия = до 3 изображений',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (balanceLoading && balance == null)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 18,
                      color: AiImageGeneratorApp.textSecondary,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      balanceLine,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AiImageGeneratorApp.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDepletedWarning) ...[
          const SizedBox(height: 12),
          InsufficientBalanceHint(
            message:
                'Фотосессии закончились. Пополните баланс, чтобы продолжить.',
            onOpenPacks: onOpenPacks,
          ),
        ],
      ],
    );
  }
}

class _CustomPhotoshootCatalogCard extends StatelessWidget {
  const _CustomPhotoshootCatalogCard({
    required this.previewHeight,
    required this.onAction,
  });

  final double previewHeight;
  final VoidCallback onAction;

  static const _accentColor = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: previewHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFEEF1FF),
                    _accentColor.withValues(alpha: 0.18),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -8,
                    bottom: -12,
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      size: 56,
                      color: _accentColor.withValues(alpha: 0.12),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_note_outlined,
                        size: 24,
                        color: _accentColor,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Свой образ',
                        style: TextStyle(
                          color: AiImageGeneratorApp.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Своя фотосессия',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Опишите образ своими словами',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.3,
                    color: AiImageGeneratorApp.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    _PhotoshootMetaChip(
                      label: 'до 3 фото',
                      backgroundColor: Color(0xFFF0F2FF),
                      textColor: _accentColor,
                    ),
                    _PhotoshootMetaChip(
                      label: 'Скоро',
                      backgroundColor: Color(0xFFFFF3E0),
                      textColor: Color(0xFFE65100),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton(
                    onPressed: onAction,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accentColor,
                      side: BorderSide(
                        color: _accentColor.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Открыть',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomPhotoshootDialog extends StatefulWidget {
  const _CustomPhotoshootDialog({required this.onShowMessage});

  final void Function(String message) onShowMessage;

  @override
  State<_CustomPhotoshootDialog> createState() => _CustomPhotoshootDialogState();
}

class _CustomPhotoshootDialogState extends State<_CustomPhotoshootDialog> {
  static const _accentColor = Color(0xFF5B6CFF);
  final _imagePicker = ImagePicker();
  final _wishesController = TextEditingController();

  Uint8List? _selectedPhotoBytes;
  bool _isPickingPhoto = false;

  static const _descriptionTips = [
    'Где проходит съёмка: офис, улица, студия, природа',
    'Какой образ: деловой, спокойный, праздничный, уверенный',
    'Какая одежда: костюм, платье, casual',
    'Какой фон и настроение',
    'Чем понятнее описание, тем лучше результат',
  ];

  @override
  void dispose() {
    _wishesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _selectedPhotoBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      widget.onShowMessage('Не удалось выбрать фото. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  void _clearPhoto() {
    setState(() => _selectedPhotoBytes = null);
  }

  void _onCreateLater() {
    widget.onShowMessage('Своя фотосессия будет добавлена позже');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = _selectedPhotoBytes != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Своя фотосессия',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 22),
                    tooltip: 'Закрыть',
                    color: AiImageGeneratorApp.textSecondary,
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Загрузите фото и опишите, какой образ хотите получить.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!hasPhoto)
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _isPickingPhoto ? null : _pickPhoto,
                            icon: _isPickingPhoto
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 20,
                                  ),
                            label: Text(
                              _isPickingPhoto ? 'Подождите...' : 'Добавить фото',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accentColor,
                              side: BorderSide(
                                color: _accentColor.withValues(alpha: 0.45),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                      else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Image.memory(
                                _selectedPhotoBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _clearPhoto,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Убрать фото'),
                            style: TextButton.styleFrom(
                              foregroundColor: AiImageGeneratorApp.textSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _wishesController,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Ваши пожелания',
                          hintText:
                              'Например: деловая фотосессия в светлом офисе, '
                              'уверенный образ, спокойный фон',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: const Color(0xFFF7F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _accentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SoftCard(
                        backgroundColor: const Color(0xFFF3F6FF),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Как описать лучше',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._descriptionTips.map(
                              (tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.check_circle_outline,
                                        size: 17,
                                        color: _accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontSize: 14,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Когда функция будет подключена, создание может занять до минуты.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.35,
                  color: AiImageGeneratorApp.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AiImageGeneratorApp.textSecondary,
                        side: BorderSide(color: Colors.grey.shade300),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Закрыть',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _onCreateLater,
                            borderRadius: BorderRadius.circular(14),
                            child: const Center(
                              child: Text(
                                'Создать позже',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoshootCard extends StatelessWidget {
  const _PhotoshootCard({
    required this.style,
    required this.previewHeight,
    required this.onAction,
  });

  final _PhotoshootStyle style;
  final double previewHeight;
  final VoidCallback onAction;

  static const _accentColor = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceBg =
        style.isFree ? const Color(0xFFE8F5E9) : const Color(0xFFEDE9FF);
    final priceFg =
        style.isFree ? const Color(0xFF2E7D32) : _accentColor;
    final onDarkPreview = style.gradientColors.first.computeLuminance() < 0.45;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: style.isFree
                ? Border.all(color: const Color(0xFFE8EAEF))
                : Border.all(
                    color: _accentColor.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
            boxShadow: [
              BoxShadow(
                color: style.isFree
                    ? Colors.black.withValues(alpha: 0.05)
                    : _accentColor.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!style.isFree)
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accentColor.withValues(alpha: 0.6),
                        const Color(0xFF7C5CFF).withValues(alpha: 0.35),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              _PhotoshootPreview(
                initials: style.initials,
                icon: style.icon,
                gradientColors: style.gradientColors,
                onDark: onDarkPreview,
                isFree: style.isFree,
                previewVariant: style.previewVariant,
                showCatalogBadges: true,
                recommendation: style.recommendation,
                fixedHeight: previewHeight,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      style.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.3,
                        color: AiImageGeneratorApp.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _PhotoshootMetaChip(
                          label: style.priceLabel,
                          backgroundColor: priceBg,
                          textColor: priceFg,
                        ),
                        const _PhotoshootMetaChip(
                          label: 'до 3 фото',
                          backgroundColor: Color(0xFFF0F2FF),
                          textColor: _accentColor,
                        ),
                        _PhotoshootMetaChip(
                          label: style.recommendation,
                          backgroundColor: const Color(0xFFF7F8FC),
                          textColor: AiImageGeneratorApp.textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: style.isFree
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C5CFF),
                                    Color(0xFF4A7CFF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Выбрать стиль',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : OutlinedButton(
                              onPressed: onAction,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _accentColor,
                                side: BorderSide(
                                  color: _accentColor.withValues(alpha: 0.4),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Скоро · 100 ₽',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoshootMetaChip extends StatelessWidget {
  const _PhotoshootMetaChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PhotoshootDetailSheet extends StatefulWidget {
  const _PhotoshootDetailSheet({
    required this.style,
    required this.apiService,
    required this.balance,
    required this.balanceLoading,
    required this.onShowMessage,
    required this.onPhotoshootGenerated,
    required this.onBalanceUpdated,
    required this.onOpenGallery,
    required this.onOpenPacks,
  });

  final _PhotoshootStyle style;
  final ApiService apiService;
  final UserBalance? balance;
  final bool balanceLoading;
  final void Function(String message) onShowMessage;
  final void Function(List<GeneratedImageItem> items) onPhotoshootGenerated;
  final ValueChanged<UserBalance> onBalanceUpdated;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenPacks;

  @override
  State<_PhotoshootDetailSheet> createState() => _PhotoshootDetailSheetState();
}

class _PhotoshootDetailSheetState extends State<_PhotoshootDetailSheet> {
  static const _accentColor = Color(0xFF5B6CFF);
  final _imagePicker = ImagePicker();
  XFile? _selectedPhotoFile;
  Uint8List? _selectedPhotoBytes;
  bool _isPickingPhoto = false;
  bool _isPreparingPhotoshoot = false;
  bool _usingMockPhoto = false;

  @override
  void initState() {
    super.initState();
    if (MockPhotoshootPhoto.shouldAutoUseOnPlatform) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyMockPhoto();
      });
    }
  }

  void _applyMockPhoto() {
    setState(() {
      _selectedPhotoFile = MockPhotoshootPhoto.asXFile();
      _selectedPhotoBytes = MockPhotoshootPhoto.bytes;
      _usingMockPhoto = true;
    });
  }

  static const _outcomes = [
    'до 3 готовых изображений',
    'единый стиль',
    'результат появится в Галерее',
  ];

  void _clearPhoto() {
    setState(() {
      _selectedPhotoFile = null;
      _selectedPhotoBytes = null;
      _usingMockPhoto = false;
    });
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedPhotoFile = file;
        _selectedPhotoBytes = bytes;
        _usingMockPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Не удалось выбрать фото. Попробуйте ещё раз.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  bool get _photoshootsBalanceDepleted {
    final balance = widget.balance;
    return balance != null &&
        !widget.balanceLoading &&
        !balance.isPhotoshootBalanceAvailable;
  }

  Future<void> _onSecondaryActionPressed() async {
    if (_isPreparingPhotoshoot) return;
    final selectedPhotoFile = _selectedPhotoFile;
    final hasSelectedPhoto = selectedPhotoFile != null;
    if (!hasSelectedPhoto) {
      widget.onShowMessage('Сначала добавьте фото.');
      return;
    }
    if (!widget.style.isFree) {
      widget.onShowMessage(
        'Оплата скоро появится. Пока можно протестировать бесплатные стили.',
      );
      return;
    }
    if (_photoshootsBalanceDepleted) {
      await InsufficientBalanceDialog.showInsufficientPhotoshoots(
        context,
        onOpenPacks: widget.onOpenPacks,
      );
      return;
    }
    setState(() => _isPreparingPhotoshoot = true);
    try {
      final result = await GenerationProgressDialog.run<PhotoshootGenerateResponse>(
        context: context,
        title: 'Создаём фотосессию…',
        subtitle: 'Обычно это занимает около 1–2 минут.',
        totalSeconds: 120,
        task: () => widget.apiService.generatePhotoshoot(
          styleId: widget.style.id,
          styleTitle: widget.style.title,
          photoFile: selectedPhotoFile,
        ),
      );
      if (!mounted) return;
      if (result.imageUrls.isEmpty) {
        widget.onShowMessage(
          'Не удалось подготовить фотосессию. Попробуйте позже.',
        );
        return;
      }
      final updatedBalance = result.balance;
      if (updatedBalance != null) {
        widget.onBalanceUpdated(updatedBalance);
      }
      final description = 'Фотосессия: ${result.styleTitle}';
      final createdAt = DateTime.now();
      final galleryItems = result.imageUrls
          .map(
            (url) => GeneratedImageItem(
              description: description,
              imageUrl: url,
              createdAt: createdAt,
            ),
          )
          .toList();
      Navigator.of(context).pop();
      widget.onPhotoshootGenerated(galleryItems);
      widget.onShowMessage('Фотосессия готова');
      widget.onOpenGallery();
    } on PhotoshootPlaceholderException {
      if (!mounted) return;
      widget.onShowMessage('Обработка фото будет добавлена позже');
    } on PhotoshootInvalidPhotoException {
      if (!mounted) return;
      widget.onShowMessage('Выберите фото JPEG, PNG или WebP до 10 МБ');
    } on InsufficientPhotoshootsException {
      if (!mounted) return;
      await InsufficientBalanceDialog.showInsufficientPhotoshoots(
        context,
        onOpenPacks: widget.onOpenPacks,
      );
    } catch (_) {
      if (!mounted) return;
      widget.onShowMessage('Не удалось подготовить фотосессию. Попробуйте позже.');
    } finally {
      if (mounted) setState(() => _isPreparingPhotoshoot = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style;
    final badgeColor =
        style.isFree ? const Color(0xFFE8F5E9) : const Color(0xFFEDE9FF);
    final badgeTextColor =
        style.isFree ? const Color(0xFF2E7D32) : _accentColor;
    final hasPhoto = _selectedPhotoBytes != null;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          maxWidth: 520,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              style.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              style.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                                color: AiImageGeneratorApp.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              style.priceLabel,
                              style: TextStyle(
                                color: badgeTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _PhotoshootMetaChip(
                            label: style.recommendation,
                            backgroundColor: const Color(0xFFF7F8FC),
                            textColor: AiImageGeneratorApp.textPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Что получится',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ..._outcomes.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                    color: _accentColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Добавьте фото',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Лучше выбрать фото, где лицо хорошо видно, '
                    'без сильной тени и размытия.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: AiImageGeneratorApp.textSecondary,
                    ),
                  ),
                  if (_usingMockPhoto) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'Для проверки на эмуляторе используется тестовое фото.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (!hasPhoto)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isPickingPhoto ? null : _pickPhoto,
                        icon: _isPickingPhoto
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          _isPickingPhoto ? 'Подождите...' : 'Добавить фото',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentColor,
                          side: BorderSide(
                            color: _accentColor.withValues(alpha: 0.45),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.memory(
                          _selectedPhotoBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _isPickingPhoto ? null : _clearPhoto,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Убрать фото'),
                        style: TextButton.styleFrom(
                          foregroundColor: AiImageGeneratorApp.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isPreparingPhotoshoot
                              ? null
                              : _onSecondaryActionPressed,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _isPreparingPhotoshoot
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Создать фотосессию',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoshootPreview extends StatelessWidget {
  const _PhotoshootPreview({
    required this.initials,
    required this.icon,
    required this.gradientColors,
    required this.onDark,
    required this.isFree,
    this.previewVariant = 0,
    this.showCatalogBadges = false,
    this.recommendation,
    this.fixedHeight,
  });

  final String initials;
  final IconData icon;
  final List<Color> gradientColors;
  final bool onDark;
  final bool isFree;
  final int previewVariant;
  final bool showCatalogBadges;
  final String? recommendation;
  final double? fixedHeight;

  @override
  Widget build(BuildContext context) {
    final iconColor = onDark ? Colors.white.withValues(alpha: 0.9) : Colors.white;
    final initialsBg = onDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.35);
    final compact = fixedHeight != null;
    final bgIconSize = compact ? 72.0 : 88.0;
    final centerIconSize = compact ? 46.0 : 56.0;
    final centerGlyphSize = compact ? 24.0 : 28.0;

    final preview = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ..._buildVariantDecorations(onDark),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: onDark ? 0.06 : 0.18),
                    Colors.transparent,
                    Colors.black.withValues(alpha: onDark ? 0.12 : 0.04),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -12,
            bottom: -16,
            child: Icon(
              icon,
              size: bgIconSize,
              color: (onDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.1),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: centerIconSize,
                  height: centerIconSize,
                  decoration: BoxDecoration(
                    color: initialsBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(icon, size: centerGlyphSize, color: iconColor),
                  ),
                ),
              ],
            ),
          ),
          if (showCatalogBadges && recommendation != null)
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: onDark ? 0.92 : 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recommendation!,
                  style: TextStyle(
                    color: AiImageGeneratorApp.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (showCatalogBadges)
            Positioned(
              right: 10,
              top: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isFree)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: onDark
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF5B6CFF),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '3 фото',
                      style: TextStyle(
                        color: AiImageGeneratorApp.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    if (fixedHeight != null) {
      return SizedBox(height: fixedHeight, child: preview);
    }

    return AspectRatio(aspectRatio: 16 / 9, child: preview);
  }

  List<Widget> _buildVariantDecorations(bool onDark) {
    final accent = onDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.28);

    switch (previewVariant % 4) {
      case 1:
        return [
          Positioned(
            left: -24,
            top: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 18,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 2),
              ),
            ),
          ),
        ];
      case 2:
        return [
          Positioned.fill(
            child: CustomPaint(
              painter: _DiagonalStripePainter(
                color: accent.withValues(alpha: 0.65),
              ),
            ),
          ),
        ];
      case 3:
        return [
          Positioned(
            left: 12,
            top: 12,
            right: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent, width: 1.5),
              ),
            ),
          ),
        ];
      default:
        return [];
    }
  }
}

class _DiagonalStripePainter extends CustomPainter {
  _DiagonalStripePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const stripeWidth = 18.0;
    const gap = 28.0;
    var x = -size.height;

    while (x < size.width + size.height) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + stripeWidth, size.height)
        ..lineTo(x + stripeWidth + size.height, 0)
        ..lineTo(x + size.height, 0)
        ..close();
      canvas.drawPath(path, paint);
      x += stripeWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

String _formatGalleryTimestamp(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final hours = dateTime.hour.toString().padLeft(2, '0');
  final minutes = dateTime.minute.toString().padLeft(2, '0');
  final time = '$hours:$minutes';

  if (day == today) {
    return 'Сегодня, $time';
  }
  final yesterday = today.subtract(const Duration(days: 1));
  if (day == yesterday) {
    return 'Вчера, $time';
  }
  return time;
}

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({
    super.key,
    required this.images,
    required this.onCreateFirst,
    required this.onClearGallery,
    this.backendHistoryUnavailable = false,
  });

  final List<GeneratedImageItem> images;
  final VoidCallback onCreateFirst;
  final VoidCallback onClearGallery;
  final bool backendHistoryUnavailable;

  void _onClearPressed(BuildContext context) {
    onClearGallery();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Галерея очищена на этом устройстве'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static const _breakpointMedium = 560.0;
  static const _breakpointWide = 900.0;

  static int _columnCount(double width) {
    if (width >= _breakpointWide) return 3;
    if (width >= _breakpointMedium) return 2;
    return 1;
  }

  static double _aspectRatio(int columns) {
    switch (columns) {
      case 3:
        return 0.62;
      case 2:
        return 0.72;
      default:
        return 0.88;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = groupGalleryItems(images);

    if (displayItems.isEmpty) {
      return _GalleryEmptyState(
        onCreateFirst: onCreateFirst,
        backendHistoryUnavailable: backendHistoryUnavailable,
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AiImageGeneratorApp.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _columnCount(constraints.maxWidth);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Галерея',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ваши созданные изображения',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _onClearPressed(context),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                            ),
                            label: const Text(
                              'Очистить',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  AiImageGeneratorApp.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: _aspectRatio(columns),
                        ),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          return _GalleryImageCard(item: displayItems[index]);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryEmptyState extends StatelessWidget {
  const _GalleryEmptyState({
    required this.onCreateFirst,
    this.backendHistoryUnavailable = false,
  });

  final VoidCallback onCreateFirst;
  final bool backendHistoryUnavailable;

  static const _accentColor = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AiImageGeneratorApp.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Галерея', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    'Здесь будут ваши созданные изображения',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  _SoftCard(
                    child: Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFEDE9FF),
                                _accentColor.withValues(alpha: 0.25),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            size: 48,
                            color: _accentColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Пока нет изображений',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Создайте первое изображение или фотосессию, чтобы увидеть результат здесь.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7C5CFF),
                                  Color(0xFF4A7CFF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentColor.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onCreateFirst,
                                borderRadius: BorderRadius.circular(14),
                                child: const Center(
                                  child: Text(
                                    'Создать первое изображение',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (backendHistoryUnavailable) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Не удалось загрузить историю с сервера. Создайте новое изображение — оно появится здесь.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _SoftCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.schedule_outlined,
                            color: _accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Скоро',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'После добавления аккаунта здесь появится полная история ваших изображений и фотосессий.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryImageCard extends StatelessWidget {
  const _GalleryImageCard({required this.item});

  final GalleryDisplayItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageCountLabel = galleryImageCountLabel(item.imageUrls.length);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _GalleryImagePreview(imageUrls: item.imageUrls),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Создано по описанию:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AiImageGeneratorApp.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AiImageGeneratorApp.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (imageCountLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    imageCountLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: AiImageGeneratorApp.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatGalleryTimestamp(item.createdAt),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryImagePreview extends StatelessWidget {
  const _GalleryImagePreview({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.length == 1) {
      return _GalleryNetworkImage(url: imageUrls.first);
    }
    if (imageUrls.length == 2) {
      return Row(
        children: [
          Expanded(child: _GalleryNetworkImage(url: imageUrls[0])),
          const SizedBox(width: 2),
          Expanded(child: _GalleryNetworkImage(url: imageUrls[1])),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _GalleryNetworkImage(url: imageUrls.first),
        ),
        const SizedBox(height: 2),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(child: _GalleryNetworkImage(url: imageUrls[1])),
              const SizedBox(width: 2),
              Expanded(
                child: imageUrls.length >= 3
                    ? _GalleryNetworkImage(url: imageUrls[2])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GalleryNetworkImage extends StatelessWidget {
  const _GalleryNetworkImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFF0F2F8),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          const _GenerationResultPreviewFallback(compact: true),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
    required this.apiService,
    required this.onAuthChanged,
    required this.balance,
    required this.balanceLoading,
    required this.balanceLoadFailed,
    required this.onRefreshBalance,
    this.onResetOnboarding,
  });

  final AuthService authService;
  final ApiService apiService;
  final VoidCallback onAuthChanged;
  final UserBalance? balance;
  final bool balanceLoading;
  final bool balanceLoadFailed;
  final VoidCallback onRefreshBalance;
  final VoidCallback? onResetOnboarding;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _accentColor = Color(0xFF5B6CFF);

  static const _comingFeatures = [
    (icon: Icons.image_outlined, label: 'Ваши созданные изображения'),
    (icon: Icons.photo_camera_outlined, label: 'История фотосессий'),
    (icon: Icons.shopping_bag_outlined, label: 'Купленные пакеты генераций'),
    (icon: Icons.settings_outlined, label: 'Настройки приложения'),
  ];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthAction _authAction = _AuthAction.none;

  bool get _isAuthLoading => _authAction != _AuthAction.none;
  bool get _isSigningIn => _authAction == _AuthAction.signIn;
  bool get _isSigningUp => _authAction == _AuthAction.signUp;
  bool get _isSigningOut => _authAction == _AuthAction.signOut;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _applySessionToApi() {
    widget.apiService.setAccessToken(widget.authService.accessToken);
    widget.onAuthChanged();
    if (mounted) setState(() {});
  }

  Future<void> _onSignIn() async {
    if (_isAuthLoading) return;
    setState(() => _authAction = _AuthAction.signIn);
    try {
      await widget.authService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      _applySessionToApi();
      _showSnackBar('Вы вошли в аккаунт');
    } on AuthNotConfiguredException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Не удалось выполнить вход. Проверьте email и пароль.');
    } finally {
      if (mounted) setState(() => _authAction = _AuthAction.none);
    }
  }

  Future<void> _onSignUp() async {
    if (_isAuthLoading) return;
    setState(() => _authAction = _AuthAction.signUp);
    try {
      await widget.authService.signUpWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      _applySessionToApi();
      _showSnackBar('Аккаунт создан');
    } on AuthNotConfiguredException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Не удалось зарегистрироваться. Проверьте email и пароль.');
    } finally {
      if (mounted) setState(() => _authAction = _AuthAction.none);
    }
  }

  Future<void> _onSignOut() async {
    if (_isAuthLoading) return;
    setState(() => _authAction = _AuthAction.signOut);
    try {
      await widget.authService.signOut();
      widget.apiService.setAccessToken(null);
      widget.onAuthChanged();
      if (!mounted) return;
      _showSnackBar('Вы вышли из аккаунта');
      setState(() {});
    } on AuthNotConfiguredException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Не удалось выйти. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _authAction = _AuthAction.none);
    }
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Профиль', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          widget.authService.isConfigured
              ? (widget.authService.isSignedIn
                  ? 'Ваш аккаунт'
                  : 'Войдите, чтобы сохранять историю')
              : 'Аккаунт и настройки',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildNotConfiguredCard(ThemeData theme) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вход недоступен в этом запуске',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Запустите приложение с Supabase config, чтобы включить авторизацию.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Без входа генерация и галерея работают в режиме разработки.',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm(ThemeData theme) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Вход в аккаунт', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Сохраняйте изображения, фотосессии и покупки в своём профиле',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            enabled: !_isAuthLoading,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Email',
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            enabled: !_isAuthLoading,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Пароль',
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _isAuthLoading
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
                      ),
                color: _isAuthLoading ? Colors.grey.shade300 : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isAuthLoading ? null : _onSignIn,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: _isSigningIn
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Войти',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _isAuthLoading ? null : _onSignUp,
              style: OutlinedButton.styleFrom(
                foregroundColor: _accentColor,
                side: BorderSide(color: _accentColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSigningUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Text(
                      'Зарегистрироваться',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInCard(ThemeData theme) {
    final email = widget.authService.currentUser?.email ?? '—';

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Вы вошли', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AiImageGeneratorApp.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Теперь приложение может сохранять ваши изображения и историю в аккаунте.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isAuthLoading ? null : _onSignOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: _accentColor,
                side: BorderSide(color: _accentColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSigningOut
                  ? const Text(
                      'Выходим...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    )
                  : const Text(
                      'Выйти',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = widget.authService;

    return Scaffold(
      backgroundColor: AiImageGeneratorApp.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 20),
                  _UserBalanceProfileCard(
                    balance: widget.balance,
                    isLoading: widget.balanceLoading,
                    hasError: widget.balanceLoadFailed,
                    onRefresh: widget.onRefreshBalance,
                  ),
                  const SizedBox(height: 24),
                  if (!auth.isConfigured) ...[
                    _buildNotConfiguredCard(theme),
                    const SizedBox(height: 20),
                    _SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Что появится здесь',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          ..._comingFeatures.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ProfileListRow(
                                icon: item.icon,
                                label: item.label,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (auth.isSignedIn) ...[
                    _buildSignedInCard(theme),
                  ] else ...[
                    _buildSignInForm(theme),
                  ],
                  if (auth.isConfigured) ...[
                    const SizedBox(height: 20),
                    _SoftCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: _accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Безопасность',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Платежные данные не хранятся в приложении. Важные операции выполняются на сервере.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!auth.isConfigured) ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => _showSnackBar(
                          'Документы будут добавлены перед релизом',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentColor,
                          side: BorderSide(
                            color: _accentColor.withValues(alpha: 0.45),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Политика конфиденциальности',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                  if (kDebugMode && widget.onResetOnboarding != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: widget.onResetOnboarding,
                        child: const Text(
                          'Показать обучалку снова',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _AuthAction {
  none,
  signIn,
  signUp,
  signOut,
}

class _ProfileListRow extends StatelessWidget {
  const _ProfileListRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  static const _accentColor = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: _accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AiImageGeneratorApp.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class CreateScreen extends StatefulWidget {
  const CreateScreen({
    super.key,
    required this.isActive,
    required this.apiService,
    required this.balance,
    required this.balanceLoading,
    required this.onImageGenerated,
    required this.onBalanceUpdated,
    required this.onOpenGallery,
    required this.onOpenPacks,
  });

  final bool isActive;
  final ApiService apiService;
  final UserBalance? balance;
  final bool balanceLoading;
  final ValueChanged<GeneratedImageItem> onImageGenerated;
  final ValueChanged<UserBalance> onBalanceUpdated;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenPacks;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateIdeaCategory {
  const _CreateIdeaCategory({
    required this.title,
    required this.ideas,
  });

  final String title;
  final List<String> ideas;
}

/// Готовые идеи для вкладки «Создать» по режимам и категориям.
class _CreateQuickIdeasCatalog {
  _CreateQuickIdeasCatalog._();

  static const withoutPhotoCategories = [
    _CreateIdeaCategory(
      title: 'Природа',
      ideas: [
        'Уютный домик в зимнем лесу, вечер, тёплый свет из окон',
        'Горное озеро на рассвете, туман, реализм',
        'Цветочное поле летом, мягкий солнечный свет',
      ],
    ),
    _CreateIdeaCategory(
      title: 'Город',
      ideas: [
        'Современный город ночью, неоновые вывески, кинематографичный стиль',
        'Уютная улица старого города после дождя',
        'Панорама большого города на закате',
      ],
    ),
    _CreateIdeaCategory(
      title: 'Дом и интерьер',
      ideas: [
        'Светлая гостиная в современном стиле, уютный свет',
        'Кухня мечты, светлые тона, аккуратный интерьер',
        'Спальня в спокойных цветах, мягкое освещение',
      ],
    ),
    _CreateIdeaCategory(
      title: 'Праздник',
      ideas: [
        'Праздничная открытка с цветами, нежные цвета, красивый свет',
        'Новогодняя открытка, ёлка, тёплые огни, уют',
        'День рождения, воздушные шары, радостная атмосфера',
      ],
    ),
    _CreateIdeaCategory(
      title: 'Реклама и товар',
      ideas: [
        'Рекламное фото чашки кофе на деревянном столе, мягкий утренний свет',
        'Карточка товара на светлом фоне, минимализм',
        'Красивая упаковка косметики, студийный свет',
      ],
    ),
    _CreateIdeaCategory(
      title: 'Соцсети и аватар',
      ideas: [
        'Аватар для соцсетей, аккуратный портрет, светлый фон',
        'Яркая обложка для поста, современный стиль',
        'Минималистичная картинка для профиля, мягкие цвета',
      ],
    ),
  ];

  static const withPhotoCategories = [
    _CreateIdeaCategory(
      title: 'Если на фото человек',
      ideas: [
        'Сделай деловой портрет в светлой студии, аккуратный костюм, мягкий свет',
        'Создай аватар для соцсетей, светлый фон, естественная улыбка',
        'Сделай зимний портрет на улице, тёплая одежда, красивый снег',
        'Добавь образ для резюме: спокойный фон, уверенный вид, реализм',
        'Сделай красивый портрет в городской прогулке, мягкий вечерний свет',
      ],
    ),
    _CreateIdeaCategory(
      title: 'Если на фото предмет или другое',
      ideas: [
        'Сделай рекламное фото товара на светлом фоне, мягкий свет',
        'Поставь предмет на деревянный стол, уютная атмосфера, реализм',
        'Улучши фото комнаты: больше света, аккуратный интерьер, чистый фон',
        'Сделай красивую карточку товара для магазина, минимализм',
        'Добавь праздничный фон вокруг предмета, красивый свет',
      ],
    ),
  ];
}

enum _CreateTipsMode { withoutPhoto, withPhoto }

class _CreateModeToggle extends StatelessWidget {
  const _CreateModeToggle({
    required this.mode,
    required this.onModeChanged,
    this.enabled = true,
  });

  final _CreateTipsMode mode;
  final ValueChanged<_CreateTipsMode> onModeChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SegmentedButton<_CreateTipsMode>(
      segments: const [
        ButtonSegment(
          value: _CreateTipsMode.withoutPhoto,
          label: Text('Без фото'),
        ),
        ButtonSegment(
          value: _CreateTipsMode.withPhoto,
          label: Text('С фото'),
        ),
      ],
      selected: {mode},
      onSelectionChanged: enabled
          ? (selection) => onModeChanged(selection.first)
          : null,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.labelLarge?.copyWith(fontSize: 13),
        ),
      ),
    );
  }
}

class _CreateQuickIdeasPanel extends StatelessWidget {
  const _CreateQuickIdeasPanel({
    required this.mode,
    required this.onModeChanged,
    required this.isBusy,
    required this.onIdeaSelected,
  });

  final _CreateTipsMode mode;
  final ValueChanged<_CreateTipsMode> onModeChanged;
  final bool isBusy;
  final ValueChanged<String> onIdeaSelected;

  List<_CreateIdeaCategory> get _categories =>
      mode == _CreateTipsMode.withoutPhoto
          ? _CreateQuickIdeasCatalog.withoutPhotoCategories
          : _CreateQuickIdeasCatalog.withPhotoCategories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Попробуйте идею', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Выберите режим и категорию — текст подставится в описание',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: AiImageGeneratorApp.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        _CreateModeToggle(
          mode: mode,
          onModeChanged: onModeChanged,
          enabled: !isBusy,
        ),
        const SizedBox(height: 10),
        _SoftCard(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Column(
              key: ValueKey(mode),
              children: [
                for (var i = 0; i < _categories.length; i++)
                  _CreateIdeaCategoryTile(
                    category: _categories[i],
                    initiallyExpanded: i == 0,
                    isBusy: isBusy,
                    onIdeaSelected: onIdeaSelected,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateIdeaCategoryTile extends StatelessWidget {
  const _CreateIdeaCategoryTile({
    required this.category,
    required this.initiallyExpanded,
    required this.isBusy,
    required this.onIdeaSelected,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final _CreateIdeaCategory category;
  final bool initiallyExpanded;
  final bool isBusy;
  final ValueChanged<String> onIdeaSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
        title: Text(
          category.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        iconColor: _accentColor,
        collapsedIconColor: AiImageGeneratorApp.textSecondary,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: category.ideas
                .map(
                  (idea) => ActionChip(
                    label: Text(
                      idea,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                    onPressed:
                        isBusy ? null : () => onIdeaSelected(idea),
                    backgroundColor: const Color(0xFFF7F8FC),
                    side: const BorderSide(color: Color(0xFFE8EAEF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CreateScreenState extends State<CreateScreen> {

  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _showGenerationErrorState = false;
  bool _isHelpDialogVisible = false;
  bool _isPickingPhoto = false;
  _CreateTipsMode _createMode = _CreateTipsMode.withoutPhoto;
  Uint8List? _selectedPhotoBytes;
  XFile? _selectedPhotoFile;
  GenerateImageResponse? _lastResponse;

  bool get _isPhotoMode => _createMode == _CreateTipsMode.withPhoto;

  bool get _hasSelectedPhoto => _selectedPhotoBytes != null;

  void _onCreateModeChanged(_CreateTipsMode mode) {
    setState(() => _createMode = mode);
  }

  @override
  void initState() {
    super.initState();
    _scheduleFirstVisitHelp();
  }

  @override
  void didUpdateWidget(CreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleFirstVisitHelp();
    }
  }

  void _scheduleFirstVisitHelp() {
    if (!widget.isActive) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowFirstVisitHelp();
    });
  }

  Future<void> _maybeShowFirstVisitHelp() async {
    if (!mounted || !widget.isActive || _isHelpDialogVisible) return;
    final seen = await CreateHelpService.isSeen();
    if (!mounted || !widget.isActive || seen) return;
    await _showHelp();
  }

  Future<void> _showHelp() async {
    if (!mounted || _isHelpDialogVisible) return;
    _isHelpDialogVisible = true;
    var dismissed = false;

    Future<void> markSeenOnDismiss() async {
      if (dismissed) return;
      dismissed = true;
      await CreateHelpService.setSeen();
    }

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => CreateHelpDialog(
          onDismissed: markSeenOnDismiss,
        ),
      );
      await markSeenOnDismiss();
    } finally {
      _isHelpDialogVisible = false;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickReferencePhoto() async {
    if (_isPickingPhoto || _isLoading) return;
    setState(() => _isPickingPhoto = true);
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedPhotoFile = file;
        _selectedPhotoBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Не удалось выбрать фото. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  void _clearReferencePhoto() {
    setState(() {
      _selectedPhotoBytes = null;
      _selectedPhotoFile = null;
    });
  }

  bool get _imagesBalanceDepleted {
    final balance = widget.balance;
    return balance != null &&
        !widget.balanceLoading &&
        !balance.isImageGenerationAvailable;
  }

  Future<void> _showInsufficientImagesDialog() {
    return InsufficientBalanceDialog.showInsufficientImages(
      context,
      onOpenPacks: widget.onOpenPacks,
    );
  }

  Future<GenerateImageResponse> _runGeneration(String text) {
    if (_isPhotoMode) {
      final photoFile = _selectedPhotoFile;
      if (photoFile == null) {
        throw StateError('Photo required in photo mode');
      }
      return widget.apiService.generateImageWithPhoto(
        description: text,
        photoFile: photoFile,
      );
    }
    return widget.apiService.generateImage(text);
  }

  Future<void> _onGenerate() async {
    final text = _descriptionController.text.trim();

    if (_isPhotoMode) {
      if (!_hasSelectedPhoto) {
        _showSnackBar('Сначала добавьте фото.');
        return;
      }
      if (text.isEmpty) {
        _showSnackBar('Опишите, что нужно сделать с фото.');
        return;
      }
    } else if (text.isEmpty) {
      _showSnackBar('Сначала опишите изображение');
      return;
    }

    if (_imagesBalanceDepleted) {
      await _showInsufficientImagesDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResponse = null;
      _showGenerationErrorState = false;
    });

    try {
      final response = await GenerationProgressDialog.run<GenerateImageResponse>(
        context: context,
        title: _isPhotoMode
            ? 'Создаём изображение по вашему фото…'
            : 'Создаём изображение',
        subtitle: _isPhotoMode
            ? 'Создание по фото обычно занимает до минуты.'
            : 'Обычно это занимает до минуты.',
        totalSeconds: 60,
        task: () => _runGeneration(text),
      );
      if (!mounted) return;
      final updatedBalance = response.balance;
      if (updatedBalance != null) {
        widget.onBalanceUpdated(updatedBalance);
      }
      widget.onImageGenerated(
        GeneratedImageItem(
          description: text,
          imageUrl: response.imageUrl,
          createdAt: DateTime.now(),
        ),
      );
      setState(() {
        _lastResponse = response;
        _isLoading = false;
      });
    } on InsufficientImagesException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _showInsufficientImagesDialog();
    } on PhotoGenerationInvalidPhotoException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Выберите фото JPEG, PNG или WebP до 10 МБ');
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _handleError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _handleError(String message) {
    if (message == 'Prompt cannot be empty') {
      _showSnackBar('Сначала опишите изображение');
    } else {
      setState(() => _showGenerationErrorState = true);
      _showSnackBar('Не удалось создать изображение. Попробуйте ещё раз позже.');
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _applyQuickIdea(String idea) {
    _descriptionController.text = idea;
    _descriptionController.selection = TextSelection.fromPosition(
      TextPosition(offset: idea.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showImagesDepleted = widget.balance != null &&
        !widget.balanceLoading &&
        widget.balance!.showImageDepletedWarning;

    return Scaffold(
      backgroundColor: AiImageGeneratorApp.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Фотогенератор',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Создавайте изображения по вашему описанию',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  SectionHelpButton(
                    onPressed: _showHelp,
                    enabled: !_isHelpDialogVisible,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CreateBalanceInfoCard(
                balance: widget.balance,
                isLoading: widget.balanceLoading,
              ),
              const SizedBox(height: 20),
              _StatusCard(response: _lastResponse),
              const SizedBox(height: 16),
              _CreateModeBanner(
                isPhotoMode: _isPhotoMode,
                hasSelectedPhoto: _hasSelectedPhoto,
                mode: _createMode,
                onModeChanged: _onCreateModeChanged,
                isBusy: _isLoading,
              ),
              const SizedBox(height: 16),
              _InputCard(
                controller: _descriptionController,
                isPhotoMode: _isPhotoMode,
              ),
              if (_isPhotoMode) ...[
                const SizedBox(height: 10),
                _CreatePhotoDescriptionHints(
                  isBusy: _isLoading,
                  onHintSelected: _applyQuickIdea,
                ),
              ],
              if (_isPhotoMode) ...[
                const SizedBox(height: 20),
                _CreateReferencePhotoCard(
                  photoBytes: _selectedPhotoBytes,
                  isPickingPhoto: _isPickingPhoto,
                  isBusy: _isLoading,
                  onPickPhoto: _pickReferencePhoto,
                  onClearPhoto: _clearReferencePhoto,
                ),
              ],
              const SizedBox(height: 24),
              _CreateQuickIdeasPanel(
                mode: _createMode,
                onModeChanged: _onCreateModeChanged,
                isBusy: _isLoading,
                onIdeaSelected: _applyQuickIdea,
              ),
              const SizedBox(height: 20),
              _CreateTipsCard(
                mode: _createMode,
                onModeChanged: _onCreateModeChanged,
                isBusy: _isLoading,
              ),
              const SizedBox(height: 24),
              if (showImagesDepleted) ...[
                InsufficientBalanceHint(
                  message:
                      'Изображения закончились. Пополните баланс, '
                      'чтобы продолжить.',
                  onOpenPacks: widget.onOpenPacks,
                ),
                const SizedBox(height: 12),
              ],
              _GenerateButton(
                isLoading: _isLoading,
                isPhotoMode: _isPhotoMode,
                onPressed: _isLoading ? null : _onGenerate,
              ),
              if (_showGenerationErrorState) ...[
                const SizedBox(height: 20),
                const _GenerationErrorCard(),
              ],
              if (_lastResponse != null) ...[
                const SizedBox(height: 32),
                _ResultSection(
                  response: _lastResponse!,
                  onOpenGallery: widget.onOpenGallery,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserBalanceProfileCard extends StatelessWidget {
  const _UserBalanceProfileCard({
    required this.balance,
    required this.isLoading,
    required this.hasError,
    required this.onRefresh,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final UserBalance? balance;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rowStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      height: 1.45,
      color: AiImageGeneratorApp.textPrimary,
    );

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: _accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Баланс', style: theme.textTheme.titleMedium),
              ),
              if (!isLoading && hasError)
                TextButton(
                  onPressed: onRefresh,
                  child: const Text('Обновить'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (hasError)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Не удалось загрузить баланс',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AiImageGeneratorApp.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRefresh,
                  child: const Text('Обновить'),
                ),
              ],
            )
          else if (balance != null) ...[
            if (!balance!.consumptionEnabled) ...[
              Text(
                'Демо-режим: списание с баланса отключено',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: AiImageGeneratorApp.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              'Бесплатные генерации: ${balance!.freeGenerationsRemaining} '
              'из ${balance!.freeGenerationsLimit}',
              style: rowStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Изображения: ${balance!.paidImageGenerations}',
              style: rowStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Фотосессии: ${balance!.paidPhotoshoots}',
              style: rowStyle,
            ),
          ],
        ],
      ),
    );
  }
}

class _UserBalancePacksBanner extends StatelessWidget {
  const _UserBalancePacksBanner({
    required this.balance,
    required this.isLoading,
    required this.hasError,
    required this.onRefresh,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final UserBalance? balance;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F7FF), Color(0xFFEEF1FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ваш баланс',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isLoading && hasError)
                TextButton(
                  onPressed: onRefresh,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: _accentColor,
                  ),
                  child: const Text('Обновить'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                const SizedBox(height: 10),
                Text(
                  'Загружаем баланс…',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AiImageGeneratorApp.textSecondary,
                  ),
                ),
              ],
            )
          else if (hasError)
            Text(
              'Не удалось загрузить баланс. Попробуйте позже.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.35,
                color: AiImageGeneratorApp.textSecondary,
              ),
            )
          else if (balance != null) ...[
            if (!balance!.consumptionEnabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFE082).withValues(alpha: 0.8),
                    ),
                  ),
                  child: Text(
                    'Демо-режим: списание отключено.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: const Color(0xFF8D6E00),
                    ),
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                final stats = [
                  _PacksBalanceStat(
                    label: 'Изображения',
                    value: '${balance!.paidImageGenerations}',
                  ),
                  _PacksBalanceStat(
                    label: 'Фотосессии',
                    value: '${balance!.paidPhotoshoots}',
                  ),
                  _PacksBalanceStat(
                    label: 'Бесплатные',
                    value:
                        '${balance!.freeGenerationsRemaining} из ${balance!.freeGenerationsLimit}',
                  ),
                ];

                if (compact) {
                  return Column(
                    children: [
                      for (var i = 0; i < stats.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        stats[i],
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var i = 0; i < stats.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: stats[i]),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Баланс используется для генерации изображений и фотосессий.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.35,
                color: AiImageGeneratorApp.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PacksBalanceStat extends StatelessWidget {
  const _PacksBalanceStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: AiImageGeneratorApp.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateBalanceInfoCard extends StatelessWidget {
  const _CreateBalanceInfoCard({
    required this.balance,
    required this.isLoading,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final UserBalance? balance;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDemoMode = balance != null && !balance!.consumptionEnabled;
    final freeRemaining = balance?.freeGenerationsRemaining ?? 0;
    final freeLimit = balance?.freeGenerationsLimit ?? 3;
    final paidImages = balance?.paidImageGenerations ?? 0;

    String title;
    String subtitle;
    if (isLoading && balance == null) {
      title = 'Загружаем баланс…';
      subtitle = 'Скоро покажем доступные генерации.';
    } else if (isDemoMode) {
      title = 'Демо-режим';
      subtitle = 'Создание изображений без списания с баланса.';
    } else if (freeRemaining > 0) {
      title =
          'Бесплатные генерации: $freeRemaining из $freeLimit';
      subtitle = 'Используйте их, чтобы попробовать создание изображений.';
    } else if (paidImages > 0) {
      title = 'Бесплатные генерации закончились';
      subtitle =
          'Используйте изображения из баланса. Доступно: $paidImages.';
    } else {
      title = 'Нет доступных генераций';
      subtitle = 'Пополните баланс, чтобы создавать изображения.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDemoMode
                  ? Icons.science_outlined
                  : Icons.auto_awesome_outlined,
              color: _accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AiImageGeneratorApp.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.35,
                    color: AiImageGeneratorApp.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateModeBanner extends StatelessWidget {
  const _CreateModeBanner({
    required this.isPhotoMode,
    required this.hasSelectedPhoto,
    required this.mode,
    required this.onModeChanged,
    this.isBusy = false,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final bool isPhotoMode;
  final bool hasSelectedPhoto;
  final _CreateTipsMode mode;
  final ValueChanged<_CreateTipsMode> onModeChanged;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isPhotoMode ? 'Режим: с фото' : 'Режим: без фото';
    final description = isPhotoMode
        ? (hasSelectedPhoto
            ? 'Мы используем выбранное фото как основу. '
                'Опишите, что нужно изменить или добавить.'
            : 'Выберите фото и опишите, что нужно изменить или добавить.')
        : 'Опишите, что нужно создать — приложение сделает '
            'изображение по вашему описанию.';

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CreateModeToggle(
            mode: mode,
            onModeChanged: onModeChanged,
            enabled: !isBusy,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPhotoMode
                      ? const Color(0xFFEDE9FF)
                      : const Color(0xFFF7F8FC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPhotoMode
                        ? _accentColor.withValues(alpha: 0.35)
                        : const Color(0xFFE8EAEF),
                  ),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPhotoMode
                        ? _accentColor
                        : AiImageGeneratorApp.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.4,
                    color: AiImageGeneratorApp.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreatePhotoDescriptionHints extends StatelessWidget {
  const _CreatePhotoDescriptionHints({
    required this.isBusy,
    required this.onHintSelected,
  });

  static const _hints = [
    'сделай фон светлым и чистым',
    'добавь атмосферу зимней улицы',
    'сделай фото в стиле рекламного баннера',
  ];

  final bool isBusy;
  final ValueChanged<String> onHintSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      height: 1.35,
      color: AiImageGeneratorApp.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Подсказки для описания', style: hintStyle),
        const SizedBox(height: 8),
        ..._hints.map(
          (hint) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: isBusy ? null : () => onHintSelected(hint),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: const Color(0xFF5B6CFF),
                  backgroundColor: const Color(0xFFF7F8FC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE8EAEF)),
                  ),
                ),
                child: Text(
                  'Например: $hint',
                  style: hintStyle?.copyWith(
                    color: AiImageGeneratorApp.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateReferencePhotoCard extends StatelessWidget {
  const _CreateReferencePhotoCard({
    required this.photoBytes,
    required this.isPickingPhoto,
    required this.isBusy,
    required this.onPickPhoto,
    required this.onClearPhoto,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final Uint8List? photoBytes;
  final bool isPickingPhoto;
  final bool isBusy;
  final VoidCallback onPickPhoto;
  final VoidCallback onClearPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = photoBytes != null;

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Фото для образа',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            hasPhoto
                ? 'Выбранное фото будет основой для нового изображения.'
                : 'Нажмите «Добавить фото», чтобы продолжить.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          if (!hasPhoto)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: isPickingPhoto || isBusy ? null : onPickPhoto,
                icon: isPickingPhoto
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: Text(isPickingPhoto ? 'Подождите...' : 'Добавить фото'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accentColor,
                  side: BorderSide(color: _accentColor.withValues(alpha: 0.45)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.memory(
                    photoBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: isBusy ? null : onClearPhoto,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Убрать фото'),
                style: TextButton.styleFrom(
                  foregroundColor: AiImageGeneratorApp.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateTipsCard extends StatelessWidget {
  const _CreateTipsCard({
    required this.mode,
    required this.onModeChanged,
    required this.isBusy,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final _CreateTipsMode mode;
  final ValueChanged<_CreateTipsMode> onModeChanged;
  final bool isBusy;

  static const _generalTips = [
    'Укажите главный объект.',
    'Добавьте место.',
    'Опишите стиль.',
    'Добавьте настроение.',
    'Не пишите слишком много противоречивых деталей.',
  ];

  static const _withoutPhotoIntro =
      'Опишите, что хотите увидеть: объект, место, стиль и настроение.';

  static const _withoutPhotoExamples = [
    'Уютный домик в зимнем лесу, вечер, тёплый свет из окон',
    'Современный город ночью, неоновые вывески, кинематографичный стиль',
  ];

  static const _withoutPhotoNote =
      'Этот режим подходит, когда вы хотите создать новое изображение с нуля.';

  static const _withPhotoIntro =
      'Если добавите фото, опишите, что нужно изменить или какой образ создать.';

  static const _withPhotoPersonExamples = [
    'Сделай деловой портрет в светлой студии, аккуратный костюм, мягкий свет',
    'Создай аватар для соцсетей, светлый фон, естественная улыбка',
    'Сделай зимний портрет на улице, тёплая одежда, красивый снег',
    'Добавь образ для резюме: спокойный фон, уверенный вид, реализм',
  ];

  static const _withPhotoObjectExamples = [
    'Сделай рекламное фото товара на светлом фоне, мягкий свет',
    'Поставь предмет на деревянный стол, уютная атмосфера, реализм',
    'Улучши фото комнаты: больше света, аккуратный интерьер, чистый фон',
    'Сделай красивую карточку товара для магазина, минимализм',
  ];

  static const _withPhotoNote =
      'Чем лучше видно объект на фото, тем лучше получится результат.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tipStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      height: 1.4,
      color: AiImageGeneratorApp.textPrimary,
    );
    final bodySecondary = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      height: 1.45,
      color: AiImageGeneratorApp.textSecondary,
    );
    final isPhotoMode = mode == _CreateTipsMode.withPhoto;

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: _accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Как получить хороший результат',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: !isPhotoMode
                ? _WithoutPhotoTipsContent(
                    key: const ValueKey('tips_without_photo'),
                    intro: _withoutPhotoIntro,
                    examples: _withoutPhotoExamples,
                    note: _withoutPhotoNote,
                    bodySecondary: bodySecondary,
                    theme: theme,
                  )
                : _WithPhotoTipsContent(
                    key: const ValueKey('tips_with_photo'),
                    intro: _withPhotoIntro,
                    personExamples: _withPhotoPersonExamples,
                    objectExamples: _withPhotoObjectExamples,
                    note: _withPhotoNote,
                    bodySecondary: bodySecondary,
                    theme: theme,
                  ),
          ),
          const SizedBox(height: 14),
          _CreateModeToggle(
            mode: mode,
            onModeChanged: onModeChanged,
            enabled: !isBusy,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _generalTips
                .map(
                  (tip) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8EAEF)),
                    ),
                    child: Text(tip, style: tipStyle),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WithoutPhotoTipsContent extends StatelessWidget {
  const _WithoutPhotoTipsContent({
    super.key,
    required this.intro,
    required this.examples,
    required this.note,
    required this.bodySecondary,
    required this.theme,
  });

  final String intro;
  final List<String> examples;
  final String note;
  final TextStyle? bodySecondary;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(intro, style: bodySecondary),
        const SizedBox(height: 12),
        Text(
          'Примеры',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...examples.map((e) => _CreateTipsExampleLine(text: e)),
        const SizedBox(height: 10),
        Text(
          note,
          style: bodySecondary?.copyWith(
            fontStyle: FontStyle.italic,
            color: AiImageGeneratorApp.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _WithPhotoTipsContent extends StatelessWidget {
  const _WithPhotoTipsContent({
    super.key,
    required this.intro,
    required this.personExamples,
    required this.objectExamples,
    required this.note,
    required this.bodySecondary,
    required this.theme,
  });

  final String intro;
  final List<String> personExamples;
  final List<String> objectExamples;
  final String note;
  final TextStyle? bodySecondary;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(intro, style: bodySecondary),
        const SizedBox(height: 12),
        _CreateTipsExampleGroup(
          title: 'Если на фото человек',
          examples: personExamples,
          theme: theme,
        ),
        const SizedBox(height: 12),
        _CreateTipsExampleGroup(
          title: 'Если на фото предмет или другое',
          examples: objectExamples,
          theme: theme,
        ),
        const SizedBox(height: 10),
        Text(note, style: bodySecondary),
      ],
    );
  }
}

class _CreateTipsExampleGroup extends StatelessWidget {
  const _CreateTipsExampleGroup({
    required this.title,
    required this.examples,
    required this.theme,
  });

  final String title;
  final List<String> examples;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...examples.map((e) => _CreateTipsExampleLine(text: e)),
        ],
      ),
    );
  }
}

class _CreateTipsExampleLine extends StatelessWidget {
  const _CreateTipsExampleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              height: 1.45,
              color: AiImageGeneratorApp.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.45,
                color: AiImageGeneratorApp.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.response});

  final GenerateImageResponse? response;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Статус генераций', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (response == null)
            Text('Готово к созданию', style: theme.textTheme.bodyMedium)
          else if (response!.creditConsumed) ...[
            Text(
              'Баланс обновлён',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AiImageGeneratorApp.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Бесплатных осталось: '
              '${response!.balance?.freeGenerationsRemaining ?? response!.remainingFreeGenerations ?? 0}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Изображений в балансе: '
              '${response!.balance?.paidImageGenerations ?? response!.remainingPaidCredits ?? 0}',
              style: theme.textTheme.bodyMedium,
            ),
            if (response!.paymentType == 'paid' &&
                (response!.balance?.freeGenerationsRemaining ?? 0) == 0) ...[
              const SizedBox(height: 8),
              Text(
                'Бесплатные генерации закончились — используйте изображения из баланса.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AiImageGeneratorApp.textSecondary,
                ),
              ),
            ],
          ] else
            Text(
              'Демо-режим: генерации не списываются',
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _GenerationErrorCard extends StatelessWidget {
  const _GenerationErrorCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SoftCard(
      borderColor: const Color(0xFFF5D0A8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 20, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Text(
                'Изображение не создано',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF9A5B00),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить описание или повторить позже.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF9A5B00),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.controller,
    this.isPhotoMode = false,
  });

  final TextEditingController controller;
  final bool isPhotoMode;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.sentences,
        enableSuggestions: true,
        enableIMEPersonalizedLearning: true,
        autocorrect: true,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: isPhotoMode
              ? 'Например: сделай деловой портрет на светлом фоне'
              : 'Например: уютный домик в зимнем лесу, вечер, тёплый свет',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(fontSize: 16, height: 1.45),
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    required this.isLoading,
    required this.onPressed,
    this.isPhotoMode = false,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isPhotoMode;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: onPressed == null ? null : _gradient,
              color: onPressed == null ? Colors.grey.shade300 : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: onPressed == null
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF5B6CFF).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isPhotoMode ? 'Создать по фото' : 'Создать',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isLoading
              ? (isPhotoMode
                  ? 'Создаём изображение по вашему фото. Обычно это занимает до минуты.'
                  : 'Создаём изображение. Обычно это занимает до минуты.')
              : (isPhotoMode
                  ? 'Обычно создание по фото занимает 20–60 секунд.'
                  : 'Обычно создание занимает 20–60 секунд.'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: AiImageGeneratorApp.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GenerationResultPreviewFallback extends StatelessWidget {
  const _GenerationResultPreviewFallback({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEDE9FF), Color(0xFFB8C4FF), Color(0xFF7C8CFF)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: compact ? 32 : 56,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              SizedBox(height: compact ? 8 : 16),
              Text(
                'Изображение создано',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 13 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: compact ? 4 : 8),
              Text(
                'Превью появится после подключения реальной генерации',
                textAlign: TextAlign.center,
                maxLines: compact ? 2 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: compact ? 10 : 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.response,
    required this.onOpenGallery,
  });

  final GenerateImageResponse response;
  final VoidCallback onOpenGallery;

  static const _accentColor = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SoftCard(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                response.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0xFFF0F2F8),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const _GenerationResultPreviewFallback(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Создано по описанию: ${response.prompt}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AiImageGeneratorApp.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onOpenGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 22),
            label: const Text(
              'Открыть в Галерее',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accentColor,
              side: BorderSide(color: _accentColor.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
