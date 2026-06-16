import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/catalog_fallback.dart';
import '../models/catalog_entries.dart';

/// Loads template and photoshoot catalogs from `assets/catalog/*.json`.
class CatalogService {
  CatalogService._();

  static final CatalogService instance = CatalogService._();

  static const _templatesAsset = 'assets/catalog/templates.json';
  static const _photoshootsAsset = 'assets/catalog/photoshoots.json';

  List<CatalogTemplateEntry> _templates = List.unmodifiable(CatalogFallback.templates);
  List<CatalogPhotoshootEntry> _photoshoots =
      List.unmodifiable(CatalogFallback.photoshoots);

  bool _isLoaded = false;
  bool _usedFallback = false;
  String? _loadError;

  bool get isLoaded => _isLoaded;
  bool get usedFallback => _usedFallback;
  String? get loadError => _loadError;

  List<CatalogTemplateEntry> get templates => _templates;
  List<CatalogPhotoshootEntry> get photoshoots => _photoshoots;

  Future<void> load() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString(_templatesAsset),
        rootBundle.loadString(_photoshootsAsset),
      ]);

      final parsedTemplates = _parseTemplates(results[0]);
      final parsedPhotoshoots = _parsePhotoshoots(results[1]);

      if (parsedTemplates.isEmpty && parsedPhotoshoots.isEmpty) {
        throw const FormatException('Catalog JSON files are empty');
      }

      _templates = List.unmodifiable(
        parsedTemplates.isEmpty ? CatalogFallback.templates : parsedTemplates,
      );
      _photoshoots = List.unmodifiable(
        parsedPhotoshoots.isEmpty
            ? CatalogFallback.photoshoots
            : parsedPhotoshoots,
      );
      _usedFallback =
          parsedTemplates.isEmpty || parsedPhotoshoots.isEmpty;
      _loadError = null;
    } catch (error) {
      _templates = List.unmodifiable(CatalogFallback.templates);
      _photoshoots = List.unmodifiable(CatalogFallback.photoshoots);
      _usedFallback = true;
      _loadError = error.toString();
    } finally {
      _isLoaded = true;
    }
  }

  List<CatalogTemplateEntry> activeTemplates() {
    final items = _templates.where((item) => item.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  List<CatalogTemplateEntry> templatesForCategory(String category) {
    return activeTemplates()
        .where((item) => item.category == category)
        .toList();
  }

  CatalogTemplateEntry? templateById(String id) {
    for (final item in _templates) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<CatalogPhotoshootEntry> activePhotoshoots() {
    final items = _photoshoots.where((item) => item.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  List<CatalogPhotoshootEntry> photoshootsForCategory(String category) {
    return activePhotoshoots()
        .where((item) => item.category == category)
        .toList();
  }

  CatalogPhotoshootEntry? photoshootById(String id) {
    for (final item in _photoshoots) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<CatalogTemplateEntry> _parseTemplates(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('templates.json must be a JSON array');
    }
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) CatalogTemplateEntry.fromJson(item),
    ];
  }

  List<CatalogPhotoshootEntry> _parsePhotoshoots(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('photoshoots.json must be a JSON array');
    }
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) CatalogPhotoshootEntry.fromJson(item),
    ];
  }
}
