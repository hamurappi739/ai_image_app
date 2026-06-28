import '../theme/app_theme.dart';
import 'package:ai_image_generator/models/gallery_display_item.dart';
import 'package:ai_image_generator/utils/gallery_download.dart';
import 'package:ai_image_generator/widgets/gallery_result_image.dart';
import 'package:flutter/material.dart';

const _accentColor = Color(0xFF5B6CFF);

Future<bool?> _confirmRemoveImage(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final screenWidth = MediaQuery.sizeOf(dialogContext).width;
      return AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth < 360 ? 16 : 24,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Удалить фото из галереи?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Фото будет убрано из галереи приложения. '
            'Это действие нельзя отменить.',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 14 : 15,
              height: 1.45,
              color: const Color(0xFF6B7280),
            ),
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
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Удалить'),
          ),
        ],
      );
    },
  );
}

Future<bool?> _confirmRemovePhotoshoot(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final screenWidth = MediaQuery.sizeOf(dialogContext).width;
      return AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth < 360 ? 16 : 24,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Удалить фотосессию из галереи?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Фотосессия будет убрана из галереи приложения. '
            'Это действие нельзя отменить.',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 14 : 15,
              height: 1.45,
              color: const Color(0xFF6B7280),
            ),
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
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Удалить'),
          ),
        ],
      );
    },
  );
}

class GallerySingleImageViewer extends StatelessWidget {
  const GallerySingleImageViewer({
    super.key,
    required this.imageUrl,
    required this.description,
    required this.hideKey,
    required this.onHide,
    this.createdAt,
  });

  final String imageUrl;
  final String description;
  final String hideKey;
  final ValueChanged<String> onHide;
  final DateTime? createdAt;

  static Future<void> show(
    BuildContext context, {
    required GalleryDisplayItem item,
    required ValueChanged<String> onHide,
  }) {
    final hideKey = item.hideKey;
    if (hideKey == null) return Future.value();

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => GallerySingleImageViewer(
        imageUrl: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
        description: item.description,
        hideKey: hideKey,
        onHide: onHide,
        createdAt: item.createdAt,
      ),
    );
  }

  Future<void> _onHidePressed(BuildContext context) async {
    final confirmed = await _confirmRemoveImage(context);
    if (confirmed != true || !context.mounted) return;
    onHide(hideKey);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Фото удалено из галереи'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = gallerySinglePhotoTitle(description);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Закрыть',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: context.appColors.subtleFill,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 3,
                  child: Center(
                    child: GalleryResultImage(
                      url: imageUrl,
                      description: description,
                      fit: BoxFit.contain,
                      fullQuality: true,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => downloadGalleryImage(
                      context,
                      imageUrl,
                      suggestedFileName: 'image',
                    ),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Скачать'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _onHidePressed(context),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Удалить из галереи'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryPhotoshootViewer extends StatelessWidget {
  const GalleryPhotoshootViewer({
    super.key,
    required this.item,
    required this.onHidePhotoshoot,
  });

  final GalleryDisplayItem item;
  final ValueChanged<String> onHidePhotoshoot;

  static Future<void> show(
    BuildContext context, {
    required GalleryDisplayItem item,
    required ValueChanged<String> onHidePhotoshoot,
  }) {
    final photoshootId = item.photoshootId;
    if (photoshootId == null || photoshootId.isEmpty) {
      return Future.value();
    }

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => GalleryPhotoshootViewer(
        item: item,
        onHidePhotoshoot: onHidePhotoshoot,
      ),
    );
  }

  Future<void> _onHidePressed(BuildContext context) async {
    final photoshootId = item.photoshootId;
    if (photoshootId == null) return;

    final confirmed = await _confirmRemovePhotoshoot(context);
    if (confirmed != true || !context.mounted) return;
    onHidePhotoshoot(photoshootId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Фотосессия удалена из галереи'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styleTitle = galleryPhotoshootStyleTitle(item.description);
    final countLabel = item.imageUrls.length == 3
        ? '3 фото'
        : galleryPhotoshootPhotoCountLabel(item.imageUrls.length);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Фотосессия',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          styleTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                countLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Закрыть',
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final urls = item.imageUrls.isEmpty
                        ? const ['', '', '']
                        : item.imageUrls.length >= 3
                            ? item.imageUrls.take(3).toList()
                            : [
                                ...item.imageUrls,
                                for (var i = item.imageUrls.length; i < 3; i++)
                                  item.imageUrls.last,
                              ];
                    final columns = constraints.maxWidth >= 480 ? 3 : 1;
                    if (columns == 3) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < urls.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: _PhotoshootPhotoTile(
                                imageUrl: urls[i],
                                label: 'Фото ${i + 1}',
                                description: item.description,
                                seriesIndex: i,
                              ),
                            ),
                          ],
                        ],
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < urls.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _PhotoshootPhotoTile(
                            imageUrl: urls[i],
                            label: 'Фото ${i + 1}',
                            description: item.description,
                            seriesIndex: i,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _onHidePressed(context),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Удалить фотосессию из галереи'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoshootPhotoTile extends StatelessWidget {
  const _PhotoshootPhotoTile({
    required this.imageUrl,
    required this.label,
    required this.description,
    required this.seriesIndex,
  });

  final String imageUrl;
  final String label;
  final String description;
  final int seriesIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: GalleryResultImage(
              url: imageUrl,
              description: description,
              seriesIndex: seriesIndex,
              photoshootSeries: true,
              fullQuality: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => downloadGalleryImage(
                context,
                imageUrl,
                suggestedFileName: label.replaceAll(' ', '_').toLowerCase(),
              ),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Скачать'),
              style: TextButton.styleFrom(
                foregroundColor: _accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
