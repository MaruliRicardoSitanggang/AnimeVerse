import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dummy_data.dart';
import '../models/anime.dart';

class AppStateProvider extends ChangeNotifier {
  final List<Anime> _favorites = [];
  static const String _storageKey = 'favorite_anime_list';
  late final Future<void> initialized;
  Future<void> _saveQueue = Future<void>.value();
  final Map<String, Anime?> _pendingFavoriteChanges = {};
  bool _isLoading = true;
  bool _disposed = false;
  String _selectedGenre = 'All';
  String _homeSearchQuery = '';
  String _favoriteSearchQuery = '';

  AppStateProvider() {
    initialized = _loadFavorites();
  }

  List<Anime> get favorites => List.unmodifiable(_favorites);
  Future<void> get favoritesSaved => _saveQueue;
  String get selectedGenre => _selectedGenre;
  String get homeSearchQuery => _homeSearchQuery;
  String get favoriteSearchQuery => _favoriteSearchQuery;

  void setSelectedGenre(String genre) {
    if (_selectedGenre == genre) return;
    _selectedGenre = genre;
    notifyListeners();
  }

  void setHomeSearchQuery(String query) {
    if (_homeSearchQuery == query) return;
    _homeSearchQuery = query;
    notifyListeners();
  }

  void setFavoriteSearchQuery(String query) {
    if (_favoriteSearchQuery == query) return;
    _favoriteSearchQuery = query;
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favorites.any((anime) => anime.id == id);
  }

  void toggleFavorite(Anime anime) {
    if (isFavorite(anime.id)) {
      removeFavorite(anime.id);
    } else {
      addFavorite(anime);
    }
  }

  void addFavorite(Anime anime) {
    if (isFavorite(anime.id)) return;
    _favorites.add(anime);
    if (_isLoading) _pendingFavoriteChanges[anime.id] = anime;
    _saveFavorites();
    notifyListeners();
  }

  void removeFavorite(String id) {
    if (!isFavorite(id)) return;
    _favorites.removeWhere((anime) => anime.id == id);
    if (_isLoading) _pendingFavoriteChanges[id] = null;
    _saveFavorites();
    notifyListeners();
  }

  List<Anime> getFilteredAnimeForHome() {
    Iterable<Anime> result = DummyData.animeList;
    if (_selectedGenre != 'All') {
      result = result.where((anime) {
        final genres = anime.genre.split(',').map((genre) => genre.trim());
        return genres.contains(_selectedGenre);
      });
    }
    if (_homeSearchQuery.isNotEmpty) {
      result = result.where(
        (anime) =>
            anime.title.toLowerCase().contains(_homeSearchQuery.toLowerCase()),
      );
    }
    return result.toList();
  }

  List<Anime> getFilteredFavorites() {
    return _favorites.where((anime) {
      return anime.title.toLowerCase().contains(
        _favoriteSearchQuery.toLowerCase(),
      );
    }).toList();
  }

  // Urutkan penulisan agar perubahan cepat tidak menimpa data terbaru.
  void _saveFavorites() {
    _saveQueue = _saveQueue.then((_) async {
      try {
        await initialized;
        final prefs = await SharedPreferences.getInstance();
        final favoritesJson = _favorites
            .map((anime) => anime.toJson())
            .toList();
        await prefs.setString(_storageKey, jsonEncode(favoritesJson));
      } catch (e) {
        debugPrint('Error saving favorites: $e');
      }
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_storageKey);
      if (favoritesJson == null) return;

      final decoded = jsonDecode(favoritesJson) as List<dynamic>;
      final restored = <String, Anime>{};
      for (final item in decoded) {
        final anime = Anime.fromJson(item as Map<String, dynamic>);
        restored[anime.id] = anime;
      }
      // Pertahankan perubahan pengguna selama data awal masih dimuat.
      for (final entry in _pendingFavoriteChanges.entries) {
        final anime = entry.value;
        if (anime == null) {
          restored.remove(entry.key);
        } else {
          restored[entry.key] = anime;
        }
      }
      _favorites
        ..clear()
        ..addAll(restored.values);
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      _pendingFavoriteChanges.clear();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
