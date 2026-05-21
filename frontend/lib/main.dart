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
      title: 'AI Image Generator',
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
    _PlaceholderScreen(
      title: 'History',
      message: 'Your generated images will appear here',
    ),
    PacksScreen(),
    _PlaceholderScreen(
      title: 'Settings',
      message: 'App settings will be added here',
    ),
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
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_camera),
            label: 'Photoshoots',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Packs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class PacksScreen extends StatelessWidget {
  const PacksScreen({super.key});

  static const _packages = [
    (
      title: 'Starter',
      generations: 25,
      price: '199 ₽',
      description: 'Best for trying ideas',
      popular: false,
    ),
    (
      title: 'Creator',
      generations: 100,
      price: '499 ₽',
      description: 'Most popular',
      popular: true,
    ),
    (
      title: 'Pro',
      generations: 250,
      price: '1199 ₽',
      description: 'Best value',
      popular: false,
    ),
  ];

  void _showPaymentsLaterSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payments will be added later'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Packs', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Buy generation packs when you need more images',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available generations',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Free generations: Coming soon',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paid generations: Coming soon',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Balance will be synced after authentication is added.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text('Generation packs', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              ..._packages.map(
                (package) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _GenerationPackCard(
                    title: package.title,
                    generations: package.generations,
                    price: package.price,
                    description: package.description,
                    popular: package.popular,
                    onComingSoon: () => _showPaymentsLaterSnackBar(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenerationPackCard extends StatelessWidget {
  const _GenerationPackCard({
    required this.title,
    required this.generations,
    required this.price,
    required this.description,
    required this.popular,
    required this.onComingSoon,
  });

  final String title;
  final int generations;
  final String price;
  final String description;
  final bool popular;
  final VoidCallback onComingSoon;

  static const _accentColor = Color(0xFF5B6CFF);

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
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
              if (popular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C5CFF), Color(0xFF4A7CFF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$generations generations',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AiImageGeneratorApp.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 22,
              color: _accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: onComingSoon,
              style: OutlinedButton.styleFrom(
                foregroundColor: AiImageGeneratorApp.textSecondary,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Coming soon',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoshootsScreen extends StatelessWidget {
  const PhotoshootsScreen({super.key});

  static const _photoshoots = [
    (
      title: 'Studio Portrait',
      description: 'Clean studio look with soft light',
      isFree: true,
    ),
    (
      title: 'Business Portrait',
      description: 'Professional portrait for work and social media',
      isFree: true,
    ),
    (
      title: 'Cozy Home Portrait',
      description: 'Warm home atmosphere with natural light',
      isFree: true,
    ),
    (
      title: 'Luxury Portrait',
      description: 'Premium elegant look with cinematic lighting',
      isFree: false,
    ),
    (
      title: 'Winter Photoshoot',
      description: 'Snowy outdoor atmosphere with soft winter colors',
      isFree: false,
    ),
    (
      title: 'City Portrait',
      description: 'Modern city background with stylish lighting',
      isFree: false,
    ),
    (
      title: 'Evening Dress',
      description: 'Elegant evening look with a premium background',
      isFree: false,
    ),
    (
      title: 'Travel Portrait',
      description: 'Vacation-style portraits in beautiful locations',
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
                  Text('Photoshoots', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    'Choose a ready-made style and get a set of images',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  _SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simple photo sets',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Pick a style, upload your photo later, and get 3 images in one theme.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Payments and uploads will be added later.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._photoshoots.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PhotoshootCard(
                        title: item.title,
                        description: item.description,
                        isFree: item.isFree,
                        onAction: () {
                          if (item.isFree) {
                            _showSnackBar(
                              context,
                              'Photoshoot generation will be added later',
                            );
                          } else {
                            _showSnackBar(
                              context,
                              'Payment for photoshoots will be added later',
                            );
                          }
                        },
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

class _PhotoshootCard extends StatelessWidget {
  const _PhotoshootCard({
    required this.title,
    required this.description,
    required this.isFree,
    required this.onAction,
  });

  final String title;
  final String description;
  final bool isFree;
  final VoidCallback onAction;

  static const _accentColor = Color(0xFF5B6CFF);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeLabel = isFree ? 'Free' : '100 ₽';
    final badgeColor = isFree
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFEDE9FF);
    final badgeTextColor =
        isFree ? const Color(0xFF2E7D32) : _accentColor;

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '3 photos',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AiImageGeneratorApp.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: isFree
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
                            'Try free',
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
                    onPressed: onAction,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accentColor,
                      side: const BorderSide(color: _accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Pay later',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AiImageGeneratorApp.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(message, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
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
      _showSnackBar('Describe your image first');
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
      _showSnackBar('Describe your image first');
    } else if (message == 'No available generations') {
      setState(() => _showNoGenerationsWarning = true);
      _showSnackBar('No generations left. Please buy a pack.');
    } else {
      _showSnackBar('Something went wrong. Please try again.');
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
              Text('AI Image Generator', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Create images from your ideas',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _StatusCard(response: _lastResponse),
              const SizedBox(height: 20),
              _InputCard(controller: _descriptionController),
              const SizedBox(height: 24),
              Text('Try an idea', style: theme.textTheme.titleMedium),
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
          Text('Generation status', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          if (response == null)
            Text('Ready to create', style: theme.textTheme.bodyMedium)
          else if (response!.creditConsumed) ...[
            Text(
              'Generations updated',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AiImageGeneratorApp.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Free left: ${response!.remainingFreeGenerations ?? 0}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Paid generations left: ${response!.remainingPaidCredits ?? 0}',
              style: theme.textTheme.bodyMedium,
            ),
          ] else
            Text(
              'Demo mode: generations are not consumed',
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
                'No generations left',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF9A5B00),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Buy a generation pack to continue creating images',
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
          hintText: 'Describe your image...',
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
                      'Generate image',
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
                    'Image preview unavailable',
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
          'Generated from: ${response.prompt}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AiImageGeneratorApp.textPrimary,
          ),
        ),
      ],
    );
  }
}
