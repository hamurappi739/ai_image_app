import 'package:flutter/material.dart';

import '../models/gallery_display_item.dart';
import '../models/generated_image_item.dart';
import '../utils/gallery_item_key.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/gallery_photoshoot_triplet_preview.dart';
import '../widgets/gallery_result_image.dart';
import '../widgets/gallery_viewer.dart';

const _scaffoldBackground = Color(0xFFF7F8FC);
const _textPrimary = Color(0xFF1A1D26);
const _textSecondary = Color(0xFF6B7280);
const _accentColor = Color(0xFF5B6CFF);

const _gallerySubtitle =
    'Здесь сохраняются созданные фото и фотосессии.';

enum GallerySuccessKind { photo, photoshoot }

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({
    super.key,
    required this.images,
    required this.hiddenImageKeys,
    required this.hiddenPhotoshootIds,
    required this.onHideImage,
    required this.onHidePhotoshoot,
    required this.onOpenTemplates,
    required this.onOpenPhotoshoots,
    required this.onOpenBuy,
    required this.onClearGallery,
    required this.onRetry,
    this.isLoading = false,
    this.loadFailed = false,
    this.successKind,
    this.highlightItemKey,
    this.onDismissSuccess,
  });

  final List<GeneratedImageItem> images;
  final Set<String> hiddenImageKeys;
  final Set<String> hiddenPhotoshootIds;
  final ValueChanged<String> onHideImage;
  final ValueChanged<String> onHidePhotoshoot;
  final VoidCallback onOpenTemplates;
  final VoidCallback onOpenPhotoshoots;
  final VoidCallback onOpenBuy;
  final VoidCallback onClearGallery;
  final VoidCallback onRetry;
  final bool isLoading;
  final bool loadFailed;
  final GallerySuccessKind? successKind;
  final String? highlightItemKey;
  final VoidCallback? onDismissSuccess;

  static bool _isHighlightedItem(
    GalleryDisplayItem item,
    String? highlightItemKey,
  ) {
    if (highlightItemKey == null || highlightItemKey.isEmpty) return false;
    if (item.isPhotoshootGroup) {
      return item.photoshootId == highlightItemKey;
    }
    return item.hideKey == highlightItemKey;
  }

  void _onClearPressed(BuildContext context) {
    onClearGallery();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Готовые фото очищены на этом устройстве'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleImages = filterVisibleGalleryImages(
      images,
      hiddenImageKeys: hiddenImageKeys,
      hiddenPhotoshootIds: hiddenPhotoshootIds,
    );
    final displayItems = groupGalleryItems(visibleImages);

    if (isLoading && displayItems.isEmpty) {
      return const _GalleryLoadingState();
    }

    if (loadFailed && displayItems.isEmpty) {
      return _GalleryErrorState(onRetry: onRetry);
    }

    if (displayItems.isEmpty) {
      return _GalleryEmptyState(
        onOpenTemplates: onOpenTemplates,
        onOpenPhotoshoots: onOpenPhotoshoots,
        onOpenBuy: onOpenBuy,
      );
    }

    return Scaffold(
      backgroundColor: _scaffoldBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppScreenHeader(
                    title: 'Готовые фото',
                    subtitle: _gallerySubtitle,
                  ),
                  if (successKind != null) ...[
                    const SizedBox(height: 12),
                    _GallerySuccessBanner(
                      kind: successKind!,
                      onDismiss: onDismissSuccess,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Создать ещё',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _GalleryQuickActions(
                    onOpenTemplates: onOpenTemplates,
                    onOpenPhotoshoots: onOpenPhotoshoots,
                    onOpenBuy: onOpenBuy,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _onClearPressed(context),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text(
                        'Очистить',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ),
                  ..._GalleryChronologicalList.build(
                    displayItems: displayItems,
                    highlightItemKey: highlightItemKey,
                    onHideImage: onHideImage,
                    onHidePhotoshoot: onHidePhotoshoot,
                    isHighlightedItem: _isHighlightedItem,
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

class _GalleryChronologicalList {
  _GalleryChronologicalList._();

  static List<Widget> build({
    required List<GalleryDisplayItem> displayItems,
    required String? highlightItemKey,
    required ValueChanged<String> onHideImage,
    required ValueChanged<String> onHidePhotoshoot,
    required bool Function(GalleryDisplayItem item, String? highlightItemKey)
        isHighlightedItem,
  }) {
    final widgets = <Widget>[const SizedBox(height: 8)];
    bool? previousWasPhotoshoot;

    for (var index = 0; index < displayItems.length; index++) {
      final item = displayItems[index];
      final isPhotoshoot = item.isPhotoshootGroup;

      if (previousWasPhotoshoot != isPhotoshoot) {
        if (widgets.length > 1) {
          widgets.add(const SizedBox(height: 24));
        }
        widgets.add(
          _GallerySectionHeader(
            title: isPhotoshoot ? 'Фотосессии' : 'Одиночные фото',
            subtitle: isPhotoshoot
                ? 'Серии по 3 фото в одном стиле.'
                : 'Фото, созданные по шаблону или своей идее.',
          ),
        );
        widgets.add(const SizedBox(height: 12));
        previousWasPhotoshoot = isPhotoshoot;
      } else if (index > 0) {
        widgets.add(const SizedBox(height: 12));
      }

      if (isPhotoshoot) {
        widgets.add(
          _GalleryPhotoshootCard(
            item: item,
            isNew: isHighlightedItem(item, highlightItemKey),
            onHidePhotoshoot: onHidePhotoshoot,
          ),
        );
      } else {
        widgets.add(
          _GallerySinglePhotoCard(
            item: item,
            isNew: isHighlightedItem(item, highlightItemKey),
            onHideImage: onHideImage,
          ),
        );
      }
    }

    return widgets;
  }
}

class _GallerySectionHeader extends StatelessWidget {
  const _GallerySectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            height: 1.35,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GalleryQuickActions extends StatelessWidget {
  const _GalleryQuickActions({
    required this.onOpenTemplates,
    required this.onOpenPhotoshoots,
    required this.onOpenBuy,
  });

  final VoidCallback onOpenTemplates;
  final VoidCallback onOpenPhotoshoots;
  final VoidCallback onOpenBuy;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _GalleryActionCard(
        icon: Icons.dashboard_customize_outlined,
        title: 'Создать фото',
        subtitle: 'По шаблону или своей идее',
        onTap: onOpenTemplates,
      ),
      _GalleryActionCard(
        icon: Icons.photo_camera_outlined,
        title: 'Сделать фотосессию',
        subtitle: '3 фото в одном стиле',
        onTap: onOpenPhotoshoots,
      ),
      _GalleryActionCard(
        icon: Icons.shopping_bag_outlined,
        title: 'Купить изображения',
        subtitle: 'Пополнить баланс',
        onTap: onOpenBuy,
      ),
    ];

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) => SizedBox(
          width: 168,
          height: 108,
          child: cards[index],
        ),
      ),
    );
  }
}

