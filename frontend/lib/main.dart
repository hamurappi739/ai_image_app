import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/generated_image_item.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

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
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

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

  void _clearGallery() {
    setState(() => _generatedImages.clear());
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      CreateScreen(
        apiService: _apiService,
        onImageGenerated: _onImageGenerated,
        onOpenGallery: _goToGalleryTab,
      ),
      const PhotoshootsScreen(),
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

class _GenerationPack {
  const _GenerationPack({
    required this.title,
    required this.price,
    required this.imageCount,
    required this.description,
    this.badge,
    this.featured = false,
  });

  final String title;
  final String price;
  final int imageCount;
  final String description;
  final String? badge;
  final bool featured;
}

class PacksScreen extends StatelessWidget {
  const PacksScreen({super.key});

  static const _breakpointMedium = 560.0;
  static const _breakpointWide = 900.0;

  static const _packages = <_GenerationPack>[
    _GenerationPack(
      title: 'Стартовый',
      price: '199 ₽',
      imageCount: 25,
      description: 'Для первых идей и быстрых проб',
    ),
    _GenerationPack(
      title: 'Авторский',
      price: '499 ₽',
      imageCount: 100,
      description: 'Оптимальный выбор для регулярного создания',
      badge: 'Популярный',
      featured: true,
    ),
    _GenerationPack(
      title: 'Профи',
      price: '1199 ₽',
      imageCount: 250,
      description: 'Максимум изображений по лучшей цене',
      badge: 'Выгодно',
    ),
  ];

  static int _columnCount(double width) {
    if (width >= _breakpointWide) return 3;
    if (width >= _breakpointMedium) return 2;
    return 1;
  }

  static double _aspectRatio(int columns) {
    switch (columns) {
      case 3:
        return 0.58;
      case 2:
        return 0.68;
      default:
        return 0.82;
    }
  }

  void _showPaymentsLaterSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Оплата будет добавлена позже'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _columnCount(constraints.maxWidth);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Пакеты генераций',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Покупайте пакеты, когда нужно больше изображений',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      _SoftCard(
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
                                    Icons.auto_awesome_outlined,
                                    color: Color(0xFF5B6CFF),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Всё просто',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '1 генерация = 1 изображение. Выберите пакет и создавайте изображения, когда захотите.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Оплата будет подключена позже.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: _aspectRatio(columns),
                        ),
                        itemCount: _packages.length,
                        itemBuilder: (context, index) {
                          final pack = _packages[index];
                          return _GenerationPackCard(
                            pack: pack,
                            onComingSoon: () =>
                                _showPaymentsLaterSnackBar(context),
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

class _GenerationPackCard extends StatelessWidget {
  const _GenerationPackCard({
    required this.pack,
    required this.onComingSoon,
  });

  final _GenerationPack pack;
  final VoidCallback onComingSoon;

  static const _accentColor = Color(0xFF5B6CFF);
  static const _featuredGradient = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: pack.featured
            ? Border.all(
                width: 2,
                color: const Color(0xFF6B5CFF),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: (pack.featured ? _accentColor : Colors.black)
                .withValues(alpha: pack.featured ? 0.12 : 0.05),
            blurRadius: pack.featured ? 28 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pack.featured)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(gradient: _featuredGradient),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    pack.badge ?? 'Популярный',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          pack.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                          ),
                        ),
                      ),
                      if (pack.badge != null && !pack.featured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            pack.badge!,
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${pack.imageCount}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AiImageGeneratorApp.textPrimary,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'изображений',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AiImageGeneratorApp.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pack.price,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _accentColor,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pack.description,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: onComingSoon,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pack.featured
                            ? _accentColor
                            : AiImageGeneratorApp.textSecondary,
                        side: BorderSide(
                          color: pack.featured
                              ? _accentColor.withValues(alpha: 0.5)
                              : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Скоро',
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

class _PhotoshootStyle {
  const _PhotoshootStyle({
    required this.title,
    required this.description,
    required this.initials,
    required this.icon,
    required this.gradientColors,
    required this.isFree,
  });

  final String title;
  final String description;
  final String initials;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isFree;
}

class PhotoshootsScreen extends StatelessWidget {
  const PhotoshootsScreen({super.key});

  static const _gridBreakpoint = 560.0;

  static const _photoshoots = <_PhotoshootStyle>[
    _PhotoshootStyle(
      title: 'Студийный портрет',
      description: 'Чистый студийный свет и мягкий фон',
      initials: 'СП',
      icon: Icons.portrait_outlined,
      gradientColors: [Color(0xFFD8D4E8), Color(0xFFB8B0D4)],
      isFree: true,
    ),
    _PhotoshootStyle(
      title: 'Деловой портрет',
      description: 'Профессиональный портрет для работы и соцсетей',
      initials: 'ДП',
      icon: Icons.business_center_outlined,
      gradientColors: [Color(0xFFB8C8DC), Color(0xFF8EA4BE)],
      isFree: true,
    ),
    _PhotoshootStyle(
      title: 'Домашний портрет',
      description: 'Тёплая домашняя атмосфера с естественным светом',
      initials: 'ДМ',
      icon: Icons.home_outlined,
      gradientColors: [Color(0xFFF0E2D0), Color(0xFFD4B896)],
      isFree: true,
    ),
    _PhotoshootStyle(
      title: 'Премиум-портрет',
      description: 'Элегантный образ с кинематографичным светом',
      initials: 'ПР',
      icon: Icons.diamond_outlined,
      gradientColors: [Color(0xFFC8B0F0), Color(0xFF9070D8)],
      isFree: false,
    ),
    _PhotoshootStyle(
      title: 'Зимняя фотосессия',
      description: 'Снежная атмосфера с мягкими зимними оттенками',
      initials: 'ЗМ',
      icon: Icons.ac_unit,
      gradientColors: [Color(0xFFB8E4F8), Color(0xFF6CB8E8)],
      isFree: false,
    ),
    _PhotoshootStyle(
      title: 'Городской портрет',
      description: 'Современный городской фон и стильный свет',
      initials: 'ГР',
      icon: Icons.location_city_outlined,
      gradientColors: [Color(0xFFA8B8F0), Color(0xFF6878D0)],
      isFree: false,
    ),
    _PhotoshootStyle(
      title: 'Вечерний образ',
      description: 'Элегантный вечерний образ с премиальным фоном',
      initials: 'ВЧ',
      icon: Icons.nightlife_outlined,
      gradientColors: [Color(0xFF6A5098), Color(0xFF3A2868)],
      isFree: false,
    ),
    _PhotoshootStyle(
      title: 'Портрет в путешествии',
      description: 'Портреты в красивых локациях в стиле отпуска',
      initials: 'ПТ',
      icon: Icons.flight_outlined,
      gradientColors: [Color(0xFFB0E8D8), Color(0xFF58B8A8)],
      isFree: false,
    ),
  ];

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        onShowMessage: (message) {
          Navigator.of(sheetContext).pop();
          _showSnackBar(context, message);
        },
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
                      Text('Фотосессии', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                        'Выберите готовый стиль. Позже вы сможете загрузить фото и получить 3 изображения в одной теме.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: columns == 2 ? 0.62 : 0.78,
                        ),
                        itemCount: _photoshoots.length,
                        itemBuilder: (context, index) {
                          final style = _photoshoots[index];
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
    final badgeLabel = style.isFree ? 'Бесплатно' : '100 ₽';
    final badgeColor =
        style.isFree ? const Color(0xFFE8F5E9) : const Color(0xFFEDE9FF);
    final badgeTextColor =
        style.isFree ? const Color(0xFF2E7D32) : _accentColor;
    final onDarkPreview = style.gradientColors.first.computeLuminance() < 0.45;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhotoshootPreview(
            initials: style.initials,
            icon: style.icon,
            gradientColors: style.gradientColors,
            onDark: onDarkPreview,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        style.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '3 фото в одном стиле',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AiImageGeneratorApp.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  style.description,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
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
                            side: const BorderSide(color: _accentColor),
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

class _PhotoshootDetailSheet extends StatelessWidget {
  const _PhotoshootDetailSheet({
    required this.style,
    required this.onShowMessage,
  });

  final _PhotoshootStyle style;
  final void Function(String message) onShowMessage;

  static const _accentColor = Color(0xFF5B6CFF);

  static const _outcomes = [
    '3 изображения в одном стиле',
    'Мягкая обработка лица и света',
    'Результат появится в Галерее',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeLabel = style.isFree ? 'Бесплатно' : '100 ₽';
    final badgeColor =
        style.isFree ? const Color(0xFFE8F5E9) : const Color(0xFFEDE9FF);
    final badgeTextColor =
        style.isFree ? const Color(0xFF2E7D32) : _accentColor;
    final laterLabel =
        style.isFree ? 'Попробовать позже' : 'Оплата позже';
    final laterMessage = style.isFree
        ? 'Загрузка фото будет добавлена позже'
        : 'Оплата будет добавлена позже';

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
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                          badgeLabel,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Загрузите своё фото, и приложение подготовит 3 изображения в выбранном стиле.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 30,
                            color: _accentColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Загрузка фото будет добавлена позже',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Сейчас это демо-экран без отправки файлов',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
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
                                      onTap: () =>
                                          onShowMessage(laterMessage),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Center(
                                        child: Text(
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
                                onPressed: () =>
                                    onShowMessage(laterMessage),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _accentColor,
                                  side: const BorderSide(color: _accentColor),
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
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

class _PhotoshootPreview extends StatelessWidget {
  const _PhotoshootPreview({
    required this.initials,
    required this.icon,
    required this.gradientColors,
    required this.onDark,
  });

  final String initials;
  final IconData icon;
  final List<Color> gradientColors;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final iconColor = onDark ? Colors.white.withValues(alpha: 0.9) : Colors.white;
    final initialsBg = onDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.35);
    final initialsText = onDark ? Colors.white : AiImageGeneratorApp.textPrimary;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
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
          ],
        ),
      ),
    );
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
    if (images.isEmpty) {
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
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return _GalleryImageCard(item: images[index]);
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

  final GeneratedImageItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
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
            ),
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
    required this.apiService,
    required this.onAuthChanged,
  });

  final AuthService authService;
  final ApiService apiService;
  final VoidCallback onAuthChanged;

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
    required this.apiService,
    required this.onImageGenerated,
    required this.onOpenGallery,
  });

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

  bool _isLoading = false;
  bool _showNoGenerationsWarning = false;
  bool _showGenerationErrorState = false;
  GenerateImageResponse? _lastResponse;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onGenerate() async {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Сначала опишите изображение');
      return;
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
              Text('AI Фотогенератор', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Создавайте изображения по вашему описанию',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _StatusCard(response: _lastResponse),
              const SizedBox(height: 20),
              _InputCard(controller: _descriptionController),
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
  const _SoftCard({required this.child, this.borderColor});

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
