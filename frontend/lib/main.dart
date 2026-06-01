import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/gallery_display_item.dart';
import 'models/generated_image_item.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/create_help_service.dart';
import 'services/onboarding_service.dart';
import 'services/photoshoots_help_service.dart';
import 'widgets/create_help_dialog.dart';
import 'widgets/packs_help_dialog.dart';
import 'widgets/photoshoots_help_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _syncAccessTokenFromAuth();
    _loadGenerationsFromBackend();
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
    setState(() {});
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
        onImageGenerated: _onImageGenerated,
        onOpenGallery: _goToGalleryTab,
      ),
      PhotoshootsScreen(
        isActive: _selectedIndex == 1,
        apiService: _apiService,
        onPhotoshootGenerated: _onPhotoshootGenerated,
        onOpenGallery: _goToGalleryTab,
      ),
      GalleryScreen(
        images: _generatedImages,
        onCreateFirst: _goToCreateTab,
        onClearGallery: _clearGallery,
        backendHistoryUnavailable: _backendHistoryUnavailable,
      ),
      const PacksScreen(),
      ProfileScreen(
        authService: _authService,
        apiService: _apiService,
        onAuthChanged: _onProfileAuthChanged,
        onResetOnboarding: widget.onResetOnboarding,
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
        onTap: (index) => setState(() => _selectedIndex = index),
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

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key});

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen> {
  static const _breakpointMedium = 560.0;
  static const _breakpointWide = 900.0;

  static const _imageUnitRub = 10;
  static const _photoshootUnitRub = 100;
  static const _customAmountMin = 200;
  static const _customAmountMax = 100000;

  static const _mixedPackages = <_PackOffering>[
    _PackOffering(
      priceRub: 199,
      photoshootCount: 1,
      imageCount: 9,
      subtitle: 'Хорошо для первого знакомства',
    ),
    _PackOffering(
      priceRub: 499,
      photoshootCount: 3,
      imageCount: 19,
      subtitle: 'Для нескольких образов',
      featured: true,
    ),
    _PackOffering(
      priceRub: 999,
      photoshootCount: 8,
      imageCount: 19,
      subtitle: 'Больше фотосессий',
    ),
  ];

  static const _imagesOnlyPackages = <_PackOffering>[
    _PackOffering(
      priceRub: 199,
      imageCount: 19,
      subtitle: 'Для небольших идей',
    ),
    _PackOffering(
      priceRub: 499,
      imageCount: 49,
      subtitle: 'Для частого создания',
      featured: true,
    ),
    _PackOffering(
      priceRub: 999,
      imageCount: 99,
      subtitle: 'Лучше всего по цене',
    ),
  ];

  _PackCatalogMode _catalogMode = _PackCatalogMode.withPhotoshoots;
  int _customAmount = 1000;
  int _customPhotoshootCount = 8;
  late final TextEditingController _customAmountController;

  @override
  void initState() {
    super.initState();
    _customAmountController = TextEditingController(text: '$_customAmount');
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  List<_PackOffering> get _activePackages => _catalogMode == _PackCatalogMode.withPhotoshoots
      ? _mixedPackages
      : _imagesOnlyPackages;

  int get _maxCustomPhotoshoots => _customAmount ~/ _photoshootUnitRub;

  int get _customImageCount {
    final remainder = _customAmount - (_customPhotoshootCount * _photoshootUnitRub);
    if (remainder <= 0) return 0;
    return remainder ~/ _imageUnitRub;
  }

  static int _columnCount(double width) {
    if (width >= _breakpointWide) return 3;
    if (width >= _breakpointMedium) return 2;
    return 1;
  }

  static double _aspectRatio(int columns, bool hasPhotoshoots) {
    if (hasPhotoshoots) {
      switch (columns) {
        case 3:
          return 0.52;
        case 2:
          return 0.58;
        default:
          return 0.72;
      }
    }
    switch (columns) {
      case 3:
        return 0.55;
      case 2:
        return 0.62;
      default:
        return 0.78;
    }
  }

  void _showPaymentsLaterSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Оплата будет добавлена позже'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => const PacksHelpDialog(),
    );
  }

  void _onCustomAmountChanged(String value) {
    final trimmed = value.replaceAll(RegExp(r'\s'), '');
    if (trimmed.isEmpty) return;
    final parsed = int.tryParse(trimmed);
    if (parsed == null) return;
    final clamped = parsed.clamp(_customAmountMin, _customAmountMax);
    setState(() {
      _customAmount = clamped;
      if (_customPhotoshootCount > _maxCustomPhotoshoots) {
        _customPhotoshootCount = _maxCustomPhotoshoots;
      }
    });
    final text = '$clamped';
    if (_customAmountController.text != text) {
      _customAmountController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _setCustomPhotoshootCount(int count) {
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
                          IconButton(
                            onPressed: _showHelp,
                            tooltip: 'Помощь',
                            icon: const Icon(Icons.help_outline),
                            color: AiImageGeneratorApp.textSecondary,
                            iconSize: 26,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Как это работает',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Изображения используются в разделе «Создать». '
                              'Фотосессия создаёт несколько готовых фото в выбранном стиле.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Оплата будет подключена позже.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AiImageGeneratorApp.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Тип пакета',
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
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio:
                              _aspectRatio(columns, showPhotoshoots),
                        ),
                        itemCount: _activePackages.length,
                        itemBuilder: (context, index) {
                          return _PackOfferingCard(
                            offering: _activePackages[index],
                            showPhotoshoots: showPhotoshoots,
                            onPaymentSoon: _showPaymentsLaterSnackBar,
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Своя сумма',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Рассчитайте, сколько фотосессий и изображений получите '
                        'на выбранную сумму. Оплата пока недоступна.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CustomAmountSection(
                        amountController: _customAmountController,
                        amount: _customAmount,
                        photoshootCount: _customPhotoshootCount,
                        maxPhotoshoots: _maxCustomPhotoshoots,
                        imageCount: _customImageCount,
                        onAmountChanged: _onCustomAmountChanged,
                        onPhotoshootCountChanged: _setCustomPhotoshootCount,
                        onPhotoshootsDecrease: _customPhotoshootCount > 0
                            ? () => _adjustCustomPhotoshoots(-1)
                            : null,
                        onPhotoshootsIncrease: _customPhotoshootCount <
                                _maxCustomPhotoshoots
                            ? () => _adjustCustomPhotoshoots(1)
                            : null,
                        onPaymentSoon: _showPaymentsLaterSnackBar,
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
    required this.showPhotoshoots,
    required this.onPaymentSoon,
  });

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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: offering.featured
            ? Border.all(color: const Color(0xFF6B5CFF), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: (offering.featured ? _accentColor : Colors.black)
                .withValues(alpha: offering.featured ? 0.12 : 0.05),
            blurRadius: offering.featured ? 28 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offering.featured)
            Container(
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(gradient: _featuredGradient),
              child: const Text(
                'Популярный',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offering.priceLabel,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _accentColor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (showPhotoshoots && offering.photoshootCount > 0) ...[
                    _PackStatChip(
                      label:
                          '${offering.photoshootCount} ${_packPhotoshootLabel(offering.photoshootCount)}',
                      backgroundColor: const Color(0xFFEDE9FF),
                      textColor: _accentColor,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _PackStatChip(
                    label:
                        '${offering.imageCount} ${_packImageLabel(offering.imageCount)}',
                    backgroundColor: const Color(0xFFF0F2FF),
                    textColor: AiImageGeneratorApp.textPrimary,
                  ),
                  const Spacer(),
                  Text(
                    offering.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: offering.featured
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: _featuredGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onPaymentSoon,
                                borderRadius: BorderRadius.circular(12),
                                child: const Center(
                                  child: Text(
                                    'Оплата скоро',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: onPaymentSoon,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accentColor,
                              side: BorderSide(
                                color: _accentColor.withValues(alpha: 0.45),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Оплата скоро',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _PackStatChip extends StatelessWidget {
  const _PackStatChip({
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CustomAmountSection extends StatelessWidget {
  const _CustomAmountSection({
    required this.amountController,
    required this.amount,
    required this.photoshootCount,
    required this.maxPhotoshoots,
    required this.imageCount,
    required this.onAmountChanged,
    required this.onPhotoshootCountChanged,
    required this.onPhotoshootsDecrease,
    required this.onPhotoshootsIncrease,
    required this.onPaymentSoon,
  });

  static const _accentColor = Color(0xFF5B6CFF);

  final TextEditingController amountController;
  final int amount;
  final int photoshootCount;
  final int maxPhotoshoots;
  final int imageCount;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<int> onPhotoshootCountChanged;
  final VoidCallback? onPhotoshootsDecrease;
  final VoidCallback? onPhotoshootsIncrease;
  final VoidCallback onPaymentSoon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Сумма пополнения, ₽',
              hintText: 'От 200 до 100 000',
              filled: true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _accentColor, width: 1.5),
              ),
            ),
            onChanged: onAmountChanged,
          ),
          const SizedBox(height: 20),
          Text(
            'Сколько фотосессий включить',
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            '1 фотосессия = 100 ₽ · остаток суммы идёт на изображения по 10 ₽',
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
          if (maxPhotoshoots > 0)
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'За $amount ₽ вы получите:',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 10),
                if (photoshootCount > 0)
                  Text(
                    '$photoshootCount ${_packPhotoshootLabel(photoshootCount)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (imageCount > 0)
                  Text(
                    '$imageCount ${_packImageLabel(imageCount)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (photoshootCount == 0 && imageCount == 0)
                  Text(
                    'Увеличьте сумму или уменьшите число фотосессий',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AiImageGeneratorApp.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onPaymentSoon,
              style: OutlinedButton.styleFrom(
                foregroundColor: _accentColor,
                side: const BorderSide(color: _accentColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Оплата скоро',
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
    required this.initials,
    required this.icon,
    required this.gradientColors,
    required this.isFree,
    this.previewVariant = 0,
  });

  final String id;
  final String title;
  final String description;
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
    required this.onPhotoshootGenerated,
    required this.onOpenGallery,
  });

  final bool isActive;
  final ApiService apiService;
  final void Function(List<GeneratedImageItem> items) onPhotoshootGenerated;
  final VoidCallback onOpenGallery;

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
      description: 'Чистый студийный свет, мягкий нейтральный фон',
      initials: 'СП',
      icon: Icons.portrait_outlined,
      gradientColors: [Color(0xFFD8D4E8), Color(0xFFB8B0D4)],
      isFree: true,
      previewVariant: 0,
    ),
    _PhotoshootStyle(
      id: 'business_portrait',
      title: 'Деловой портрет',
      description: 'Строгий деловой образ для работы и соцсетей',
      initials: 'ДП',
      icon: Icons.business_center_outlined,
      gradientColors: [Color(0xFFB8C8DC), Color(0xFF8EA4BE)],
      isFree: true,
      previewVariant: 1,
    ),
    _PhotoshootStyle(
      id: 'home_portrait',
      title: 'Домашний портрет',
      description: 'Уютная домашняя атмосфера с тёплым светом',
      initials: 'ДМ',
      icon: Icons.home_outlined,
      gradientColors: [Color(0xFFF0E2D0), Color(0xFFD4B896)],
      isFree: true,
      previewVariant: 2,
    ),
    _PhotoshootStyle(
      id: 'premium_portrait',
      title: 'Премиум-портрет',
      description: 'Кинематографичный свет и изысканный фон',
      initials: 'ПР',
      icon: Icons.diamond_outlined,
      gradientColors: [Color(0xFFC8B0F0), Color(0xFF9070D8)],
      isFree: false,
      previewVariant: 3,
    ),
    _PhotoshootStyle(
      id: 'winter_photoshoot',
      title: 'Зимняя фотосессия',
      description: 'Снежная атмосфера и мягкие зимние оттенки',
      initials: 'ЗМ',
      icon: Icons.ac_unit,
      gradientColors: [Color(0xFFB8E4F8), Color(0xFF6CB8E8)],
      isFree: false,
      previewVariant: 1,
    ),
    _PhotoshootStyle(
      id: 'urban_portrait',
      title: 'Городской портрет',
      description: 'Городской фон, современный стиль и уличный свет',
      initials: 'ГР',
      icon: Icons.location_city_outlined,
      gradientColors: [Color(0xFFA8B8F0), Color(0xFF6878D0)],
      isFree: false,
      previewVariant: 0,
    ),
    _PhotoshootStyle(
      id: 'evening_look',
      title: 'Вечерний образ',
      description: 'Элегантный вечерний образ с мягким светом',
      initials: 'ВЧ',
      icon: Icons.nightlife_outlined,
      gradientColors: [Color(0xFF6A5098), Color(0xFF3A2868)],
      isFree: false,
      previewVariant: 2,
    ),
    _PhotoshootStyle(
      id: 'travel_portrait',
      title: 'Портрет в путешествии',
      description: 'Красивые локации и атмосфера отдыха',
      initials: 'ПТ',
      icon: Icons.flight_outlined,
      gradientColors: [Color(0xFFB0E8D8), Color(0xFF58B8A8)],
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

  void _openPhotoshootSheet(BuildContext context, _PhotoshootStyle style) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PhotoshootDetailSheet(
        style: style,
        apiService: widget.apiService,
        onShowMessage: (message) => _showSnackBar(context, message),
        onPhotoshootGenerated: widget.onPhotoshootGenerated,
        onOpenGallery: widget.onOpenGallery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                                  'Фотосессии',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Готовые фотосессии — выберите стиль, загрузите фото и получите 3 изображения.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed:
                                _isHelpDialogVisible ? null : _showHelp,
                            tooltip: 'Помощь',
                            icon: const Icon(Icons.help_outline),
                            color: AiImageGeneratorApp.textSecondary,
                            iconSize: 26,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
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
                          childAspectRatio: columns == 2 ? 0.58 : 0.72,
                        ),
                        itemCount: _photoshoots.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _CustomPhotoshootCatalogCard(
                              onAction: () =>
                                  _openCustomPhotoshootDialog(context),
                            );
                          }
                          final style = _photoshoots[index - 1];
                          return _PhotoshootCard(
                            style: style,
                            onAction: () =>
                                _openPhotoshootSheet(context, style),
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

class _CustomPhotoshootCatalogCard extends StatelessWidget {
  const _CustomPhotoshootCatalogCard({required this.onAction});

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
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
                      size: 72,
                      color: _accentColor.withValues(alpha: 0.12),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_note_outlined,
                        size: 28,
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Своя фотосессия',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    _PhotoshootMetaChip(
                      label: '3 фото',
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
                const SizedBox(height: 8),
                Text(
                  'Опишите образ своими словами',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
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
    required this.onAction,
  });

  final _PhotoshootStyle style;
  final VoidCallback onAction;

  static const _accentColor = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor =
        style.isFree ? const Color(0xFFE8F5E9) : const Color(0xFFEDE9FF);
    final badgeTextColor =
        style.isFree ? const Color(0xFF2E7D32) : _accentColor;
    final onDarkPreview = style.gradientColors.first.computeLuminance() < 0.45;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: style.isFree
            ? null
            : Border.all(
                color: _accentColor.withValues(alpha: 0.22),
                width: 1.2,
              ),
        boxShadow: [
          BoxShadow(
            color: style.isFree
                ? Colors.black.withValues(alpha: 0.06)
                : _accentColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!style.isFree)
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentColor.withValues(alpha: 0.55),
                    const Color(0xFF7C5CFF).withValues(alpha: 0.35),
                  ],
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
                      label: '3 фото',
                      backgroundColor: const Color(0xFFF0F2FF),
                      textColor: _accentColor,
                    ),
                    _PhotoshootMetaChip(
                      label: style.priceLabel,
                      backgroundColor: badgeColor,
                      textColor: badgeTextColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  style.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: style.isFree
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onAction,
                              borderRadius: BorderRadius.circular(12),
                              child: const Center(
                                child: Text(
                                  'Попробовать',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
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
                            'Оплата позже',
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
    required this.onShowMessage,
    required this.onPhotoshootGenerated,
    required this.onOpenGallery,
  });

  final _PhotoshootStyle style;
  final ApiService apiService;
  final void Function(String message) onShowMessage;
  final void Function(List<GeneratedImageItem> items) onPhotoshootGenerated;
  final VoidCallback onOpenGallery;

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

  static const _outcomes = [
    '3 изображения в одном стиле',
    'Мягкая обработка лица и света',
    'Результат появится в Галерее',
  ];

  static const _photoUploadTips = [
    'Лицо хорошо видно',
    'Фото не размытое',
    'Хорошее освещение',
    'Без сильной тени на лице',
    'Для некоторых образов лучше фото по пояс или в полный рост',
    'Чем лучше исходное фото, тем лучше результат',
  ];

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

  Future<void> _onSecondaryActionPressed() async {
    if (_isPreparingPhotoshoot) return;
    final selectedPhotoFile = _selectedPhotoFile;
    final hasSelectedPhoto = selectedPhotoFile != null;
    if (!hasSelectedPhoto) {
      widget.onShowMessage('Сначала выберите фото');
      return;
    }
    if (!widget.style.isFree) {
      widget.onShowMessage('Оплата будет добавлена позже');
      return;
    }
    setState(() => _isPreparingPhotoshoot = true);
    try {
      final result = await widget.apiService.generatePhotoshoot(
        styleId: widget.style.id,
        styleTitle: widget.style.title,
        photoFile: selectedPhotoFile,
      );
      if (!mounted) return;
      if (result.imageUrls.isEmpty) {
        widget.onShowMessage(
          'Не удалось подготовить фотосессию. Попробуйте позже.',
        );
        return;
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
    final laterLabel = style.isFree ? 'Подготовить позже' : 'Оплата позже';
    final onDarkPreview = style.gradientColors.first.computeLuminance() < 0.45;

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
                        child: Text(
                          style.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
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
                            label: '3 фото',
                            backgroundColor: const Color(0xFFF0F2FF),
                            textColor: _accentColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    style.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _PhotoshootPreview(
                      initials: style.initials,
                      icon: style.icon,
                      gradientColors: style.gradientColors,
                      onDark: onDarkPreview,
                      isFree: style.isFree,
                      previewVariant: style.previewVariant,
                      aspectRatio: 2.2,
                      showCatalogBadges: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PhotoshootResultExamplesSection(style: style),
                  const SizedBox(height: 16),
                  _PhotoshootPhotoTipsSection(tips: _photoUploadTips),
                  const SizedBox(height: 20),
                  Text(
                    'Загрузите своё фото, и приложение подготовит 3 изображения в выбранном стиле.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _isPickingPhoto ? null : _pickPhoto,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: _selectedPhotoBytes == null
                          ? Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE9FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isPickingPhoto
                                      ? const Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: _accentColor,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 30,
                                          color: _accentColor,
                                        ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _isPickingPhoto
                                      ? 'Подождите...'
                                      : 'Выберите своё фото',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Пока фото не отправляется на сервер',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: AspectRatio(
                                    aspectRatio: 1.2,
                                    child: Image.memory(
                                      _selectedPhotoBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Фото выбрано',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: _isPickingPhoto ? null : _pickPhoto,
                                  child: const Text('Выбрать другое фото'),
                                ),
                              ],
                            ),
                    ),
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
                        const SizedBox(height: 14),
                        ..._outcomes.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
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
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: AiImageGeneratorApp.textPrimary,
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
                  const SizedBox(height: 24),
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
                            'Понятно',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: style.isFree
                            ? SizedBox(
                                height: 48,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7C5CFF),
                                        Color(0xFF4A7CFF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _isPreparingPhotoshoot
                                          ? null
                                          : _onSecondaryActionPressed,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Center(
                                        child: _isPreparingPhotoshoot
                                            ? const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.3,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    'Подождите...',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                laterLabel,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: _isPreparingPhotoshoot
                                    ? null
                                    : _onSecondaryActionPressed,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _accentColor,
                                  side: const BorderSide(color: _accentColor),
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isPreparingPhotoshoot
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.3,
                                        ),
                                      )
                                    : Text(
                                  laterLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
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
        ),
      ),
    );
  }
}

class _PhotoshootResultExamplesSection extends StatelessWidget {
  const _PhotoshootResultExamplesSection({required this.style});

  final _PhotoshootStyle style;

  static const _labels = ['Фото 1', 'Фото 2', 'Фото 3'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Пример результата',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Здесь позже появятся настоящие примеры. Сейчас — заглушки.',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(3, (index) {
              final colorA = style.gradientColors.first;
              final colorB = style.gradientColors.length > 1
                  ? style.gradientColors[1]
                  : style.gradientColors.first;
              final blend = index == 0
                  ? [colorA, colorB]
                  : index == 1
                      ? [Color.lerp(colorA, colorB, 0.35)!, colorB]
                      : [colorA, Color.lerp(colorA, colorB, 0.65)!];

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                  child: _PhotoshootResultPlaceholder(
                    label: _labels[index],
                    gradientColors: blend,
                    icon: style.icon,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PhotoshootResultPlaceholder extends StatelessWidget {
  const _PhotoshootResultPlaceholder({
    required this.label,
    required this.gradientColors,
    required this.icon,
  });

  final String label;
  final List<Color> gradientColors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final onDark = gradientColors.first.computeLuminance() < 0.45;
    final iconColor = onDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 0.78,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 4,
                  bottom: 2,
                  child: Icon(icon, size: 28, color: iconColor),
                ),
                Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 22,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _PhotoshootPhotoTipsSection extends StatelessWidget {
  const _PhotoshootPhotoTipsSection({required this.tips});

  final List<String> tips;

  static const _accentColor = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SoftCard(
      backgroundColor: const Color(0xFFF3F6FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tips_and_updates_outlined,
                  color: _accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Какое фото лучше загрузить',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map(
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
                      style: theme.textTheme.bodyMedium?.copyWith(
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
    this.aspectRatio = 16 / 9,
  });

  final String initials;
  final IconData icon;
  final List<Color> gradientColors;
  final bool onDark;
  final bool isFree;
  final int previewVariant;
  final bool showCatalogBadges;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final iconColor = onDark ? Colors.white.withValues(alpha: 0.9) : Colors.white;
    final initialsBg = onDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.35);
    final initialsText = onDark ? Colors.white : AiImageGeneratorApp.textPrimary;
    final watermarkColor = onDark
        ? Colors.white.withValues(alpha: 0.75)
        : Colors.black.withValues(alpha: 0.45);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
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
            Positioned(
              right: -12,
              bottom: -16,
              child: Icon(
                icon,
                size: 88,
                color: (onDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.08),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: initialsBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: initialsText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(icon, size: 28, color: iconColor),
                ],
              ),
            ),
            if (showCatalogBadges)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: onDark ? 0.28 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Пример',
                    style: TextStyle(
                      color: watermarkColor,
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
      ),
    );
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
    this.onResetOnboarding,
  });

  final AuthService authService;
  final ApiService apiService;
  final VoidCallback onAuthChanged;
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
    required this.onImageGenerated,
    required this.onOpenGallery,
  });

  final bool isActive;
  final ApiService apiService;
  final ValueChanged<GeneratedImageItem> onImageGenerated;
  final VoidCallback onOpenGallery;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  static const _quickIdeas = [
    'Киберпанк-кот',
    'Уютный дом',
    'Премиум-реклама',
    'Аниме-портрет',
    'Город будущего',
  ];

  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _showNoGenerationsWarning = false;
  bool _showGenerationErrorState = false;
  bool _isHelpDialogVisible = false;
  bool _isPickingPhoto = false;
  Uint8List? _selectedPhotoBytes;
  GenerateImageResponse? _lastResponse;

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
      setState(() => _selectedPhotoBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Не удалось выбрать фото. Попробуйте ещё раз.');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  void _clearReferencePhoto() {
    setState(() => _selectedPhotoBytes = null);
  }

  Future<void> _onGenerate() async {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Сначала опишите изображение');
      return;
    }

    if (_selectedPhotoBytes != null) {
      _showSnackBar(
        'Создание по фото будет добавлено позже. '
        'Сейчас изображение создаётся по описанию.',
      );
    }

    setState(() {
      _isLoading = true;
      _lastResponse = null;
      _showNoGenerationsWarning = false;
      _showGenerationErrorState = false;
    });

    try {
      final response = await widget.apiService.generateImage(text);
      if (!mounted) return;
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
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _handleError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _handleError(String message) {
    if (message == 'Prompt cannot be empty') {
      _showSnackBar('Сначала опишите изображение');
    } else if (message == 'No available generations') {
      setState(() => _showNoGenerationsWarning = true);
      _showSnackBar(
        'Генерации закончились. Купите пакет, чтобы продолжить.',
      );
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
                  IconButton(
                    onPressed: _isHelpDialogVisible ? null : _showHelp,
                    tooltip: 'Помощь',
                    icon: const Icon(Icons.help_outline),
                    color: AiImageGeneratorApp.textSecondary,
                    iconSize: 26,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _StatusCard(response: _lastResponse),
              const SizedBox(height: 20),
              _InputCard(controller: _descriptionController),
              const SizedBox(height: 20),
              _CreateReferencePhotoCard(
                photoBytes: _selectedPhotoBytes,
                isPickingPhoto: _isPickingPhoto,
                isBusy: _isLoading,
                onPickPhoto: _pickReferencePhoto,
                onClearPhoto: _clearReferencePhoto,
              ),
              const SizedBox(height: 24),
              Text('Попробуйте идею', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickIdeas
                    .map(
                      (idea) => ActionChip(
                        label: Text(idea),
                        onPressed: _isLoading ? null : () => _applyQuickIdea(idea),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              const _CreateTipsCard(),
              const SizedBox(height: 24),
              _GenerateButton(
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _onGenerate,
              ),
              if (_showNoGenerationsWarning) ...[
                const SizedBox(height: 20),
                const _NoGenerationsWarningCard(),
              ],
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
            'Позже здесь можно будет создать одно изображение '
            'на основе вашего фото и описания.',
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
          const SizedBox(height: 4),
          Text(
            'Сейчас создание работает по описанию. '
            'Генерация по фото будет добавлена позже.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: AiImageGeneratorApp.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateTipsCard extends StatelessWidget {
  const _CreateTipsCard();

  static const _accentColor = Color(0xFF5B6CFF);

  static const _tips = [
    'Опишите человека, предмет или сцену',
    'Добавьте стиль: реализм, кино, портрет, реклама',
    'Укажите настроение: уютно, премиально, ярко, спокойно',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          const SizedBox(height: 16),
          ..._tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
                      tip,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AiImageGeneratorApp.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAEF)),
            ),
            child: Text(
              'Например: Женский деловой портрет в светлой студии, реализм, мягкий свет',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: AiImageGeneratorApp.textSecondary,
                height: 1.45,
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
              'Генерации обновлены',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AiImageGeneratorApp.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Бесплатных осталось: ${response!.remainingFreeGenerations ?? 0}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Купленных осталось: ${response!.remainingPaidCredits ?? 0}',
              style: theme.textTheme.bodyMedium,
            ),
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

class _NoGenerationsWarningCard extends StatelessWidget {
  const _NoGenerationsWarningCard();

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
              Icon(Icons.info_outline, size: 20, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Text(
                'Генерации закончились',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF9A5B00),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Купите пакет генераций, чтобы продолжить создавать изображения',
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
  const _InputCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: 'Например: портрет в деловом стиле',
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
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                  : const Text(
                      'Создать изображение',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
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
