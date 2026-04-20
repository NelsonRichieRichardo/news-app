import '../models/news_article.dart';

/// Filter criteria for news articles
class FilterCriteria {
  final String? category;
  final String? source;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String> keywords;
  final bool onlyWithImages;
  final bool onlyRecent; // Last 24 hours
  final String? sortBy; // publishedAt, relevance, popularity

  const FilterCriteria({
    this.category,
    this.source,
    this.fromDate,
    this.toDate,
    this.keywords = const [],
    this.onlyWithImages = false,
    this.onlyRecent = false,
    this.sortBy,
  });

  /// Create copy with updated values
  FilterCriteria copyWith({
    String? category,
    String? source,
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? keywords,
    bool? onlyWithImages,
    bool? onlyRecent,
    String? sortBy,
  }) {
    return FilterCriteria(
      category: category ?? this.category,
      source: source ?? this.source,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      keywords: keywords ?? this.keywords,
      onlyWithImages: onlyWithImages ?? this.onlyWithImages,
      onlyRecent: onlyRecent ?? this.onlyRecent,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Check if any filter is active
  bool get hasActiveFilters =>
      category != null ||
      source != null ||
      fromDate != null ||
      toDate != null ||
      keywords.isNotEmpty ||
      onlyWithImages ||
      onlyRecent ||
      sortBy != null;

  /// Reset all filters
  FilterCriteria get reset => const FilterCriteria();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterCriteria &&
        other.category == category &&
        other.source == source &&
        other.fromDate == fromDate &&
        other.toDate == toDate &&
        other.keywords == keywords &&
        other.onlyWithImages == onlyWithImages &&
        other.onlyRecent == onlyRecent &&
        other.sortBy == sortBy;
  }

  @override
  int get hashCode {
    return category.hashCode ^
        source.hashCode ^
        fromDate.hashCode ^
        toDate.hashCode ^
        keywords.hashCode ^
        onlyWithImages.hashCode ^
        onlyRecent.hashCode ^
        sortBy.hashCode;
  }

  @override
  String toString() {
    return 'FilterCriteria(category: $category, source: $source, keywords: $keywords)';
  }
}

/// Filter result with metadata
class FilterResult {
  final List<NewsArticle> filteredArticles;
  final FilterCriteria appliedCriteria;
  final int originalCount;
  final int filteredCount;

  const FilterResult({
    required this.filteredArticles,
    required this.appliedCriteria,
    required this.originalCount,
    required this.filteredCount,
  });

  double get filterPercentage => 
      originalCount > 0 ? (filteredCount / originalCount) * 100 : 0;

  @override
  String toString() {
    return 'FilterResult(filtered: $filteredCount/$originalCount, criteria: $appliedCriteria)';
  }
}

/// Service for filtering news articles with business logic separated from UI
class FilterService {
  // Available categories
  static const List<String> availableCategories = [
    'general',
    'business',
    'entertainment',
    'health',
    'science',
    'sports',
    'technology',
  ];

  // Available sort options
  static const List<String> sortOptions = [
    'publishedAt',
    'relevance',
    'popularity',
  ];

  // Common sources (would be populated from actual API data)
  static const List<String> commonSources = [
    'BBC News',
    'CNN',
    'Reuters',
    'The Guardian',
    'The New York Times',
    'TechCrunch',
    'Wired',
  ];

