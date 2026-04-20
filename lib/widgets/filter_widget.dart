import 'package:flutter/material.dart';
import '../services/filter_service.dart';
import '../models/news_article.dart';

/// Filter widget with UI separated from business logic
class FilterWidget extends StatefulWidget {
  final List<NewsArticle> articles;
  final Function(FilterResult) onFilterApplied;
  final FilterCriteria? initialCriteria;

  const FilterWidget({
    super.key,
    required this.articles,
    required this.onFilterApplied,
    this.initialCriteria,
  });

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  late FilterService _filterService;
  late FilterCriteria _criteria;
  late TextEditingController _keywordController;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _filterService = FilterService();
    _criteria = widget.initialCriteria ?? const FilterCriteria();
    _keywordController = TextEditingController();
    
    // Initialize keyword controller if keywords exist
    if (_criteria.keywords.isNotEmpty) {
      _keywordController.text = _criteria.keywords.join(', ');
    }
    
    // Initialize dates
    _fromDate = _criteria.fromDate;
    _toDate = _criteria.toDate;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  /// Apply filters and notify parent
  void _applyFilters() {
    // Parse keywords
    final keywords = _keywordController.text
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();

    // Create updated criteria
    final updatedCriteria = _criteria.copyWith(
      fromDate: _fromDate,
      toDate: _toDate,
      keywords: keywords,
    );

    // Validate criteria
    if (!_filterService.validateCriteria(updatedCriteria)) {
      _showValidationError();
      return;
    }

    // Apply filters
    final result = _filterService.applyFilters(widget.articles, updatedCriteria);
    widget.onFilterApplied(result);
  }

  /// Reset all filters
  void _resetFilters() {
    setState(() {
      _criteria = const FilterCriteria();
      _keywordController.clear();
      _fromDate = null;
      _toDate = null;
    });
    
    // Apply reset (no filters)
    final result = _filterService.applyFilters(widget.articles, _criteria);
    widget.onFilterApplied(result);
  }

  /// Show validation error
  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid filter settings. Please check your criteria.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Select date range
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Filter content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category filter
                  _buildCategoryFilter(),
                  const SizedBox(height: 16),
                  
                  // Source filter
                  _buildSourceFilter(),
                  const SizedBox(height: 16),
                  
                  // Date range filter
                  _buildDateRangeFilter(),
                  const SizedBox(height: 16),
                  
                  // Keywords filter
                  _buildKeywordsFilter(),
                  const SizedBox(height: 16),
                  
                  // Boolean filters
                  _buildBooleanFilters(),
                  const SizedBox(height: 16),
                  
                  // Sort options
                  _buildSortOptions(),
                  const SizedBox(height: 24),
                  
                  // Filter summary
                  _buildFilterSummary(),
                ],
              ),
            ),
          ),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          const Expanded(
            child: Text(
              'Filter Articles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: FilterService.availableCategories.map((category) {
            final isSelected = _criteria.category == category;
            return FilterChip(
              label: Text(category.capitalize()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _criteria = _criteria.copyWith(
                    category: selected ? category : null,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSourceFilter() {
    final availableSources = _filterService.getAvailableSources(widget.articles);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Source',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _criteria.source,
          decoration: const InputDecoration(
            hintText: 'Select source',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Sources')),
            ...availableSources.map((source) {
              return DropdownMenuItem(
                value: source,
                child: Text(source),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _criteria = _criteria.copyWith(source: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fromDate != null && _toDate != null
                        ? '${_fromDate!.day}/${_fromDate!.month} - ${_toDate!.day}/${_toDate!.month}'
                        : 'Select date range',
                    style: TextStyle(
                      color: _fromDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                if (_fromDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keywords',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _keywordController,
          decoration: const InputDecoration(
            hintText: 'Enter keywords separated by commas',
            border: OutlineInputBorder(),
            helperText: 'e.g., technology, innovation, startup',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildBooleanFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Filters',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Only with images'),
          value: _criteria.onlyWithImages,
          onChanged: (value) {
            setState(() {
              _criteria = _criteria.copyWith(onlyWithImages: value ?? false);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Recent articles (last 24 hours)'),
          value: _criteria.onlyRecent,
          onChanged: (value) {
            setState(() {
              _criteria = _criteria.copyWith(onlyRecent: value ?? false);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: FilterService.sortOptions.map((sortOption) {
            final isSelected = _criteria.sortBy == sortOption;
            return FilterChip(
              label: Text(sortOption.capitalize()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _criteria = _criteria.copyWith(
                    sortBy: selected ? sortOption : null,
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterSummary() {
    final summary = _filterService.getFilterSummary(_criteria);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary,
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetFilters,
              child: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
