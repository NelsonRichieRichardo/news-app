import 'package:flutter/foundation.dart';
import '../models/news_article.dart';
import '../services/news_api_service.dart';
import '../services/cache_service.dart';

/// Enum representing the different states of news data fetching
enum NewsState {
  idle,      // Initial state, no action taken
  loading,   // Currently fetching data
  loaded,    // Successfully fetched data
  error,     // Error occurred while fetching data
}

/// Provider class for managing news data state
class NewsProvider extends ChangeNotifier {
  final NewsApiService _apiService;
  final CacheService _cacheService;
  
  NewsProvider(this._apiService, [CacheService? cacheService]) 
      : _cacheService = cacheService ?? CacheService();

  // Private state variables
  NewsState _state = NewsState.idle;
  List<NewsArticle> _articles = [];
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;
  String _currentCategory = '';
  String _searchQuery = '';

  // Public getters
  NewsState get state => _state;
  List<NewsArticle> get articles => _articles;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == NewsState.loading;
  bool get hasError => _state == NewsState.error;
  bool get hasData => _articles.isNotEmpty;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String get currentCategory => _currentCategory;
  String get searchQuery => _searchQuery;

  /// Set loading state and clear previous errors
  void _setLoading() {
    _state = NewsState.loading;
    _errorMessage = '';
    notifyListeners();
  }

  /// Set loaded state with articles
  void _setLoaded(List<NewsArticle> articles, {bool isRefresh = false}) {
    _state = NewsState.loaded;
    if (isRefresh) {
      _articles = articles;
    } else {
      _articles.addAll(articles);
    }
    _errorMessage = '';
    notifyListeners();
  }

