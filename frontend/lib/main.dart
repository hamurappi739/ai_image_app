import 'package:flutter/material.dart';

import 'services/api_service.dart';

void main() {
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

  int _selectedIndex = 0;

  static const _screens = <Widget>[
    CreateScreen(),
    PhotoshootsScreen(),
    GalleryScreen(),
    PacksScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
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

  void _onPhotoshootAction(BuildContext context, _PhotoshootStyle style) {
    if (style.isFree) {
      _showSnackBar(
        context,
        'Генерация фотосессий будет добавлена позже',
      );
    } else {
      _showSnackBar(context, 'Оплата фотосессий будет добавлена позже');
    }
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
                                _onPhotoshootAction(context, style),
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

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

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
                    'Здесь появятся ваши созданные изображения',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  _SoftCard(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            size: 36,
                            color: _accentColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Пока нет изображений',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Создайте первое изображение или фотосессию, чтобы увидеть его здесь.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Изображения будут сохраняться здесь после добавления аккаунтов и хранения.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _accentColor = Color(0xFF5B6CFF);

  static const _comingFeatures = [
    (icon: Icons.image_outlined, label: 'Ваши созданные изображения'),
    (icon: Icons.photo_camera_outlined, label: 'История фотосессий'),
    (icon: Icons.shopping_bag_outlined, label: 'Купленные пакеты генераций'),
    (icon: Icons.settings_outlined, label: 'Настройки приложения'),
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
                  Text('Профиль', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    'Аккаунт и настройки будут добавлены позже',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  _SoftCard(
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
                                  colors: [
                                    Color(0xFF7C5CFF),
                                    Color(0xFF4A7CFF),
                                  ],
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
                                    'Вход будет доступен позже',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'После входа ваши изображения, фотосессии и пакеты генераций будут сохраняться в аккаунте.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                                'Секретные ключи и платежные данные не хранятся в приложении. Все важные операции будут выполняться на сервере.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
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
                          onTap: () => _showSnackBar(
                            context,
                            'Вход будет добавлен позже',
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: const Center(
                            child: Text(
                              'Войти позже',
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
                      onPressed: () => _showSnackBar(
                        context,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
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
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  static const _quickIdeas = [
    'Cyberpunk cat',
    'Cozy cabin',
    'Luxury product photo',
    'Anime portrait',
    'Futuristic city',
  ];

  final _apiService = ApiService();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _showNoGenerationsWarning = false;
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
    });

    try {
      final response = await _apiService.generateImage(text);
      if (!mounted) return;
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
      _showSnackBar('Что-то пошло не так. Попробуйте ещё раз.');
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
              const SizedBox(height: 24),
              _GenerateButton(
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _onGenerate,
              ),
              if (_showNoGenerationsWarning) ...[
                const SizedBox(height: 20),
                const _NoGenerationsWarningCard(),
              ],
              if (_lastResponse != null) ...[
                const SizedBox(height: 32),
                _ResultSection(response: _lastResponse!),
              ],
            ],
          ),
        ),
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

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.response});

  final GenerateImageResponse response;

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
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF0F2F8),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Превью изображения недоступно',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
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
      ],
    );
  }
}
