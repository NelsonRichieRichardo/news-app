import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom;
import '../widgets/news_card.dart';

/// Main news screen with search, categories, and articles
class NewsHomeScreen extends StatefulWidget {
  const NewsHomeScreen({super.key});

  @override
  State<NewsHomeScreen> createState() => _NewsHomeScreenState();
}

class _NewsHomeScreenState extends State<NewsHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _categories = [
    'General',
    'Business',
    'Entertainment',
    'Health',
    'Science',
    'Sports',
    'Technology',
  ];
  
  String _selectedCategory = 'General';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize news data
  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().fetchTopHeadlines(category: 'general');
    });
  }

  /// Setup scroll listener for pagination
  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Only trigger loadMore when not at the top (to avoid conflicts with refresh)
      if (_scrollController.position.pixels > 100 &&
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final provider = context.read<NewsProvider>();
        if (provider.hasMore && !provider.isLoading && !provider.hasError) {
          provider.loadMore();
        }
      }
    });
  }

  /// Handle search
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });
    
    context.read<NewsProvider>().searchNews(query, refresh: true);
  }

  
  /// Refresh data
  Future<void> _refreshData() async {
    final provider = context.read<NewsProvider>();
    if (_isSearching) {
      await provider.searchNews(_searchController.text, refresh: true);
    } else {
      await provider.getArticlesByCategory(_selectedCategory.toLowerCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'News Hub',
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: !isSmallScreen,
        actions: [
          if (isTablet)
            Container(
              width: 200,
              margin: const EdgeInsets.only(right: 16),
              child: _buildCategoryDropdown(),
            )
          else
            PopupMenuButton<String>(
              icon: Icon(
                Icons.category_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onSelected: _selectCategoryFromMenu,
              itemBuilder: (context) => _categories.map((category) {
                return PopupMenuItem<String>(
                  value: category,
                  child: Row(
                    children: [
                      if (category == _selectedCategory)
                        Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: _refreshData,
            color: Theme.of(context).colorScheme.primary,
            child: Column(
              children: [
                // Always visible search bar
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: 8,
                  ),
                  child: _buildCompactSearchBar(isSmallScreen),
                ),
                
                // Category dropdown for tablets
                if (isTablet) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCategoryDropdown(),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Header section
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: 8,
                  ),
                  child: _buildResponsiveHeader(isSmallScreen, isTablet),
                ),
                
                // Content area
                Expanded(
                  child: _buildResponsiveContent(provider, isSmallScreen),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build compact search bar (always visible)
  Widget _buildCompactSearchBar(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search news...',
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: isSmallScreen ? 14 : 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: isSmallScreen ? 20 : 24,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: isSmallScreen ? 18 : 24,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearching = false;
                    });
                    context.read<NewsProvider>().fetchTopHeadlines(
                      category: _selectedCategory.toLowerCase(),
                      refresh: true,
                    );
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 10 : 12,
          ),
        ),
        style: Theme.of(context).textTheme.bodyMedium,
        onSubmitted: _performSearch,
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  /// Build category dropdown
  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          items: _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: category == _selectedCategory 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              _selectCategoryFromMenu(newValue);
            }
          },
        ),
      ),
    );
  }

  /// Handle category selection from menu
  void _selectCategoryFromMenu(String category) {
    if (_selectedCategory == category) return;
    
    setState(() {
      _selectedCategory = category;
      _isSearching = false;
      _searchController.clear();
    });
    
    context.read<NewsProvider>().getArticlesByCategory(
      category.toLowerCase(),
    );
  }

  /// Build responsive header
  Widget _buildResponsiveHeader(bool isSmallScreen, bool isTablet) {
    return Consumer<NewsProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Headlines',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 20 : isTablet ? 28 : 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedCategory.isNotEmpty 
                        ? '${_selectedCategory} News' 
                        : 'Latest news from around the world',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: isSmallScreen ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                provider.articles.length.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 10 : 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build responsive content
  Widget _buildResponsiveContent(NewsProvider provider, bool isSmallScreen) {
    print('DEBUG UI: Provider state: ${provider.state.name}');
    print('DEBUG UI: Articles count: ${provider.articles.length}');
    print('DEBUG UI: Is loading: ${provider.isLoading}');
    print('DEBUG UI: Has error: ${provider.hasError}');
    print('DEBUG UI: Error message: ${provider.errorMessage}');
    
    if (provider.state.name == 'idle' && provider.articles.isEmpty) {
      print('DEBUG UI: Showing loading (idle state)');
      return const LoadingWidget(message: 'Loading news...');
    }

    if (provider.isLoading && provider.articles.isEmpty) {
      print('DEBUG UI: Showing loading (loading state)');
      return const LoadingWidget(message: 'Fetching latest news...');
    }

    if (provider.hasError && provider.articles.isEmpty) {
      print('DEBUG UI: Showing error widget');
      return custom.CustomErrorWidget(
        message: provider.errorMessage,
        onRetry: () {
          if (_isSearching) {
            provider.searchNews(_searchController.text, refresh: true);
          } else {
            provider.getArticlesByCategory(_selectedCategory.toLowerCase());
          }
        },
      );
    }

    if (provider.articles.isEmpty) {
      print('DEBUG UI: Showing no data widget');
      return custom.NoDataWidget(
        message: _isSearching
            ? 'No articles found for "${_searchController.text}"'
            : 'No articles available',
        icon: _isSearching ? Icons.search_off : Icons.article_outlined,
        actionText: 'Refresh',
        onAction: _refreshData,
      );
    }
    
    print('DEBUG UI: Showing articles list with ${provider.articles.length} items');

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 16,
        vertical: 8,
      ),
      itemCount: provider.articles.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.articles.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: SmallLoadingWidget()),
          );
        }
        
        final article = provider.articles[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: isSmallScreen ? 8 : 12,
          ),
          child: NewsCard(
            article: article,
            onTap: () {
              // Handle article tap - you could navigate to detail screen
            },
          ),
        );
      },
    );
  }
}