  /// Apply filters to a list of articles
  FilterResult applyFilters(List<NewsArticle> articles, FilterCriteria criteria) {
    final originalCount = articles.length;
    var filteredArticles = List<NewsArticle>.from(articles);

    // Apply category filter
    if (criteria.category != null && criteria.category!.isNotEmpty) {
      filteredArticles = filteredArticles.where((article) {
        // This would ideally use actual category data from the article
        // For now, we'll simulate based on title/content
        final titleLower = article.title?.toLowerCase() ?? '';
        final descLower = article.description?.toLowerCase() ?? '';
        final categoryLower = criteria.category!.toLowerCase();
        
        return titleLower.contains(categoryLower) || 
               descLower.contains(categoryLower);
      }).toList();
    }

    // Apply source filter
    if (criteria.source != null && criteria.source!.isNotEmpty) {
      filteredArticles = filteredArticles.where((article) {
        final articleSource = article.source?.toLowerCase() ?? '';
        final filterSource = criteria.source!.toLowerCase();
        return articleSource.contains(filterSource);
      }).toList();
    }

    // Apply date range filter
    if (criteria.fromDate != null || criteria.toDate != null) {
      filteredArticles = filteredArticles.where((article) {
        if (article.publishedAt == null) return false;
        
        try {
          final articleDate = DateTime.parse(article.publishedAt!);
          
          if (criteria.fromDate != null && articleDate.isBefore(criteria.fromDate!)) {
            return false;
          }
          
          if (criteria.toDate != null && articleDate.isAfter(criteria.toDate!)) {
            return false;
          }
          
          return true;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Apply recent filter (last 24 hours)
    if (criteria.onlyRecent) {
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
      
      filteredArticles = filteredArticles.where((article) {
        if (article.publishedAt == null) return false;
        
        try {
          final articleDate = DateTime.parse(article.publishedAt!);
          return articleDate.isAfter(twentyFourHoursAgo);
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Apply keywords filter
    if (criteria.keywords.isNotEmpty) {
      filteredArticles = filteredArticles.where((article) {
        final titleLower = article.title?.toLowerCase() ?? '';
        final descLower = article.description?.toLowerCase() ?? '';
        final contentLower = article.content?.toLowerCase() ?? '';
        
        return criteria.keywords.any((keyword) {
          final keywordLower = keyword.toLowerCase();
          return titleLower.contains(keywordLower) ||
                 descLower.contains(keywordLower) ||
                 contentLower.contains(keywordLower);
        });
      }).toList();
    }

    // Apply images only filter
    if (criteria.onlyWithImages) {
      filteredArticles = filteredArticles.where((article) {
        return article.urlToImage != null && article.urlToImage!.isNotEmpty;
      }).toList();
    }

    // Apply sorting
    if (criteria.sortBy != null) {
      filteredArticles = _sortArticles(filteredArticles, criteria.sortBy!);
    }

    final filteredCount = filteredArticles.length;

    return FilterResult(
      filteredArticles: filteredArticles,
      appliedCriteria: criteria,
      originalCount: originalCount,
      filteredCount: filteredCount,
    );
  }

  /// Sort articles based on criteria
  List<NewsArticle> _sortArticles(List<NewsArticle> articles, String sortBy) {
    switch (sortBy.toLowerCase()) {
      case 'publishedat':
      case 'published_at':
        return List.from(articles)..sort((a, b) {
          if (a.publishedAt == null && b.publishedAt == null) return 0;
          if (a.publishedAt == null) return 1;
          if (b.publishedAt == null) return -1;
          
          try {
            final dateA = DateTime.parse(a.publishedAt!);
            final dateB = DateTime.parse(b.publishedAt!);
            return dateB.compareTo(dateA); // Newest first
          } catch (e) {
            return 0;
          }
        });
        
      case 'relevance':
        // Sort by relevance (would need actual relevance scores)
        // For now, sort by title length as a proxy
        return List.from(articles)..sort((a, b) {
          final titleA = a.title?.length ?? 0;
          final titleB = b.title?.length ?? 0;
          return titleA.compareTo(titleB);
        });
        
      case 'popularity':
        // Sort by popularity (would need actual popularity metrics)
        // For now, sort by description length as a proxy
        return List.from(articles)..sort((a, b) {
          final descA = a.description?.length ?? 0;
          final descB = b.description?.length ?? 0;
          return descB.compareTo(descA);
        });
        
      default:
        return articles;
    }
  }

  /// Get available sources from articles
  List<String> getAvailableSources(List<NewsArticle> articles) {
    final sources = articles
        .map((article) => article.source)
        .where((source) => source != null && source!.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    
    sources.sort();
    return sources;
  }

  /// Validate filter criteria
  bool validateCriteria(FilterCriteria criteria) {
    // Validate date range
    if (criteria.fromDate != null && criteria.toDate != null) {
      if (criteria.fromDate!.isAfter(criteria.toDate!)) {
        return false;
      }
    }
    
    // Validate keywords
    if (criteria.keywords.any((keyword) => keyword.trim().isEmpty)) {
      return false;
    }
    
    // Validate category
    if (criteria.category != null && 
        criteria.category!.isNotEmpty && 
        !availableCategories.contains(criteria.category!.toLowerCase())) {
      return false;
    }
    
    // Validate sort option
    if (criteria.sortBy != null && 
        !sortOptions.contains(criteria.sortBy!.toLowerCase())) {
      return false;
    }
    
    return true;
  }

  /// Get filter summary for display
  String getFilterSummary(FilterCriteria criteria) {
    final parts = <String>[];
    
    if (criteria.category != null && criteria.category!.isNotEmpty) {
      parts.add('Category: ${criteria.category}');
    }
    
    if (criteria.source != null && criteria.source!.isNotEmpty) {
      parts.add('Source: ${criteria.source}');
    }
    
    if (criteria.keywords.isNotEmpty) {
      parts.add('Keywords: ${criteria.keywords.join(', ')}');
    }
    
    if (criteria.onlyWithImages) {
      parts.add('With images only');
    }
    
    if (criteria.onlyRecent) {
      parts.add('Recent only');
    }
    
    if (criteria.sortBy != null) {
      parts.add('Sort by: ${criteria.sortBy}');
    }
    
    if (criteria.fromDate != null || criteria.toDate != null) {
      final from = criteria.fromDate != null 
          ? '${criteria.fromDate!.day}/${criteria.fromDate!.month}'
          : 'Any';
      final to = criteria.toDate != null 
          ? '${criteria.toDate!.day}/${criteria.toDate!.month}'
          : 'Any';
      parts.add('Date: $from - $to');
    }
    
    return parts.isEmpty ? 'No filters' : parts.join(' | ');
  }
}
