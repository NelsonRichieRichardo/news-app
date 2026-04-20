import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_article.dart';

/// Service for caching news data using SharedPreferences
class CacheService {
  static const String _headlinesKeyPrefix = 'cached_headlines_';
  static const String _searchKeyPrefix = 'cached_search_';
  static const String _timestampKeyPrefix = 'timestamp_';
  static const String _lastUpdatedKey = 'last_updated';
  
  /// Cache duration in minutes
  static const int _cacheDurationMinutes = 30;

  /// Save headlines to cache
  Future<void> saveHeadlines({
    required List<NewsArticle> articles,
    String? category,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getHeadlinesKey(category);
      final timestampKey = _getTimestampKey('headlines', category);
      
      // Convert articles to JSON
      final articlesJson = articles.map((article) => article.toJson()).toList();
      final jsonString = jsonEncode(articlesJson);
      
      // Save to cache
      await prefs.setString(key, jsonString);
      await prefs.setString(timestampKey, DateTime.now().toIso8601String());
      await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Cache errors shouldn't crash the app
      print('Cache save error: $e');
    }
  }

  /// Save search results to cache
  Future<void> saveSearchResults({
    required List<NewsArticle> articles,
    required String query,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSearchKey(query);
      final timestampKey = _getTimestampKey('search', query);
      
      // Convert articles to JSON
      final articlesJson = articles.map((article) => article.toJson()).toList();
      final jsonString = jsonEncode(articlesJson);
      
      // Save to cache
      await prefs.setString(key, jsonString);
      await prefs.setString(timestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Cache save error: $e');
    }
  }

  /// Get cached headlines
  Future<List<NewsArticle>?> getCachedHeadlines({String? category}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getHeadlinesKey(category);
      final timestampKey = _getTimestampKey('headlines', category);
      
      // Check if cache is still valid
      if (!await _isCacheValid(timestampKey)) {
        return null;
      }
      
      // Get cached data
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;
      
      // Parse JSON to articles
      final List<dynamic> articlesJson = jsonDecode(jsonString);
      return articlesJson.map((json) => NewsArticle.fromJson(json)).toList();
    } catch (e) {
      print('Cache retrieval error: $e');
      return null;
    }
  }

  /// Get cached search results
  Future<List<NewsArticle>?> getCachedSearchResults(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSearchKey(query);
      final timestampKey = _getTimestampKey('search', query);
      
      // Check if cache is still valid
      if (!await _isCacheValid(timestampKey)) {
        return null;
      }
      
      // Get cached data
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;
      
      // Parse JSON to articles
      final List<dynamic> articlesJson = jsonDecode(jsonString);
      return articlesJson.map((json) => NewsArticle.fromJson(json)).toList();
    } catch (e) {
      print('Cache retrieval error: $e');
      return null;
    }
  }

  /// Check if cache is still valid (not expired)
  Future<bool> _isCacheValid(String timestampKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(timestampKey);
      if (timestampString == null) return false;
      
      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      // Cache is valid if less than cache duration
      return difference.inMinutes < _cacheDurationMinutes;
    } catch (e) {
      return false;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Remove all cache-related keys
      for (final key in keys) {
        if (key.startsWith(_headlinesKeyPrefix) ||
            key.startsWith(_searchKeyPrefix) ||
            key.startsWith(_timestampKeyPrefix) ||
            key == _lastUpdatedKey) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Cache clear error: $e');
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_timestampKeyPrefix)) {
          if (!await _isCacheValid(key)) {
            // Remove expired cache entries
            final cacheKey = _getCacheKeyFromTimestamp(key);
            if (cacheKey != null) {
              await prefs.remove(key);
              await prefs.remove(cacheKey);
            }
          }
        }
      }
    } catch (e) {
      print('Cache cleanup error: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int cacheEntries = 0;
      DateTime? lastUpdated;
      
      for (final key in keys) {
        if (key.startsWith(_headlinesKeyPrefix) ||
            key.startsWith(_searchKeyPrefix)) {
          cacheEntries++;
        }
      }
      
      final lastUpdatedString = prefs.getString(_lastUpdatedKey);
      if (lastUpdatedString != null) {
        lastUpdated = DateTime.parse(lastUpdatedString);
      }
      
      return {
        'cacheEntries': cacheEntries,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'cacheDurationMinutes': _cacheDurationMinutes,
      };
    } catch (e) {
      return {
        'cacheEntries': 0,
        'lastUpdated': null,
        'cacheDurationMinutes': _cacheDurationMinutes,
        'error': e.toString(),
      };
    }
  }

  /// Generate headlines cache key
  String _getHeadlinesKey(String? category) {
    return category != null 
        ? '$_headlinesKeyPrefix${category.toLowerCase()}'
        : '$_headlinesKeyPrefix general';
  }

  /// Generate search cache key
  String _getSearchKey(String query) {
    return '$_searchKeyPrefix${query.toLowerCase().trim()}';
  }

  /// Generate timestamp cache key
  String _getTimestampKey(String type, String? identifier) {
    if (type == 'headlines') {
      return '$_timestampKeyPrefix${_getHeadlinesKey(identifier)}';
    } else if (type == 'search') {
      return '$_timestampKeyPrefix${_getSearchKey(identifier ?? '')}';
    }
    return '$_timestampKeyPrefix$type';
  }

  /// Get cache key from timestamp key
  String? _getCacheKeyFromTimestamp(String timestampKey) {
    if (timestampKey.startsWith('$_timestampKeyPrefix$_headlinesKeyPrefix')) {
      return timestampKey.replaceFirst('$_timestampKeyPrefix', '');
    } else if (timestampKey.startsWith('$_timestampKeyPrefix$_searchKeyPrefix')) {
      return timestampKey.replaceFirst('$_timestampKeyPrefix', '');
    }
    return null;
  }

  /// Check if device is online (basic connectivity check)
  Future<bool> isOnline() async {
    try {
      // This is a simple connectivity check
      // In a real app, you might want to use connectivity_plus package
      final prefs = await SharedPreferences.getInstance();
      final lastOnlineCheck = prefs.getString('last_online_check');
      
      if (lastOnlineCheck != null) {
        final lastCheck = DateTime.parse(lastOnlineCheck);
        final now = DateTime.now();
        
        // If we checked recently (within last 5 minutes), assume same state
        if (now.difference(lastCheck).inMinutes < 5) {
          return prefs.getBool('is_online') ?? true;
        }
      }
      
      // For now, we'll assume online. In production, you'd do a real check
      await prefs.setString('last_online_check', DateTime.now().toIso8601String());
      await prefs.setBool('is_online', true);
      return true;
    } catch (e) {
      return false;
    }
  }
}
