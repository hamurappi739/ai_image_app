import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../data/catalog_fallback.dart';
import '../models/catalog_entries.dart';
import 'api_service.dart';

enum CatalogSource { remote, localAssets, embeddedFallback }

/// Loads template and photoshoot catalogs from the backend API, with local
/// asset and embedded fallbacks.
class CatalogService {
  CatalogService._();

  static final CatalogService instance = CatalogService._();

  static const _templatesAsset = 'assets/catalog/templates.json';
  static const _photoshootsAsset = 'assets/catalog/photoshoots.json';
  static const _remoteTimeout = Duration(seconds: 4);

  List<CatalogTemplateEntry> _templates =
      List.unmodifiable(CatalogFallback.templates);
  List<CatalogPhotoshootEntry> _photoshoots =
      List.unmodifiable(CatalogFallback.photoshoots);

  bool _isLoaded = false;
  bool _usedFallback = false;
  CatalogSource _catalogSource = CatalogSource.embeddedFallback;
  String? _loadError;

  bool get isLoaded => _isLoaded;
  bool get usedFallback => _usedFallback;
  CatalogSource get catalogSource => _catalogSource;
  String? get loadError => _loadError;

  List<CatalogTemplateEntry> get templates => _templates;
  List<CatalogPhotoshootEntry> get photoshoots => _photoshoots;

  Future<void> load() async {
    final remoteLoaded = await _tryLoadRemote();
    if (!remoteLoaded) {
      await _loadFromAssets();
    }
    _isLoaded = true;
  }

  Future<bool> _tryLoadRemote() async {
    final client = http.Client();
    try {
      final baseUrl = ApiService.baseUrl;
      final responses = await Future.wait([
        client
            .get(Uri.parse('$baseUrl/catalog/templates'))
            .timeout(_remoteTimeout),
        client
            .get(Uri.parse('$baseUrl/catalog/photoshoots'))
            .timeout(_remoteTimeout),
      ]).timeout(_remoteTimeout);

      if (responses.any((response) => response.statusCode != 200)) {
        if (kDebugMode) {
          debugPrint(
            'CatalogService: remote catalog HTTP '
            '${responses[0].statusCode}/${responses[1].statusCode}',
          );
        }
        return false;
      }

      final parsedTemplates =
          _parseTemplatesPayload(jsonDecode(responses[0].body));
      final parsedPhotoshoots =
          _parsePhotoshootsPayload(jsonDecode(responses[1].body));

      if (parsedTemplates.isEmpty && parsedPhotoshoots.isEmpty) {
        return false;
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
      _catalogSource = CatalogSource.remote;
      _loadError = null;

      if (kDebugMode) {
        debugPrint(
          'CatalogService: loaded remote catalog '
          '(${_templates.length} templates, ${_photoshoots.length} photoshoots)',
        );
      }
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('CatalogService: remote catalog failed: $error');
      }
      return false;
    } finally {
      client.close();
    }
  }

  Future<void> _loadFromAssets() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString(_templatesAsset),
        rootBundle.loadString(_photoshootsAsset),
      ]);

      final parsedTemplates = _parseTemplatesPayload(jsonDecode(results[0]));
      final parsedPhotoshoots =
          _parsePhotoshootsPayload(jsonDecode(results[1]));

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
      _catalogSource = CatalogSource.localAssets;
      _loadError = null;

      if (kDebugMode) {
        debugPrint('CatalogService: loaded local asset catalog');
      }
    } catch (error) {
      _templates = List.unmodifiable(CatalogFallback.templates);
      _photoshoots = List.unmodifiable(CatalogFallback.photoshoots);
      _usedFallback = true;
      _catalogSource = CatalogSource.embeddedFallback;
      _loadError = error.toString();

      if (kDebugMode) {
        debugPrint('CatalogService: using embedded fallback: $error');
      }
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

  List<CatalogTemplateEntry> _parseTemplatesPayload(Object? decoded) {
    final rawItems = _extractItemsArray(decoded, 'templates');
    return [
      for (final item in rawItems)
        if (item is Map<String, dynamic>) CatalogTemplateEntry.fromJson(item),
    ];
  }

  List<CatalogPhotoshootEntry> _parsePhotoshootsPayload(Object? decoded) {
    final rawItems = _extractItemsArray(decoded, 'photoshoots');
    return [
      for (final item in rawItems)
        if (item is Map<String, dynamic>) CatalogPhotoshootEntry.fromJson(item),
    ];
  }

  List<dynamic> _extractItemsArray(Object? decoded, String label) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final items = decoded['items'];
      if (items is List) {
        return items;
      }
    }
    throw FormatException('$label catalog payload must contain an items array');
  }
}
