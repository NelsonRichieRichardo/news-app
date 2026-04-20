import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';

/// Widget to display cache information and management options
class CacheInfoWidget extends StatelessWidget {
  const CacheInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, provider, child) {
        // Declare local functions before they are used
        Widget _buildInfoRow(
          BuildContext context,
          String label,
          String value,
          IconData icon,
        ) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        String _formatDateTime(String? dateString) {
          if (dateString == null) return 'Never';
          
          try {
            final date = DateTime.parse(dateString);
            final now = DateTime.now();
            final difference = now.difference(date);

            if (difference.inDays > 0) {
              return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
            } else if (difference.inHours > 0) {
              return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
            } else if (difference.inMinutes > 0) {
              return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
            } else {
              return 'Just now';
            }
          } catch (e) {
            return 'Unknown';
          }
        }

        void _showClearCacheDialog(BuildContext context, NewsProvider provider) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Clear Cache'),
                content: const Text(
                  'Are you sure you want to clear all cached data? This will remove all saved articles and you will need an internet connection to fetch them again.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await provider.clearCache();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All cache cleared'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Clear'),
                  ),
                ],
              );
            },
          );
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: provider.getCacheStats(),
          builder: (context, snapshot) {
            final cacheStats = snapshot.data ?? {
              'cacheEntries': 0,
              'lastUpdated': null,
              'cacheDurationMinutes': 30,
            };

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.storage,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cache Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Cache statistics
                    _buildInfoRow(
                      context,
                      'Cached Items',
                      '${cacheStats['cacheEntries'] ?? 0}',
                      Icons.article_outlined,
                    ),
                    
                    _buildInfoRow(
                      context,
                      'Cache Duration',
                      '${cacheStats['cacheDurationMinutes'] ?? 30} minutes',
                      Icons.timer_outlined,
                    ),
                    
                    if (cacheStats['lastUpdated'] != null)
                      _buildInfoRow(
                        context,
                        'Last Updated',
                        _formatDateTime(cacheStats['lastUpdated']),
                        Icons.update_outlined,
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Cache management buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await provider.clearExpiredCache();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Expired cache cleared'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.cleaning_services, size: 18),
                            label: const Text('Clear Expired'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showClearCacheDialog(context, provider),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Clear All'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }
}

/// Small cache indicator widget for showing cache status
class CacheIndicatorWidget extends StatelessWidget {
  const CacheIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<bool>(
          future: provider.isOnline(),
          builder: (context, snapshot) {
            final isOnline = snapshot.data ?? true;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOnline ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOnline ? Icons.cloud_done : Icons.cloud_off,
                    size: 14,
                    color: isOnline ? Colors.green[700] : Colors.orange[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
