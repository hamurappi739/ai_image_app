import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _catalogVersionKey = 'catalog_version';
  static const _catalogUpdatedAtKey = 'catalog_updated_at';

  List<CatalogTemplateEntry> _templates =
      List.unmodifiable(CatalogFallback.templates);
  List<CatalogPhotoshootEntry> _photoshoots =
      List.unmodifiable(CatalogFallback.photoshoots);

  bool _isLoaded = false;
  bool _usedFallback = false;
  CatalogSource _catalogSource = CatalogSource.embeddedFallback;
  String? _loadError;
  String? _catalogVersion;
  String? _catalogUpdatedAt;

  bool get isLoaded => _isLoaded;
  bool get usedFallback => _usedFallback;
  CatalogSource get catalogSource => _catalogSource;
  String? get loadError => _loadError;
  String? get catalogVersion => _catalogVersion;
  String? get catalogUpdatedAt => _catalogUpdatedAt;

  List<CatalogTemplateEntry> get templates => _templates;
  List<CatalogPhotoshootEntry> get photoshoots => _photoshoots;

  Future<void> load({bool forceRemote = false}) async {
    final remoteLoaded = await _tryLoadRemote(force: forceRemote);
    if (!remoteLoaded) {
      await _loadFromAssets();
    }
    _isLoaded = true;
  }

  /// Reload remote catalog when backend [catalogVersion] changed.
  Future<bool> refreshIfCatalogChanged() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getString(_catalogVersionKey);
    final storedUpdatedAt = prefs.getString(_catalogUpdatedAtKey);

    if (!await _tryLoadRemote(persistMetadata: false)) {
      return false;
    }

    final changed = (_catalogVersion != null && _catalogVersion != storedVersion) ||
        (_catalogUpdatedAt != null && _catalogUpdatedAt != storedUpdatedAt);

    if (changed) {
      await _persistCatalogMetadata(prefs);
      _isLoaded = true;
    }
    return changed;
  }

  Future<bool> _tryLoadRemote({
    bool force = false,
    bool persistMetadata = true,
  }) async {
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
      final templatesMeta = _parseCatalogMetadata(jsonDecode(responses[0].body));
      final photoshootsMeta = _parseCatalogMetadata(jsonDecode(responses[1].body));

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
      _catalogVersion =
          templatesMeta.catalogVersion ?? photoshootsMeta.catalogVersion;
      _catalogUpdatedAt = _latestUpdatedAt(
        templatesMeta.updatedAt,
        photoshootsMeta.updatedAt,
      );
      _usedFallback =
          parsedTemplates.isEmpty || parsedPhotoshoots.isEmpty;
      _catalogSource = CatalogSource.remote;
      _loadError = null;

      if (persistMetadata) {
        await _persistCatalogMetadata(await SharedPreferences.getInstance());
      }

      if (kDebugMode) {
        debugPrint(
          'CatalogService: loaded remote catalog '
          '(${_templates.length} templates, ${_photoshoots.length} photoshoots, '
          'version=${_catalogVersion ?? 'unknown'})',
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

  Future<void> _persistCatalogMetadata(SharedPreferences prefs) async {
    final version = _catalogVersion;
    final updatedAt = _catalogUpdatedAt;
    if (version != null && version.isNotEmpty) {
      await prefs.setString(_catalogVersionKey, version);
    }
    if (updatedAt != null && updatedAt.isNotEmpty) {
      await prefs.setString(_catalogUpdatedAtKey, updatedAt);
    }
  }

  _CatalogMetadata _parseCatalogMetadata(Object? decoded) {
    if (decoded is! Map<String, dynamic>) {
      return const _CatalogMetadata();
    }
    final catalogVersion = decoded['catalogVersion'];
    final updatedAt = decoded['updatedAt'];
    return _CatalogMetadata(
      catalogVersion: catalogVersion is String && catalogVersion.trim().isNotEmpty
          ? catalogVersion.trim()
          : null,
      updatedAt: updatedAt is String && updatedAt.trim().isNotEmpty
          ? updatedAt.trim()
          : null,
    );
  }

  String? _latestUpdatedAt(String? first, String? second) {
    if (first == null || first.isEmpty) {
      return second;
    }
    if (second == null || second.isEmpty) {
      return first;
    }
    return first.compareTo(second) >= 0 ? first : second;
  }
}

class _CatalogMetadata {
  const _CatalogMetadata({this.catalogVersion, this.updatedAt});

  final String? catalogVersion;
  final String? updatedAt;
}