  /// Set error state with message
  void _setError(String message) {
    _state = NewsState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Reset provider to initial state
  void reset() {
    _state = NewsState.idle;
    _articles.clear();
    _errorMessage = '';
    _currentPage = 1;
    _hasMore = true;
    _currentCategory = '';
    _searchQuery = '';
    notifyListeners();
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await _cacheService.clearCache();
    } catch (e) {
      _setError('Failed to clear cache: ${e.toString()}');
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      await _cacheService.clearExpiredCache();
    } catch (e) {
      // Don't show error for cache cleanup, just log it
      print('Cache cleanup error: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return await _cacheService.getCacheStats();
    } catch (e) {
      return {
        'cacheEntries': 0,
        'lastUpdated': null,
        'cacheDurationMinutes': 30,
        'error': e.toString(),
      };
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      return await _cacheService.isOnline();
    } catch (e) {
      return false;
    }
  }

  /// Fetch top headlines from the API
  /// [category] - optional category filter
  /// [refresh] - if true, clears existing data and fetches fresh data
  Future<void> fetchTopHeadlines({
    String? category,
    bool refresh = false,
  }) async {
    print('DEBUG: fetchTopHeadlines called with category: $category, refresh: $refresh');
    print('DEBUG: Current state: isLoading=$isLoading, hasData=$hasData');
    
    if (isLoading) return; // Prevent multiple simultaneous requests

    try {
      _setLoading();
      print('DEBUG: Loading state set');

      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
        _currentCategory = category ?? '';
      }

      // Try to load from cache first (only for initial load, not refresh)
      if (!refresh && _currentPage == 1) {
        final cachedArticles = await _cacheService.getCachedHeadlines(category: category);
        if (cachedArticles != null) {
          _articles = cachedArticles;
          _state = NewsState.loaded;
          _errorMessage = '';
          notifyListeners();
          
          // Continue to fetch fresh data in background
          _fetchFreshHeadlines(category, refresh);
          return;
        }
      }

      await _fetchFreshHeadlines(category, refresh);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Helper method to fetch fresh headlines from API
  Future<void> _fetchFreshHeadlines(String? category, bool refresh) async {
    print('DEBUG: _fetchFreshHeadlines called with category: $category, refresh: $refresh');
    print('DEBUG: About to call API service');
    
    try {
      final articles = await _apiService.fetchTopHeadlines(
        country: 'us',
        category: category,
        pageSize: 20,
        page: _currentPage,
      );
      
      print('DEBUG: API call completed, received ${articles.length} articles');

      // Check if we have more data
      _hasMore = articles.length == 20;
      _currentPage++;

      _setLoaded(articles, isRefresh: refresh);

      // Save to cache (only for first page)
      if (_currentPage == 2) {
        await _cacheService.saveHeadlines(
          articles: articles,
          category: category,
        );
      }
    } catch (e) {
      // If API fails and we have no data, try to show cached data
      if (_articles.isEmpty) {
        final cachedArticles = await _cacheService.getCachedHeadlines(category: category);
        if (cachedArticles != null) {
          _articles = cachedArticles;
          _state = NewsState.loaded;
          _errorMessage = '';
          notifyListeners();
          return;
        }
      }
      _setError(e.toString());
    }
  }

  /// Search for news articles
  /// [query] - search query string
  /// [refresh] - if true, clears existing data and fetches fresh data
  Future<void> searchNews(
    String query, {
    bool refresh = false,
  }) async {
    if (isLoading || query.trim().isEmpty) return;

    try {
      _setLoading();

      if (refresh || _searchQuery != query) {
        _currentPage = 1;
        _hasMore = true;
        _searchQuery = query;
        _currentCategory = '';
      }

      // Try to load from cache first (only for initial load, not refresh)
      if (!refresh && _currentPage == 1) {
        final cachedArticles = await _cacheService.getCachedSearchResults(query);
        if (cachedArticles != null) {
          _articles = cachedArticles;
          _state = NewsState.loaded;
          _errorMessage = '';
          notifyListeners();
          
          // Continue to fetch fresh data in background
          _fetchFreshSearchResults(query, refresh);
          return;
        }
      }

      await _fetchFreshSearchResults(query, refresh);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Helper method to fetch fresh search results from API
  Future<void> _fetchFreshSearchResults(String query, bool refresh) async {
    try {
      final articles = await _apiService.searchNews(
        query: query,
        language: 'en',
        sortBy: 'publishedAt',
        pageSize: 20,
        page: _currentPage,
      );

      // Check if we have more data
      _hasMore = articles.length == 20;
      _currentPage++;

      _setLoaded(articles, isRefresh: refresh || _searchQuery != query);

      // Save to cache (only for first page)
      if (_currentPage == 2) {
        await _cacheService.saveSearchResults(
          articles: articles,
          query: query,
        );
      }
    } catch (e) {
      // If API fails and we have no data, try to show cached data
      if (_articles.isEmpty) {
        final cachedArticles = await _cacheService.getCachedSearchResults(query);
        if (cachedArticles != null) {
          _articles = cachedArticles;
          _state = NewsState.loaded;
          _errorMessage = '';
          notifyListeners();
          return;
        }
      }
      _setError(e.toString());
    }
  }

  /// Load more articles (pagination)
  Future<void> loadMore() async {
    if (!hasMore || isLoading) return;

    if (_searchQuery.isNotEmpty) {
      await searchNews(_searchQuery);
    } else {
      await fetchTopHeadlines(category: _currentCategory.isNotEmpty ? _currentCategory : null);
    }
  }

  /// Refresh current data
  Future<void> refresh() async {
    if (_searchQuery.isNotEmpty) {
      await searchNews(_searchQuery, refresh: true);
    } else {
      await fetchTopHeadlines(category: _currentCategory.isNotEmpty ? _currentCategory : null, refresh: true);
    }
  }

  /// Retry the last failed operation
  Future<void> retry() async {
    if (_searchQuery.isNotEmpty) {
      await searchNews(_searchQuery, refresh: true);
    } else {
      await fetchTopHeadlines(category: _currentCategory.isNotEmpty ? _currentCategory : null, refresh: true);
    }
  }

  /// Get articles by category
  Future<void> getArticlesByCategory(String category) async {
    if (_currentCategory == category && hasData) return; // Already loaded this category
    
    await fetchTopHeadlines(category: category, refresh: true);
  }

  /// Clear error state
  void clearError() {
    if (_state == NewsState.error) {
      _state = NewsState.idle;
      _errorMessage = '';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
