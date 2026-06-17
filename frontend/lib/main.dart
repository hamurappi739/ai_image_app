import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'assets/preview_asset_paths.dart';
import 'data/app_prompts.dart';
import 'models/generated_image_item.dart';
import 'models/payment_result.dart';
import 'models/user_balance.dart';
import 'navigation/app_section.dart';
import 'screens/gallery_screen.dart';
import 'screens/help_hub_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/template_photo_screen.dart';
import 'services/catalog_service.dart';
import 'services/api_service.dart';
import 'data/catalog_visuals.dart';
import 'models/catalog_entries.dart';
import 'services/auth_service.dart';
import 'services/payment_service.dart';
import 'services/create_help_service.dart';
import 'services/free_generations_welcome_service.dart';
import 'services/onboarding_service.dart';
import 'services/photoshoots_help_service.dart';
import 'utils/gallery_item_key.dart';
import 'utils/mock_photoshoot_photo.dart';
import 'widgets/app_balance_summary.dart';
import 'widgets/app_drawer.dart';
import 'widgets/app_navigation_scope.dart';
import 'widgets/app_screen_header.dart';
import 'widgets/category_filter_chips.dart';
import 'widgets/coming_soon_dialog.dart';
import 'widgets/custom_request_flow.dart';
import 'widgets/create_help_dialog.dart';
import 'widgets/create_result_tips_card.dart';
import 'widgets/free_generations_welcome_dialog.dart';
import 'widgets/gallery_result_image.dart';
import 'widgets/generation_progress_dialog.dart';
import 'widgets/good_result_guide_card.dart';
import 'widgets/insufficient_balance_dialog.dart';
import 'widgets/missing_photo_dialog.dart';
import 'widgets/photoshoot_generation_failed_dialog.dart';
import 'widgets/photoshoot_triplet_preview.dart';
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

  await CatalogService.instance.load();

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _apiService = ApiService();
  late final PaymentService _paymentService =
      PaymentService(apiService: _apiService);
  final _authService = AuthService();

  AppSection _section = AppSection.home;
  final List<GeneratedImageItem> _generatedImages = [];
  final Set<String> _hiddenGalleryImageKeys = {};
  final Set<String> _hiddenPhotoshootIds = {};
  bool _backendHistoryUnavailable = false;
  bool _galleryLoading = false;
  UserBalance? _userBalance;
  bool _balanceLoading = false;
  bool _balanceLoadFailed = false;
  StreamSubscription<AuthState>? _authSubscription;
  GallerySuccessKind? _gallerySuccessKind;
  String? _galleryHighlightKey;
  bool _demoWelcomeCheckScheduled = false;
  bool _demoWelcomePresentationStarted = false;

  bool get _isDemoModeWithoutAuth => !_authService.isConfigured;
  bool get _canLoadUserBackendData {
    if (!_authService.isConfigured) {
      return true;
    }
    return _authService.isSignedIn;
  }

  bool get _showUserBalance => _canLoadUserBackendData;

  @override
  void initState() {
    super.initState();
    _syncAccessTokenFromAuth();
    if (_authService.isConfigured) {
      _authSubscription = _authService.onAuthStateChange.listen(_onAuthStateChanged);
    }
    if (_canLoadUserBackendData) {
      _loadGenerationsFromBackend();
      _loadBalance();
    } else {
      _clearSessionUserData();
    }
    _scheduleDemoFreeGenerationsWelcome();
  }

  void _scheduleDemoFreeGenerationsWelcome() {
    if (_demoWelcomeCheckScheduled) return;
    _demoWelcomeCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeShowDemoFreeGenerationsWelcome());
    });
  }

  bool _hasModalOverlay(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).canPop();
  }

  Future<void> _maybeShowDemoFreeGenerationsWelcome() async {
    if (!mounted || !_isDemoModeWithoutAuth) return;
    if (_demoWelcomePresentationStarted) return;
    if (FreeGenerationsWelcomeService.shownThisSession) return;

    final alreadySeen = await FreeGenerationsWelcomeService.hasSeen();
    if (!mounted || alreadySeen) return;
    if (_hasModalOverlay(context)) return;

    _demoWelcomePresentationStarted = true;
    await FreeGenerationsWelcomeDialog.show(context);
    if (!mounted) return;
    await FreeGenerationsWelcomeService.markSeen();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged(AuthState state) {
    _syncAccessTokenFromAuth();
    if (state.event == AuthChangeEvent.signedOut) {
      _clearSessionUserData();
    } else if (state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.tokenRefreshed) {
      _loadGenerationsFromBackend();
      _loadBalance();
    }
    if (mounted) {
      setState(() {});
    }
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
    if (_canLoadUserBackendData) {
      _loadGenerationsFromBackend();
      _loadBalance();
    } else {
      _clearSessionUserData();
    }
    setState(() {});
  }

  void _clearSessionUserData() {
    setState(() {
      _generatedImages.clear();
      _hiddenGalleryImageKeys.clear();
      _hiddenPhotoshootIds.clear();
      _userBalance = null;
      _balanceLoading = false;
      _balanceLoadFailed = false;
      _backendHistoryUnavailable = false;
      _galleryLoading = false;
    });
  }

  Future<void> _loadBalance() async {
    if (!_canLoadUserBackendData) {
      if (!mounted) return;
      setState(() {
        _userBalance = null;
        _balanceLoading = false;
        _balanceLoadFailed = false;
      });
      return;
    }
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

  bool _scrollPhotoshootsToTrending = false;

  void _navigateToSection(AppSection section) {
    setState(() {
      if (section != AppSection.gallery) {
        _gallerySuccessKind = null;
        _galleryHighlightKey = null;
      }
      _section = section;
      _scrollPhotoshootsToTrending = false;
    });
    if (section == AppSection.photoshoots ||
        section == AppSection.customRequest ||
        section == AppSection.buy ||
        section == AppSection.profile) {
      _loadBalance();
    }
  }

  void _showShellSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String? _userDisplayName() {
    final user = _authService.currentUser;
    if (user == null) return null;
    final metadata = user.userMetadata;
    if (metadata == null) return null;
    for (final key in ['full_name', 'name', 'display_name']) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  void _updateBalance(UserBalance balance) {
    setState(() => _userBalance = balance);
  }

  Future<void> _loadGenerationsFromBackend() async {
    if (!_canLoadUserBackendData) {
      if (!mounted) return;
      setState(() {
        _generatedImages.clear();
        _hiddenGalleryImageKeys.clear();
        _hiddenPhotoshootIds.clear();
        _backendHistoryUnavailable = false;
        _galleryLoading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _galleryLoading = true;
      _backendHistoryUnavailable = false;
    });
    try {
      final history = await _apiService.fetchGenerations();
      if (!mounted) return;
      setState(() {
        _galleryLoading = false;
        _backendHistoryUnavailable = false;
        _generatedImages
          ..clear()
          ..addAll(history.map((item) => item.toGalleryItem()))
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _galleryLoading = false;
        _backendHistoryUnavailable = true;
      });
    }
  }

  void _goToPhotoshootsTab() => _navigateToSection(AppSection.photoshoots);

  void _showTrendingComingSoon() {
    if (!mounted) return;
    ComingSoonDialog.show(context);
  }

  void _onTrendingPhotoshootsScrollHandled() {
    if (!_scrollPhotoshootsToTrending) return;
    setState(() => _scrollPhotoshootsToTrending = false);
  }

  void _goToGalleryTab() => _navigateToSection(AppSection.gallery);

  void _goToPacksTab() {
    setState(() {
      _section = AppSection.buy;
      _scrollPhotoshootsToTrending = false;
    });
    _loadBalance();
  }

  void _goToBuyImages() => _goToPacksTab();

  void _goToBuyPhotoshoots() => _goToPacksTab();

  void _goToTemplateTab() => _navigateToSection(AppSection.templatePhoto);

  void _onImageGenerated(GeneratedImageItem item) {
    setState(() {
      if (item.id != null) {
        _generatedImages.removeWhere((existing) => existing.id == item.id);
      }
      _generatedImages.insert(0, item);
      _gallerySuccessKind = GallerySuccessKind.photo;
      _galleryHighlightKey = galleryImageHideKey(item);
    });
  }

  void _onPhotoshootGenerated(List<GeneratedImageItem> items) {
    final photoshootId = items.isNotEmpty
        ? items.first.photoshootId?.trim()
        : null;
    setState(() {
      _generatedImages.insertAll(0, items);
      _gallerySuccessKind = GallerySuccessKind.photoshoot;
      _galleryHighlightKey =
          (photoshootId != null && photoshootId.isNotEmpty)
              ? photoshootId
              : null;
    });
  }

  void _dismissGallerySuccessBanner() {
    if (_gallerySuccessKind == null) return;
    setState(() => _gallerySuccessKind = null);
  }

  void _clearGallery() {
    setState(() {
      _generatedImages.clear();
      _hiddenGalleryImageKeys.clear();
      _hiddenPhotoshootIds.clear();
    });
  }

  void _hideGalleryImage(String hideKey) {
    setState(() => _hiddenGalleryImageKeys.add(hideKey));
  }

  void _hidePhotoshoot(String photoshootId) {
    setState(() => _hiddenPhotoshootIds.add(photoshootId));
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(onNavigate: _navigateToSection),
      TemplatePhotoScreen(
        apiService: _apiService,
        balance: _userBalance,
        balanceLoading: _balanceLoading,
        onImageGenerated: _onImageGenerated,
        onBalanceUpdated: _updateBalance,
        onRefreshBalance: _loadBalance,
        onOpenGallery: _goToGalleryTab,
        onOpenPacks: _goToBuyImages,
        onShowMessage: _showShellSnackBar,
      ),
      PhotoshootsScreen(
        isActive: _section == AppSection.photoshoots,
        scrollToTrending: _scrollPhotoshootsToTrending,
        onTrendingScrollHandled: _onTrendingPhotoshootsScrollHandled,
        apiService: _apiService,
        balance: _userBalance,
        balanceLoading: _balanceLoading,
        onPhotoshootGenerated: _onPhotoshootGenerated,
        onBalanceUpdated: _updateBalance,
        onRefreshBalance: _loadBalance,
        onOpenGallery: _goToGalleryTab,
        onOpenPacks: _goToBuyPhotoshoots,
      ),
      CreateScreen(
        key: const ValueKey('create_screen'),
        isActive: _section == AppSection.customRequest,
        apiService: _apiService,
        balance: _userBalance,
        balanceLoading: _balanceLoading,
        onShowMessage: _showShellSnackBar,
        onImageGenerated: _onImageGenerated,
        onBalanceUpdated: _updateBalance,
        onRefreshBalance: _loadBalance,
        onOpenGallery: _goToGalleryTab,
        onOpenPacks: _goToBuyImages,
        onOpenTemplates: _goToTemplateTab,
      ),
      GalleryScreen(
        images: _generatedImages,
        hiddenImageKeys: _hiddenGalleryImageKeys,
        hiddenPhotoshootIds: _hiddenPhotoshootIds,
        onHideImage: _hideGalleryImage,
        onHidePhotoshoot: _hidePhotoshoot,
        onOpenTemplates: _goToTemplateTab,
        onOpenPhotoshoots: _goToPhotoshootsTab,
        onOpenBuy: _goToPacksTab,
        onClearGallery: _clearGallery,
        isLoading: _galleryLoading,
        loadFailed: _backendHistoryUnavailable,
        onRetry: _loadGenerationsFromBackend,
        successKind: _gallerySuccessKind,
        highlightItemKey: _galleryHighlightKey,
        onDismissSuccess: _dismissGallerySuccessBanner,
      ),
      PacksScreen(
        paymentService: _paymentService,
        balance: _userBalance,
        balanceLoading: _balanceLoading,
        balanceLoadFailed: _balanceLoadFailed,
        onRefreshBalance: _loadBalance,
        onBalanceUpdated: _updateBalance,
      ),
      ProfileScreen(
        authService: _authService,
        apiService: _apiService,
        onAuthChanged: _onProfileAuthChanged,
        onNavigate: _navigateToSection,
        onResetOnboarding: widget.onResetOnboarding,
        balance: _userBalance,
        balanceLoading: _balanceLoading,
        balanceLoadFailed: _balanceLoadFailed,
        onRefreshBalance: _loadBalance,
        showUserBalance: _showUserBalance,
      ),
      const HelpHubScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        currentSection: _section,
        onSectionSelected: _navigateToSection,
        onTrendingPhotoshootsTap: _showTrendingComingSoon,
        userEmail: _authService.currentUser?.email,
        userDisplayName: _userDisplayName(),
        showUserBalance: _showUserBalance,
        balance: _userBalance,
        balanceLoading: _balanceLoading,
        balanceLoadFailed: _balanceLoadFailed,
        onBuyTap: _goToPacksTab,
      ),
      body: AppNavigationScope(
        openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        showUserBalance: _showUserBalance,
        userBalance: _userBalance,
        balanceLoading: _balanceLoading,
        balanceLoadFailed: _balanceLoadFailed,
        child: IndexedStack(
          index: _section.index,
          children: screens,
        ),
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
    required this.packageId,
    required this.priceRub,
    required this.imageCount,
    required this.cardTitle,
    required this.subtitle,
    this.extraNote,
    this.featured = false,
    this.valueBadge,
    this.bestValue = false,
  });

  final String packageId;
  final int priceRub;
  final int imageCount;
  final String cardTitle;
  final String subtitle;
  final String? extraNote;
  final bool featured;
  final String? valueBadge;
  final bool bestValue;

  String get priceLabel => '$priceRub ₽';
}

String _formatMockPaymentAddedSummary(int images) {
  if (images <= 0) return 'Баланс обновлён.';
  return 'На баланс добавлено $images изображений.';
}

const _demoPurchaseNotice =
    'Демо-режим: деньги не списываются. '
    'Покупка нужна только для проверки приложения.';

class _DemoPurchaseNotice extends StatelessWidget {
  const _DemoPurchaseNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: Color(0xFF5B6CFF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _demoPurchaseNotice,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.4,
                color: AiImageGeneratorApp.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PacksScreen extends StatefulWidget {
  const PacksScreen({
    super.key,
    required this.paymentService,
    required this.balance,
    required this.balanceLoading,
    required this.balanceLoadFailed,
    required this.onRefreshBalance,
    required this.onBalanceUpdated,
  });

  final PaymentService paymentService;
  final UserBalance? balance;
  final bool balanceLoading;
  final bool balanceLoadFailed;
  final VoidCallback onRefreshBalance;
  final ValueChanged<UserBalance> onBalanceUpdated;

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  static const _breakpointMedium = 560.0;
  static const _breakpointWide = 900.0;

  static const _imagePackages = <_PackOffering>[
    _PackOffering(
      packageId: 'package_39_1_image',
      priceRub: 39,
      imageCount: 1,
      cardTitle: '1 фото',
      subtitle: 'Для одной генерации',
    ),
    _PackOffering(
      packageId: 'package_99_3_images',
      priceRub: 99,
      imageCount: 3,
      cardTitle: '3 фото',
      subtitle: '33 ₽ за 1 фото',
      extraNote: 'Хватит на 1 фотосессию',
    ),
    _PackOffering(
      packageId: 'package_249_9_images',
      priceRub: 249,
      imageCount: 9,
      cardTitle: '9 фото',
      subtitle: '28 ₽ за 1 фото',
      extraNote: 'До 3 фотосессий',
    ),
    _PackOffering(
      packageId: 'package_499_20_images',
      priceRub: 499,
      imageCount: 20,
      cardTitle: '20 фото',
      subtitle: '25 ₽ за 1 фото',
      featured: true,
      valueBadge: 'Популярно',
      extraNote: 'До 6 фотосессий',
    ),
    _PackOffering(
      packageId: 'package_999_50_images',
      priceRub: 999,
      imageCount: 50,
      cardTitle: '50 фото',
      subtitle: '20 ₽ за 1 фото',
      valueBadge: 'Выгодно',
      bestValue: true,
      extraNote: 'До 16 фотосессий',
    ),
  ];

  String? _processingPackageId;

  static int _columnCount(double width) {
    if (width >= _breakpointWide) return 3;
    if (width >= _breakpointMedium) return 2;
    return 1;
  }

  Future<void> _showMockTopUpLoadingDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Пополняем баланс…',
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        color: AiImageGeneratorApp.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPackPaymentSoonDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Оплата скоро',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Пополнение баланса пока доступно только в демо-режиме на backend.',
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Color(0xFF6B7280),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5B6CFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  Future<void> _presentPaymentResult(PaymentResult result) async {
    if (result.isFailed) {
      switch (result.failureReason) {
        case PaymentFailureReason.unavailable:
          await _showPackPaymentSoonDialog();
          return;
        case PaymentFailureReason.serviceUnavailable:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Не удалось выполнить покупку. Попробуйте ещё раз.',
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        case PaymentFailureReason.generic:
        case null:
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Не удалось выполнить покупку. Попробуйте ещё раз.',
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
      }
    }

    if (result.balance != null) {
      widget.onBalanceUpdated(result.balance!);
    }

    if (result.isAlreadyProcessed) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Покупка уже обработана',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Эта покупка уже была обработана.',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5B6CFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      return;
    }

    var successSummary = _formatMockPaymentAddedSummary(
      result.addedImageGenerations,
    );
    final unusedRub = result.unusedRub;
    if (unusedRub != null && unusedRub > 0) {
      successSummary += '\n\nОстаток $unusedRub ₽ пока не используется';
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Баланс пополнен',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Text(
          successSummary,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Color(0xFF6B7280),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5B6CFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Хорошо'),
          ),
        ],
      ),
    );
  }

  String _purchaseConfirmMessage(_PackOffering offering) {
    return 'Вы получите ${offering.imageCount} '
        '${_imagesWord(offering.imageCount)} за ${offering.priceRub} ₽.\n\n'
        'В демо-режиме деньги не списываются.';
  }

  static String _imagesWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'изображений';
    if (mod10 == 1) return 'изображение';
    if (mod10 >= 2 && mod10 <= 4) return 'изображения';
    return 'изображений';
  }

  Future<void> _onPackSelected(_PackOffering offering) async {
    if (_processingPackageId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Подтвердите покупку',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: Text(
          _purchaseConfirmMessage(offering),
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5B6CFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Купить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingPackageId = offering.packageId);
    unawaited(_showMockTopUpLoadingDialog());
    await Future<void>.delayed(Duration.zero);

    try {
      final result = await widget.paymentService.purchasePackage(
        offering.packageId,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _presentPaymentResult(result);
    } finally {
      if (mounted) {
        setState(() => _processingPackageId = null);
      }
    }
  }

  Widget _buildPackCardsList({
    required BuildContext context,
    required double maxWidth,
  }) {
    const spacing = 12.0;
    final columns = _columnCount(maxWidth);

    if (columns == 1) {
      return Column(
        children: [
          for (var i = 0; i < _imagePackages.length; i++) ...[
            if (i > 0) const SizedBox(height: spacing),
            _PackOfferingCard(
              offering: _imagePackages[i],
              isLoading:
                  _processingPackageId == _imagePackages[i].packageId,
              isDisabled: _processingPackageId != null &&
                  _processingPackageId != _imagePackages[i].packageId,
              onSelect: () => _onPackSelected(_imagePackages[i]),
            ),
          ],
        ],
      );
    }

    final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final offering in _imagePackages)
          SizedBox(
            width: cardWidth,
            child: _PackOfferingCard(
              offering: offering,
              isLoading: _processingPackageId == offering.packageId,
              isDisabled: _processingPackageId != null &&
                  _processingPackageId != offering.packageId,
              onSelect: () => _onPackSelected(offering),
            ),
          ),
      ],
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => const PacksHelpDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiImageGeneratorApp.scaffoldBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppScreenHeader(
                        title: 'Купить изображения',
                        subtitle:
                            'Пополните баланс, чтобы создавать фото '
                            'и фотосессии.',
                        trailing: SectionHelpButton(onPressed: _showHelp),
                      ),
                      const SizedBox(height: 16),
                      _UserBalancePacksBanner(
                        balance: widget.balance,
                        isLoading: widget.balanceLoading,
                        hasError: widget.balanceLoadFailed,
                        onRefresh: widget.onRefreshBalance,
                      ),
                      const SizedBox(height: 16),
                      const _BalancePricingInfoCard(),
                      const SizedBox(height: 14),
                      const _DemoPurchaseNotice(),
                      const SizedBox(height: 20),
                      _buildPackCardsList(
                        context: context,
                        maxWidth: constraints.maxWidth,
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

class _PackOfferingCard extends StatelessWidget {
  const _PackOfferingCard({
    required this.offering,
    required this.isLoading,
    required this.isDisabled,
    required this.onSelect,
  });

  final _PackOffering offering;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onSelect;

  static const _accentColor = Color(0xFF5B6CFF);
  static const _featuredGradient = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bannerLabel = offering.valueBadge ??
        (offering.featured ? 'Популярно' : null);
    final borderColor = offering.featured
        ? const Color(0xFF6B5CFF)
        : offering.bestValue
            ? const Color(0xFF9B7CFF)
            : const Color(0xFFE8EAEF);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: offering.featured || offering.bestValue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (offering.featured || offering.bestValue
                    ? _accentColor
                    : Colors.black)
                .withValues(
              alpha: offering.featured || offering.bestValue ? 0.1 : 0.04,
            ),
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
          if (bannerLabel != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: offering.featured
                    ? _featuredGradient
                    : LinearGradient(
                        colors: offering.bestValue
                            ? const [
                                Color(0xFFEDE9FF),
                                Color(0xFFE0D4FF),
                              ]
                            : const [
                                Color(0xFFEDE9FF),
                                Color(0xFFE8E4FF),
                              ],
                      ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Center(
                  child: Text(
                    bannerLabel,
                    style: TextStyle(
                      color: offering.featured ? Colors.white : _accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offering.cardTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offering.priceLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _accentColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offering.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.3,
                    color: AiImageGeneratorApp.textSecondary,
                  ),
                ),
                if (offering.extraNote != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    offering.extraNote!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      height: 1.3,
                      color: _accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _PackPaymentButton(
                  featured: offering.featured || offering.bestValue,
                  height: 40,
                  fontSize: 14,
                  isLoading: isLoading,
                  onPressed: isDisabled ? null : onSelect,
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
    required this.isLoading,
    required this.onPressed,
  });

  final bool featured;
  final double height;
  final double fontSize;
  final bool isLoading;
  final VoidCallback? onPressed;

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
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Купить',
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
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Text(
                'Купить',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
              ),
      ),
    );
  }
}

class _PhotoshootStyle {
  const _PhotoshootStyle({
    required this.id,
    required this.title,
    required this.description,
    required this.stylePrompt,
    required this.recommendation,
    required this.initials,
    required this.icon,
    required this.gradientColors,
    required this.isFree,
    this.previewVariant = 0,
    this.previewAssetPath,
    this.previewAssetPaths,
    this.previewUrls,
  });

  final String id;
  final String title;
  final String description;
  final String stylePrompt;
  final String recommendation;
  final String initials;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isFree;
  final int previewVariant;

  /// Optional hero preview for modals (legacy single image).
  final String? previewAssetPath;

  /// Three result previews for catalog cards (jpg under assets/previews/photoshoots/).
  final List<String>? previewAssetPaths;

  /// Optional remote preview URLs from backend catalog.
  final List<String>? previewUrls;

  String? get effectivePreviewAssetPath =>
      previewAssetPath ?? PreviewAssetPaths.photoshootPathForId(id);

  List<String> get effectivePreviewAssets =>
      previewAssetPaths ?? PreviewAssetPaths.photoshootPreviewAssetsForId(id);

  List<String> get effectivePreviewUrls => previewUrls ?? const [];

  String get priceLabel => isFree ? 'Бесплатно' : '3 изображения';

  factory _PhotoshootStyle.fromCatalog(CatalogPhotoshootEntry entry) {
    final visuals = CatalogVisuals.photoshootFor(entry.id);
    return _PhotoshootStyle(
      id: entry.id,
      title: entry.title,
      description: entry.shortDescription,
      stylePrompt: entry.prompt,
      recommendation: entry.badge ?? 'Фотосессия',
      initials: visuals.initials,
      icon: visuals.icon,
      gradientColors: visuals.gradientColors,
      isFree: entry.isFree,
      previewVariant: visuals.previewVariant,
      previewAssetPath:
          entry.previewAssets.isNotEmpty ? entry.previewAssets.first : null,
      previewAssetPaths: entry.previewAssets,
      previewUrls: entry.previewUrls,
    );
  }
}

class _PhotoshootCollection {
  const _PhotoshootCollection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.styleIds,
    this.highlighted = false,
    this.omitDuplicates = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> styleIds;
  final bool highlighted;
  final bool omitDuplicates;
}

class PhotoshootsScreen extends StatefulWidget {
  const PhotoshootsScreen({
    super.key,
    required this.isActive,
    this.scrollToTrending = false,
    this.onTrendingScrollHandled,
    required this.apiService,
    required this.balance,
    required this.balanceLoading,
    required this.onPhotoshootGenerated,
    required this.onBalanceUpdated,
    required this.onRefreshBalance,
    required this.onOpenGallery,
    required this.onOpenPacks,
  });

  final bool isActive;
  final bool scrollToTrending;
  final VoidCallback? onTrendingScrollHandled;
  final ApiService apiService;
  final UserBalance? balance;
  final bool balanceLoading;
  final void Function(List<GeneratedImageItem> items) onPhotoshootGenerated;
  final ValueChanged<UserBalance> onBalanceUpdated;
  final VoidCallback onRefreshBalance;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenPacks;

  @override
  State<PhotoshootsScreen> createState() => _PhotoshootsScreenState();
}

class _PhotoshootsScreenState extends State<PhotoshootsScreen> {
  bool _isHelpDialogVisible = false;
  final _scrollController = ScrollController();
  String _selectedCategoryId = 'trending';

  static const _gridBreakpoint = 560.0;

  static const _categoryIds = [
    'trending',
    'for_self',
    'work',
    'atmospheric',
  ];

  static const _categoryLabels = [
    'Популярное сейчас',
    'Для себя',
    'Для работы',
    'Атмосферные',
  ];

  static const _collections = [
    _PhotoshootCollection(
      id: 'trending',
      title: 'Популярное сейчас',
      subtitle: 'Стили, которые чаще всего выбирают для красивых фото.',
      styleIds: [
        'business_portrait',
        'studio_portrait',
        'urban_portrait',
        'evening_look',
      ],
      highlighted: true,
    ),
    _PhotoshootCollection(
      id: 'for_self',
      title: 'Для себя',
      subtitle: 'Нежные и сезонные варианты для личного профиля.',
      styleIds: [
        'tender_photoshoot',
        'summer_photoshoot',
        'winter_photoshoot',
        'home_portrait',
      ],
      omitDuplicates: true,
    ),
    _PhotoshootCollection(
      id: 'work',
      title: 'Для работы',
      subtitle: 'Образы для карьеры, блога и делового профиля.',
      styleIds: [
        'expert_photoshoot',
        'business_brand',
        'personal_brand',
      ],
      omitDuplicates: true,
    ),
    _PhotoshootCollection(
      id: 'atmospheric',
      title: 'Атмосферные',
      subtitle: 'Живые фоны и выразительная подача.',
      styleIds: [
        'travel_portrait',
        'cafe_city',
        'park_walk',
        'premium_portrait',
      ],
      omitDuplicates: true,
    ),
  ];

  List<_PhotoshootStyle> _stylesForSelectedCategory() {
    final collection = _collections.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => _collections.first,
    );
    return [
      for (final entry
          in CatalogService.instance.photoshootsForCategory(collection.title))
        _PhotoshootStyle.fromCatalog(entry),
    ];
  }

  @override
  void initState() {
    super.initState();
    _scheduleFirstVisitHelp();
    if (widget.scrollToTrending && widget.isActive) {
      _selectedCategoryId = 'trending';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PhotoshootsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleFirstVisitHelp();
    }
    if (widget.isActive &&
        widget.scrollToTrending &&
        (!oldWidget.scrollToTrending || !oldWidget.isActive)) {
      setState(() => _selectedCategoryId = 'trending');
      widget.onTrendingScrollHandled?.call();
    }
  }

  int get _selectedCategoryIndex {
    final index = _categoryIds.indexOf(_selectedCategoryId);
    return index >= 0 ? index : 0;
  }

  static double _photoshootGridItemWidth(double gridWidth, int columns) {
    if (columns <= 1) return gridWidth;
    return (gridWidth - 16 * (columns - 1)) / columns;
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

  void _openCustomPhotoshootSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CustomPhotoshootSheet(
        apiService: widget.apiService,
        balance: widget.balance,
        balanceLoading: widget.balanceLoading,
        onShowMessage: (message) => _showSnackBar(context, message),
        onPhotoshootGenerated: widget.onPhotoshootGenerated,
        onBalanceUpdated: widget.onBalanceUpdated,
        onRefreshBalance: widget.onRefreshBalance,
        onOpenGallery: widget.onOpenGallery,
        onOpenPacks: widget.onOpenPacks,
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

  Widget _buildStyleGrid({
    required BuildContext context,
    required List<_PhotoshootStyle> styles,
    required int columns,
    required double gridWidth,
  }) {
    if (styles.isEmpty) return const SizedBox.shrink();

    final itemWidth = _photoshootGridItemWidth(gridWidth, columns);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final style in styles)
          SizedBox(
            width: itemWidth,
            child: _PhotoshootCard(
              style: style,
              onAction: () => _onStyleSelected(context, style),
            ),
          ),
      ],
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
        onRefreshBalance: widget.onRefreshBalance,
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
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >= _gridBreakpoint ? 2 : 1;
                final styles = _stylesForSelectedCategory();
                final selectedCollection = _collections.firstWhere(
                  (c) => c.id == _selectedCategoryId,
                  orElse: () => _collections.first,
                );

                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 16, 20, 32),
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
                      const SizedBox(height: 16),
                      _CustomPhotoshootPromoBanner(
                        onAction: () => _openCustomPhotoshootSheet(context),
                      ),
                      const SizedBox(height: 16),
                      CategoryFilterChips(
                        labels: _categoryLabels,
                        selectedIndex: _selectedCategoryIndex,
                        onSelected: (index) {
                          setState(() {
                            _selectedCategoryId = _categoryIds[index];
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        selectedCollection.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              height: 1.4,
                              color: AiImageGeneratorApp.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildStyleGrid(
                        context: context,
                        styles: styles,
                        columns: columns,
                        gridWidth: constraints.maxWidth,
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

class _PhotoshootCard extends StatelessWidget {
  const _PhotoshootCard({
    required this.style,
    required this.onAction,
  });

  final _PhotoshootStyle style;
  final VoidCallback onAction;

  static const _accentColor = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: style.isFree
              ? const Color(0xFFE8EAEF)
              : _accentColor.withValues(alpha: 0.28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            PhotoshootTripletPreview(
              styleId: style.id,
              previewAssets: style.effectivePreviewAssets,
              previewUrls: style.effectivePreviewUrls,
              gradientColors: style.gradientColors,
              icon: style.icon,
              previewVariant: style.previewVariant,
            ),
            const SizedBox(height: 10),
            Text(
              style.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              style.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                height: 1.3,
                color: AiImageGeneratorApp.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              'Стоимость: 3 изображения',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: style.isFree
                  ? FilledButton(
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Попробовать',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: onAction,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accentColor,
                        side: BorderSide(
                          color: _accentColor.withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Создать',
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
    final isDemoMode = balance != null && !balance!.consumptionEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppScreenHeader(
          title: 'Фотосессии',
          subtitle:
              'Выберите стиль — приложение подготовит серию из 3 фото.',
          trailing: SectionHelpButton(
            onPressed: onShowHelp,
            enabled: helpEnabled,
          ),
        ),
        const SizedBox(height: 14),
        if (isDemoMode && balance != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Демо-режим — фотосессии доступны без списания.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: AiImageGeneratorApp.textSecondary,
                  ),
            ),
          )
        else
          AppScreenBalanceCard(
            balance: balance,
            isLoading: balanceLoading,
            showPhotoshootCostHint: true,
          ),
        if (showDepletedWarning) ...[
          const SizedBox(height: 12),
          InsufficientBalanceHint(
            message: 'Для фотосессии нужно 3 изображения.',
            actionLabel: 'Купить изображения',
            onOpenPacks: onOpenPacks,
          ),
        ],
      ],
    );
  }
}

class _CustomPhotoshootPromoBanner extends StatelessWidget {
  const _CustomPhotoshootPromoBanner({required this.onAction});

  final VoidCallback onAction;

  static const _accentColor = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8F5), Color(0xFFEEF1FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8B4A0).withValues(alpha: 0.45),
          width: 1.5,
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      _accentColor.withValues(alpha: 0.12),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 24,
                  color: _accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Не нашли подходящий стиль?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Опишите свой образ — мы подготовим фотосессию '
                      'по вашей идее.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.45,
                        color: AiImageGeneratorApp.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Создать свой образ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
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
    required this.onRefreshBalance,
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
  final VoidCallback onRefreshBalance;
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
    '3 готовых фото',
    'Стоимость: 3 изображения',
    'Фотосессия сохранится в готовых фото',
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
      await MissingPhotoDialog.showForPhotoshoot(context);
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
          description: widget.style.stylePrompt,
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
      } else {
        widget.onRefreshBalance();
      }
      final description = 'Фотосессия: ${result.styleTitle}';
      final createdAt = DateTime.now();
      final photoshootId = result.photoshootId.trim();
      final galleryItems = result.imageUrls
          .map(
            (url) => GeneratedImageItem(
              description: description,
              imageUrl: url,
              createdAt: createdAt,
              photoshootId: photoshootId.isEmpty ? null : photoshootId,
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
    } on PhotoshootGenerationFailedException {
      if (!mounted) return;
      await PhotoshootGenerationFailedDialog.show(context);
    } catch (_) {
      if (!mounted) return;
      await PhotoshootGenerationFailedDialog.show(context);
    } finally {
      if (mounted) setState(() => _isPreparingPhotoshoot = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style;
    final hasPhoto = _selectedPhotoBytes != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
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
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  16 + MediaQuery.viewPaddingOf(context).bottom,
                ),
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
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            style.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _isPreparingPhotoshoot
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Закрыть',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PhotoshootTripletPreview(
                      styleId: style.id,
                      previewAssets: style.effectivePreviewAssets,
                      previewUrls: style.effectivePreviewUrls,
                      gradientColors: style.gradientColors,
                      icon: style.icon,
                      previewVariant: style.previewVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Добавьте фото',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_usingMockPhoto) ...[
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
                      const SizedBox(height: 10),
                    ],
                    if (!hasPhoto)
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed:
                              _isPickingPhoto || _isPreparingPhotoshoot
                                  ? null
                                  : _pickPhoto,
                          icon: _isPickingPhoto
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            _isPickingPhoto ? 'Подождите…' : 'Выбрать фото',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.memory(
                            _selectedPhotoBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: _isPreparingPhotoshoot || _isPickingPhoto
                                ? null
                                : _pickPhoto,
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            label: const Text('Изменить фото'),
                            style: TextButton.styleFrom(
                              foregroundColor: _accentColor,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          TextButton.icon(
                            onPressed:
                                _isPreparingPhotoshoot ? null : _clearPhoto,
                            icon: const Icon(Icons.close, size: 17),
                            label: const Text('Убрать фото'),
                            style: TextButton.styleFrom(
                              foregroundColor: AiImageGeneratorApp.textSecondary,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Что получится',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._outcomes.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 16,
                                    color: _accentColor.withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      line,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: AiImageGeneratorApp.textSecondary,
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
                    const SizedBox(height: 12),
                    const GoodResultGuideCard(
                      style: GoodResultGuideStyle.sheet,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _isPreparingPhotoshoot
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF7C5CFF),
                                    Color(0xFF4A7CFF),
                                  ],
                                ),
                          color: _isPreparingPhotoshoot
                              ? Colors.grey.shade300
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isPreparingPhotoshoot
                              ? null
                              : [
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
      ),
    );
  }
}

class _CustomPhotoshootIdea {
  const _CustomPhotoshootIdea({required this.label, required this.text});

  final String label;
  final String text;
}

class _CustomPhotoshootFlow {
  _CustomPhotoshootFlow._();

  static const styleId = 'custom_photoshoot';
  static const baseTitle = 'Своя фотосессия';
  static const minDescriptionLength = 10;
  static const maxHistoryDescriptionLength = 1000;

  static final ideas = AppPrompts.customPhotoshootChips
      .map(
        (chip) => _CustomPhotoshootIdea(label: chip.label, text: chip.text),
      )
      .toList();

  static String galleryDescription(String description) {
    final trimmed = description.trim();
    final prefix = '$baseTitle: ';
    final maxBody = maxHistoryDescriptionLength - prefix.length;
    if (maxBody <= 0) return baseTitle;
    if (trimmed.length <= maxBody) return '$prefix$trimmed';
    return '$prefix${trimmed.substring(0, maxBody)}';
  }

  static String galleryDescriptionFromResponse({
    required String userDescription,
    String? serverDescription,
  }) {
    final normalized = serverDescription?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return galleryDescription(normalized);
    }
    return galleryDescription(userDescription);
  }
}

class _CustomPhotoshootSheet extends StatefulWidget {
  const _CustomPhotoshootSheet({
    required this.apiService,
    required this.balance,
    required this.balanceLoading,
    required this.onShowMessage,
    required this.onPhotoshootGenerated,
    required this.onBalanceUpdated,
    required this.onRefreshBalance,
    required this.onOpenGallery,
    required this.onOpenPacks,
  });

  final ApiService apiService;
  final UserBalance? balance;
  final bool balanceLoading;
  final void Function(String message) onShowMessage;
  final void Function(List<GeneratedImageItem> items) onPhotoshootGenerated;
  final ValueChanged<UserBalance> onBalanceUpdated;
  final VoidCallback onRefreshBalance;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenPacks;

  @override
  State<_CustomPhotoshootSheet> createState() => _CustomPhotoshootSheetState();
}

class _CustomPhotoshootSheetState extends State<_CustomPhotoshootSheet> {
  static const _accentColor = Color(0xFF5B6CFF);

  final _imagePicker = ImagePicker();
  final _descriptionController = TextEditingController();

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

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyMockPhoto() {
    setState(() {
      _selectedPhotoFile = MockPhotoshootPhoto.asXFile();
      _selectedPhotoBytes = MockPhotoshootPhoto.bytes;
      _usingMockPhoto = true;
    });
  }

  void _clearPhoto() {
    setState(() {
      _selectedPhotoFile = null;
      _selectedPhotoBytes = null;
      _usingMockPhoto = false;
    });
  }

  void _applyIdea(String text) {
    setState(() {
      _descriptionController.text = text;
      _descriptionController.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
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
      widget.onShowMessage('Не удалось выбрать фото. Попробуйте ещё раз.');
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

  Future<void> _onCreatePressed() async {
    if (_isPreparingPhotoshoot) return;

    final selectedPhotoFile = _selectedPhotoFile;
    if (selectedPhotoFile == null) {
      await MissingPhotoDialog.showForPhotoshoot(context);
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      widget.onShowMessage('Опишите, какой образ хотите получить.');
      return;
    }
    if (description.length < _CustomPhotoshootFlow.minDescriptionLength) {
      widget.onShowMessage('Добавьте немного больше деталей.');
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
          styleId: _CustomPhotoshootFlow.styleId,
          styleTitle: _CustomPhotoshootFlow.baseTitle,
          photoFile: selectedPhotoFile,
          description: description,
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
      } else {
        widget.onRefreshBalance();
      }

      final galleryDescription =
          _CustomPhotoshootFlow.galleryDescriptionFromResponse(
        userDescription: description,
        serverDescription: result.description,
      );
      final createdAt = DateTime.now();
      final photoshootId = result.photoshootId.trim();
      final galleryItems = result.imageUrls
          .map(
            (url) => GeneratedImageItem(
              description: galleryDescription,
              imageUrl: url,
              createdAt: createdAt,
              photoshootId: photoshootId.isEmpty ? null : photoshootId,
            ),
          )
          .toList();

      Navigator.of(context).pop();
      widget.onPhotoshootGenerated(galleryItems);
      widget.onShowMessage(
        'Фотосессия готова и сохранена в готовых фото.',
      );
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
    } on PhotoshootGenerationFailedException {
      if (!mounted) return;
      await PhotoshootGenerationFailedDialog.show(context);
    } catch (_) {
      if (!mounted) return;
      await PhotoshootGenerationFailedDialog.show(context);
    } finally {
      if (mounted) setState(() => _isPreparingPhotoshoot = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = _selectedPhotoBytes != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
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
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  16 + MediaQuery.viewPaddingOf(context).bottom,
                ),
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
                    const SizedBox(height: 16),
                    Text(
                      _CustomPhotoshootFlow.baseTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Опишите, какой образ хотите получить. '
                    'Мы создадим серию из 3 фото.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: AiImageGeneratorApp.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ваш образ',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          'Например: деловая фотосессия в светлом костюме '
                          'на фоне города',
                      hintStyle: TextStyle(
                        color: AiImageGeneratorApp.textSecondary
                            .withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F8FC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE8EAEF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE8EAEF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _accentColor.withValues(alpha: 0.55),
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Идеи для вдохновения',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AiImageGeneratorApp.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final idea in _CustomPhotoshootFlow.ideas)
                        ActionChip(
                          label: Text(
                            idea.label,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: _isPreparingPhotoshoot
                              ? null
                              : () => _applyIdea(idea.text),
                          backgroundColor: const Color(0xFFF0F2FF),
                          side: BorderSide(
                            color: _accentColor.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ваше фото',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Выбрать фото'),
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
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: Image.memory(
                          _selectedPhotoBytes!,
                          width: double.infinity,
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
                  if (_usingMockPhoto) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Для проверки на эмуляторе используется тестовое фото.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AiImageGeneratorApp.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Что получится',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...const [
                          '3 готовых фото',
                          'Стоимость: 3 изображения',
                          'Фотосессия сохранится в готовых фото',
                        ].map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: _accentColor.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: AiImageGeneratorApp.textSecondary,
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
                  const SizedBox(height: 12),
                  const GoodResultGuideCard(style: GoodResultGuideStyle.sheet),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed:
                          _isPreparingPhotoshoot ? null : _onCreatePressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _accentColor.withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
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
    ),
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
    this.onShowMessage,
    required this.onImageGenerated,
    required this.onBalanceUpdated,
    required this.onRefreshBalance,
    required this.onOpenGallery,
    required this.onOpenPacks,
    required this.onOpenTemplates,
  });

  final bool isActive;
  final ApiService apiService;
  final UserBalance? balance;
  final bool balanceLoading;
  final ValueChanged<String>? onShowMessage;
  final ValueChanged<GeneratedImageItem> onImageGenerated;
  final ValueChanged<UserBalance> onBalanceUpdated;
  final VoidCallback onRefreshBalance;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenPacks;
  final VoidCallback onOpenTemplates;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {

  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _showGenerationErrorState = false;
  bool _isHelpDialogVisible = false;
  bool _isPickingPhoto = false;
  Uint8List? _selectedPhotoBytes;
  XFile? _selectedPhotoFile;
  GenerateImageResponse? _lastResponse;

  bool get _hasSelectedPhoto => _selectedPhotoBytes != null;

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
    final photoFile = _selectedPhotoFile;
    if (photoFile == null) {
      throw StateError('Photo required');
    }
    return widget.apiService.generateImageWithPhoto(
      description: text,
      photoFile: photoFile,
    );
  }

  Future<void> _onGenerate() async {
    final text = _descriptionController.text.trim();

    if (!_hasSelectedPhoto) {
      await MissingPhotoDialog.showForTemplateOrCustom(context);
      return;
    }
    if (text.isEmpty) {
      _showSnackBar('Напишите, что нужно сделать с фото.');
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
        title: 'Создаём фото…',
        subtitle: 'Обычно это занимает до минуты.',
        totalSeconds: 60,
        task: () => _runGeneration(text),
      );
      if (!mounted) return;
      final updatedBalance = response.balance;
      if (updatedBalance != null) {
        widget.onBalanceUpdated(updatedBalance);
      } else {
        widget.onRefreshBalance();
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
      widget.onOpenGallery();
      widget.onShowMessage?.call(
        'Фото готово и сохранено в готовых фото.',
      );
    } on InsufficientImagesException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _showInsufficientImagesDialog();
    } on PhotoGenerationInvalidPhotoException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Выберите фото JPEG, PNG или WebP до 10 МБ');
    } on PhotoGenerationDescriptionException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Напишите, что нужно сделать с фото.');
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _handleError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _handleError(String message) {
    if (message == 'Prompt cannot be empty') {
      _showSnackBar('Напишите, что нужно сделать с фото.');
      return;
    }
    if (InsufficientBalanceMessages.looksLikeInsufficientImages(message)) {
      _showInsufficientImagesDialog();
      return;
    }
    if (InsufficientBalanceMessages.looksLikeInsufficientPhotoshoots(message) ||
        InsufficientBalanceMessages.looksLikePaymentRequired(message)) {
      _showSnackBar('Пополните баланс, чтобы продолжить.');
      return;
    }
    setState(() => _showGenerationErrorState = true);
    _showSnackBar('Не удалось создать фото. Попробуйте ещё раз.');
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
    final showImagesDepleted = widget.balance != null &&
        !widget.balanceLoading &&
        widget.balance!.showImageDepletedWarning;

    return Scaffold(
      backgroundColor: AiImageGeneratorApp.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppScreenHeader(
                title: 'Своя идея',
                subtitle:
                    'Добавьте фото и напишите, что нужно изменить или создать.',
                trailing: SectionHelpButton(
                  onPressed: _showHelp,
                  enabled: !_isHelpDialogVisible,
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _isLoading ? null : widget.onOpenTemplates,
                icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
                label: const Text('Не знаете, что написать? Откройте шаблоны'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5B6CFF),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(height: 16),
              _CreateBalanceInfoCard(
                balance: widget.balance,
                isLoading: widget.balanceLoading,
              ),
              const SizedBox(height: 20),
              if (showImagesDepleted) ...[
                InsufficientBalanceHint(
                  message: 'Изображения на балансе закончились.',
                  actionLabel: 'Купить изображения',
                  onOpenPacks: widget.onOpenPacks,
                ),
                const SizedBox(height: 12),
              ],
              CustomRequestFlow(
                descriptionController: _descriptionController,
                photoBytes: _selectedPhotoBytes,
                isPickingPhoto: _isPickingPhoto,
                isBusy: _isLoading,
                onPickPhoto: _pickReferencePhoto,
                onClearPhoto: _clearReferencePhoto,
                onCreate: _isLoading ? null : _onGenerate,
                isCreating: _isLoading,
                onIdeaSelected: _applyQuickIdea,
              ),
              const SizedBox(height: 24),
              const CreateResultTipsCard(),
              const SizedBox(height: 24),
              if (_showGenerationErrorState) ...[
                const _GenerationErrorCard(),
                const SizedBox(height: 20),
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

class _BalancePricingInfoCard extends StatelessWidget {
  const _BalancePricingInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
          Text(
            'Как это работает',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const _BalancePricingLine(text: '1 фото = 1 изображение'),
          const SizedBox(height: 6),
          const _BalancePricingLine(text: '1 фотосессия = 3 изображения'),
          const SizedBox(height: 8),
          Text(
            'Все созданные результаты сохраняются в готовых фото.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              height: 1.35,
              color: AiImageGeneratorApp.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancePricingLine extends StatelessWidget {
  const _BalancePricingLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(
            Icons.circle,
            size: 6,
            color: Color(0xFF5B6CFF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.4,
                  color: AiImageGeneratorApp.textPrimary,
                ),
          ),
        ),
      ],
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
                    value: '${balance!.totalAvailableImages}',
                  ),
                  _PacksBalanceStat(
                    label: 'Бесплатные генерации',
                    value: '${balance!.freeGenerationsRemaining}',
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
              'Фотосессия стоит 3 изображения',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
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
    final totalImages = balance?.totalAvailableImages ?? 0;
    final isDepleted = balance != null && balance!.showImageDepletedWarning;

    if (isLoading && balance == null) {
      return AppScreenBalanceCard(balance: balance, isLoading: true);
    }

    if (isDemoMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentColor.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Демо-режим',
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AiImageGeneratorApp.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Сейчас приложение работает в демо-режиме.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: AiImageGeneratorApp.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (isDepleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE082)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Изображения закончились',
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AiImageGeneratorApp.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Пополните баланс, чтобы продолжить.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: AiImageGeneratorApp.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (freeRemaining > 0 && totalImages == freeRemaining) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EAEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Бесплатные: $freeRemaining из $freeLimit',
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AiImageGeneratorApp.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Используйте их, чтобы попробовать создание фото.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: AiImageGeneratorApp.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return AppScreenBalanceCard(balance: balance, isLoading: isLoading);
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.borderColor,
  });

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                'Фото не создано',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF9A5B00),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте другое фото или измените описание.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF9A5B00),
            ),
          ),
        ],
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
              child: GalleryResultImage(
                url: response.imageUrl,
                description: response.prompt,
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
              'Открыть готовые фото',
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
