import 'dart:async';
import '../models/news_article.dart';
import '../services/news_api_service.dart';
import '../services/cache_service.dart';

/// Search result with additional metadata
class SearchResult {
  final List<NewsArticle> articles;
  final String query;
  final int totalCount;
  final DateTime timestamp;
  final bool fromCache;

  const SearchResult({
    required this.articles,
    required this.query,
    required this.totalCount,
    required this.timestamp,
    this.fromCache = false,
  });

  @override
  String toString() {
    return 'SearchResult(query: $query, articles: ${articles.length}, fromCache: $fromCache)';
  }
}

/// Enhanced search service with debouncing and async operations
class SearchService {
  final NewsApiService _apiService;
  final CacheService _cacheService;
  
  // Debouncing timer
  Timer? _debounceTimer;
  
  // Search history
  final List<String> _searchHistory = [];
  static const int _maxHistoryItems = 10;
  
  // Search suggestions cache
  final Map<String, List<String>> _suggestionsCache = {};

  SearchService(this._apiService, this._cacheService);

  /// Perform search with debouncing and async/await
  /// [query] - search query
  /// [debounceDelay] - delay in milliseconds before executing search
  /// [forceRefresh] - ignore cache and force fresh API call
  Future<SearchResult> searchNews({
    required String query,
    int debounceDelay = 500,
    bool forceRefresh = false,
  }) async {
    if (query.trim().isEmpty) {
      return SearchResult(
        articles: [],
        query: query,
        totalCount: 0,
        timestamp: DateTime.now(),
      );
    }

    // Cancel previous search if still pending
    _debounceTimer?.cancel();

    // Add to search history
    _addToHistory(query);

    // Return a Future that will complete after debounce
    final completer = Completer<SearchResult>();
    
    _debounceTimer = Timer(Duration(milliseconds: debounceDelay), () async {
      try {
        final result = await _performSearch(query, forceRefresh);
        completer.complete(result);
      } catch (error) {
        completer.completeError(error);
      }
    });

    return completer.future;
  }

  /// Internal method to perform the actual search
  Future<SearchResult> _performSearch(String query, bool forceRefresh) async {
    try {
      // Try cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedArticles = await _cacheService.getCachedSearchResults(query);
        if (cachedArticles != null) {
          return SearchResult(
            articles: cachedArticles,
            query: query,
            totalCount: cachedArticles.length,
            timestamp: DateTime.now(),
            fromCache: true,
          );
        }
      }

      // Perform API search with async/await
      final articles = await _apiService.searchNews(
        query: query,
        language: 'en',
        sortBy: 'publishedAt',
        pageSize: 20,
        page: 1,
      );

      // Cache the results
      await _cacheService.saveSearchResults(
        articles: articles,
        query: query,
      );

      return SearchResult(
        articles: articles,
        query: query,
        totalCount: articles.length,
        timestamp: DateTime.now(),
        fromCache: false,
      );
    } catch (e) {
      // If API fails, try cache as fallback
      if (!forceRefresh) {
        final cachedArticles = await _cacheService.getCachedSearchResults(query);
        if (cachedArticles != null) {
          return SearchResult(
            articles: cachedArticles,
            query: query,
            totalCount: cachedArticles.length,
            timestamp: DateTime.now(),
            fromCache: true,
          );
        }
      }
      rethrow;
    }
  }

  /// Get search suggestions based on query and history
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      return getRecentSearches();
    }

    // Check cache first
    if (_suggestionsCache.containsKey(query)) {
      return _suggestionsCache[query]!;
    }

    // Generate suggestions from history and common terms
    final suggestions = <String>[];
    
    // Add matching history items
    for (final historyItem in _searchHistory) {
      if (historyItem.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(historyItem);
      }
    }

    // Add common technology/news terms that match
    final commonTerms = [
      'flutter', 'dart', 'android', 'ios', 'mobile development',
      'technology', 'science', 'business', 'health', 'sports',
      'politics', 'entertainment', 'breaking news', 'latest news'
    ];

    for (final term in commonTerms) {
      if (term.toLowerCase().contains(query.toLowerCase()) && !suggestions.contains(term)) {
        suggestions.add(term);
      }
    }

    // Cache suggestions
    _suggestionsCache[query] = suggestions.take(5).toList();
    
    return suggestions.take(5).toList();
  }

  /// Get recent search history
  List<String> getRecentSearches() {
    return List.unmodifiable(_searchHistory);
  }

  /// Clear search history
  void clearSearchHistory() {
    _searchHistory.clear();
    _suggestionsCache.clear();
  }

  /// Add query to search history
  void _addToHistory(String query) {
    // Remove if already exists
    _searchHistory.remove(query);
    
    // Add to beginning
    _searchHistory.insert(0, query);
    
    // Limit history size
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory.removeRange(_maxHistoryItems, _searchHistory.length);
    }
  }

  /// Cancel ongoing search
  void cancelSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _suggestionsCache.clear();
    _searchHistory.clear();
  }
}
