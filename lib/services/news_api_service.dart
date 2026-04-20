import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  const ApiException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Service class for handling news API requests using HTTP
class NewsApiService {
  static const String _baseUrl = 'https://newsapi.org/v2';
  static const String _apiKey = 'API_KEY';
  final http.Client _client;
  
  NewsApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch top headlines from various sources
  /// [country] - 2-letter ISO 3166-1 country code (default: 'us')
  /// [category] - category of news (business, entertainment, general, health, science, sports, technology)
  /// [pageSize] - number of results per page (max: 100)
  /// [page] - page number for pagination
  Future<List<NewsArticle>> fetchTopHeadlines({
    String country = 'us',
    String? category,
    int pageSize = 20,
    int page = 1,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'apiKey': _apiKey,
        'country': country,
        'pageSize': pageSize.toString(),
        'page': page.toString(),
      };
      
      if (category != null) {
        queryParams['category'] = category;
      }

      final uri = Uri.parse('$_baseUrl/top-headlines').replace(
        queryParameters: queryParams,
      );

      print('DEBUG: Making API request to: $uri');
      print('DEBUG: API Key: ${_apiKey.substring(0, 10)}...');

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> articles = responseData['articles'] ?? [];
        return articles.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? 'Unknown error occurred';
        throw ApiException(message, response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (e.message.contains('Connection refused') ?? false) {
        throw const ApiException('Server is not responding. Please try again later.');
      } else if (e.message.contains('Connection timed out') ?? false) {
        throw const ApiException('Connection timeout. Please check your internet connection.');
      } else if (e.message.contains('No address associated with hostname') ?? false) {
        throw const ApiException('No internet connection. Please check your network settings.');
      } else {
        throw ApiException('Network error: ${e.message}');
      }
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  /// Search for news articles by keyword
  /// [query] - search keywords or phrases
  /// [language] - 2-letter ISO-639-1 language code (default: 'en')
  /// [sortBy] - relevance, popularity, publishedAt (default: 'publishedAt')
  /// [pageSize] - number of results per page (max: 100)
  /// [page] - page number for pagination
  Future<List<NewsArticle>> searchNews({
    required String query,
    String language = 'en',
    String sortBy = 'publishedAt',
    int pageSize = 20,
    int page = 1,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/everything').replace(
        queryParameters: {
          'q': query,
          'apiKey': _apiKey,
          'language': language,
          'sortBy': sortBy,
          'pageSize': pageSize.toString(),
          'page': page.toString(),
        },
      );

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> articles = responseData['articles'] ?? [];
        return articles.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? 'Unknown error occurred';
        throw ApiException(message, response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (e.message?.contains('Connection refused') ?? false) {
        throw const ApiException('Server is not responding. Please try again later.');
      } else if (e.message?.contains('Connection timed out') ?? false) {
        throw const ApiException('Connection timeout. Please check your internet connection.');
      } else if (e.message?.contains('No address associated with hostname') ?? false) {
        throw const ApiException('No internet connection. Please check your network settings.');
      } else {
        throw ApiException('Network error: ${e.message}');
      }
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  /// Dispose of HTTP client
  void dispose() {
    _client.close();
  }
}