class _GalleryActionCard extends StatelessWidget {
  const _GalleryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAEF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: _accentColor),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.25,
                      color: _textSecondary,
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

class _GalleryLoadingState extends StatelessWidget {
  const _GalleryLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _scaffoldBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppScreenHeader(
                    title: 'Готовые фото',
                    subtitle: _gallerySubtitle,
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _accentColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Загружаем готовые фото…',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            color: _textSecondary,
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

class _GalleryErrorState extends StatelessWidget {
  const _GalleryErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _scaffoldBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppScreenHeader(
                    title: 'Готовые фото',
                    subtitle: _gallerySubtitle,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: _accentColor.withValues(alpha: 0.75),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Не удалось загрузить готовые фото. '
                          'Попробуйте ещё раз.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: onRetry,
                            style: FilledButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Повторить',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
        ),
      ),
    );
  }
}

class _GallerySuccessBanner extends StatelessWidget {
  const _GallerySuccessBanner({
    required this.kind,
    this.onDismiss,
  });

  final GallerySuccessKind kind;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (kind) {
      GallerySuccessKind.photo => 'Готово! Фото сохранено.',
      GallerySuccessKind.photoshoot => 'Фотосессия готова и сохранена.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FDF4), Color(0xFFE8F5EE)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8E6CF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 22, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A5C38),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Сохранено в готовых фото',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF3D6B52),
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 20),
              color: const Color(0xFF6B7280),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}

class _GalleryEmptyState extends StatelessWidget {
  const _GalleryEmptyState({
    required this.onOpenTemplates,
    required this.onOpenPhotoshoots,
    required this.onOpenBuy,
  });

