import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/search_service.dart';
import '../models/news_article.dart';
import 'news_card.dart';
import 'loading_widget.dart';
import 'error_widget.dart' as custom;

/// Enhanced search widget with FutureBuilder and async/await
class EnhancedSearchWidget extends StatefulWidget {
  final SearchService searchService;
  final Function(NewsArticle) onArticleTap;
  final VoidCallback? onClearHistory;

  const EnhancedSearchWidget({
    super.key,
    required this.searchService,
    required this.onArticleTap,
    this.onClearHistory,
  });

  @override
  State<EnhancedSearchWidget> createState() => _EnhancedSearchWidgetState();
}

class _EnhancedSearchWidgetState extends State<EnhancedSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  Future<SearchResult>? _searchFuture;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    widget.searchService.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus && _suggestions.isNotEmpty;
    });
  }

  /// Perform search with async/await and update FutureBuilder
  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchFuture = null;
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Create new future for search
    setState(() {
      _searchFuture = widget.searchService.searchNews(query: query);
      _showSuggestions = false;
    });

    // Get suggestions in background
    _getSuggestions(query);
  }

  /// Get search suggestions
  Future<void> _getSuggestions(String query) async {
    try {
      final suggestions = await widget.searchService.getSearchSuggestions(query);
      if (mounted && query == _searchController.text) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = _searchFocusNode.hasFocus && suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      // Don't show error for suggestions
    }
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchFuture = null;
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  /// Select suggestion
  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _searchFocusNode.unfocus();
    _performSearch(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search input field
        _buildSearchField(),
        
        // Suggestions overlay
        if (_showSuggestions) _buildSuggestionsOverlay(),
        
        // Search results
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search news articles...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: _performSearch,
        onSubmitted: (value) {
          _searchFocusNode.unfocus();
        },
        inputFormatters: [
          LengthLimitingTextInputFormatter(100),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            leading: const Icon(Icons.history, size: 20),
            title: Text(suggestion),
            onTap: () => _selectSuggestion(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchFuture == null) {
      return _buildEmptyState();
    }

    return FutureBuilder<SearchResult>(
      future: _searchFuture,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Searching...');
        }

        // Error state
        if (snapshot.hasError) {
          return custom.CustomErrorWidget(
            message: snapshot.error.toString(),
            onRetry: () {
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            },
          );
        }

        // No data state
        if (!snapshot.hasData || snapshot.data!.articles.isEmpty) {
          return _buildNoResultsState();
        }

        // Success state
        final searchResult = snapshot.data!;
        return _buildResultsList(searchResult);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Search for news articles',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for topics like "technology", "sports", or "business"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Recent searches
          if (widget.searchService.getRecentSearches().isNotEmpty)
            _buildRecentSearches(),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    final recentSearches = widget.searchService.getRecentSearches().take(5).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.onClearHistory != null)
                TextButton(
                  onPressed: widget.onClearHistory,
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: recentSearches.map((search) {
              return ActionChip(
                label: Text(search),
                onPressed: () => _selectSuggestion(search),
                avatar: const Icon(Icons.history, size: 16),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return custom.NoDataWidget(
      message: 'No articles found for "${_searchController.text}"',
      icon: Icons.search_off,
      actionText: 'Try different keywords',
      onAction: () {
        _searchController.clear();
        _searchFocusNode.requestFocus();
      },
    );
  }

  Widget _buildResultsList(SearchResult searchResult) {
    return Column(
      children: [
        // Search header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Found ${searchResult.totalCount} results for "${searchResult.query}"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (searchResult.fromCache)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.offline_bolt,
                        size: 14,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: searchResult.articles.length,
            itemBuilder: (context, index) {
              final article = searchResult.articles[index];
              return CompactNewsCard(
                article: article,
                onTap: () => widget.onArticleTap(article),
              );
            },
          ),
        ),
      ],
    );
  }
}