  final VoidCallback onOpenTemplates;
  final VoidCallback onOpenPhotoshoots;
  final VoidCallback onOpenBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _scaffoldBackground,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppScreenHeader(
                    title: 'Готовые фото',
                    subtitle: _gallerySubtitle,
                  ),
                  const SizedBox(height: 16),
                  _GalleryQuickActions(
                    onOpenTemplates: onOpenTemplates,
                    onOpenPhotoshoots: onOpenPhotoshoots,
                    onOpenBuy: onOpenBuy,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE8EAEF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const _GalleryEmptyPlaceholder(),
                        const SizedBox(height: 18),
                        Text(
                          'Пока здесь пусто',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Создайте первое фото по шаблону '
                          'или сделайте фотосессию.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            height: 1.45,
                            color: _textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 50,
                          width: double.infinity,
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
                                onTap: onOpenTemplates,
                                borderRadius: BorderRadius.circular(14),
                                child: const Center(
                                  child: Text(
                                    'Создать фото',
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
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: onOpenPhotoshoots,
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
                              'Сделать фотосессию',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
        ),
      ),
    );
  }
}

class _GalleryEmptyPlaceholder extends StatelessWidget {
  const _GalleryEmptyPlaceholder();

  static const _colors = [
    [Color(0xFFEDE9FF), Color(0xFFD4CBFF)],
    [Color(0xFFE8EEFC), Color(0xFFC9D8F5)],
    [Color(0xFFF5E8FF), Color(0xFFE0C4F5)],
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFFF7F8FC),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _colors[i],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: _accentColor.withValues(alpha: 0.35),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GalleryPhotoshootCard extends StatelessWidget {
  const _GalleryPhotoshootCard({
    required this.item,
    required this.onHidePhotoshoot,
    this.isNew = false,
  });

  final GalleryDisplayItem item;
  final ValueChanged<String> onHidePhotoshoot;
  final bool isNew;

  void _openViewer(BuildContext context) {
    GalleryPhotoshootViewer.show(
      context,
      item: item,
      onHidePhotoshoot: onHidePhotoshoot,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item.displayTitle;
    final countLabel = item.imageUrls.length == 3
        ? '3 фото'
        : galleryPhotoshootPhotoCountLabel(item.imageUrls.length);

    return _GalleryResultCardShell(
      isNew: isNew,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openViewer(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: GalleryPhotoshootTripletPreview(
                  imageUrls: item.imageUrls,
                  description: item.description,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    const _GalleryChip(label: 'Фотосессия', emphasized: true),
                    _GalleryChip(label: countLabel, emphasized: true),
                    if (isNew) const _GalleryChip(label: 'Новое', isNew: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _openViewer(context),
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
                      'Открыть',
                      style: TextStyle(fontWeight: FontWeight.w600),
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

class _GallerySinglePhotoCard extends StatelessWidget {
  const _GallerySinglePhotoCard({
    required this.item,
    required this.onHideImage,
    this.isNew = false,
  });

  final GalleryDisplayItem item;
  final ValueChanged<String> onHideImage;
  final bool isNew;

  void _openViewer(BuildContext context) {
    GallerySingleImageViewer.show(
      context,
      item: item,
      onHide: onHideImage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item.displayTitle;

    return _GalleryResultCardShell(
      isNew: isNew,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openViewer(context),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: GalleryResultImage(
                    url: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
                    description: item.description,
                    compact: true,
                    onOpenPressed: () => _openViewer(context),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    const _GalleryChip(label: 'Фото'),
                    if (isNew) const _GalleryChip(label: 'Новое', isNew: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _openViewer(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Открыть',
                      style: TextStyle(fontWeight: FontWeight.w600),
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

class _GalleryResultCardShell extends StatelessWidget {
  const _GalleryResultCardShell({
    required this.child,
    this.isNew = false,
  });

  final Widget child;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isNew
            ? Border.all(color: _accentColor.withValues(alpha: 0.35), width: 1.5)
            : Border.all(color: const Color(0xFFE8EAEF)),
        boxShadow: [
          BoxShadow(
            color: isNew
                ? _accentColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isNew ? 18 : 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _GalleryChip extends StatelessWidget {
  const _GalleryChip({
    required this.label,
    this.emphasized = false,
    this.isNew = false,
  });

  final String label;
  final bool emphasized;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch ((isNew, emphasized)) {
      (true, _) => (const Color(0xFF5B6CFF), Colors.white),
      (false, true) => (const Color(0xFFF0F2FF), const Color(0xFF5B6CFF)),
      _ => (const Color(0xFFF7F8FC), _textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
