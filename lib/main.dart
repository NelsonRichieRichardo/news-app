import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/news_home_screen.dart';
import 'providers/news_provider.dart';
import 'services/news_api_service.dart';

void main() {
  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => NewsProvider(NewsApiService()),
        ),
      ],
      child: MaterialApp(
        title: 'News App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ).copyWith(
            surface: const Color(0xFFF8F9FA),
            surfaceVariant: const Color(0xFFF1F3F4),
            primary: const Color(0xFF1976D2),
            secondary: const Color(0xFF03DAC6),
            tertiary: const Color(0xFF7C4DFF),
            error: const Color(0xFFBA1A1A),
            outline: const Color(0xFF79747E),
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 1,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: TextStyle(
              color: const Color(0xFF1C1B1F),
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.15,
            ),
            iconTheme: const IconThemeData(
              color: Color(0xFF1C1B1F),
              size: 24,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 1,
              shadowColor: Colors.black.withOpacity(0.1),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              color: Color(0xFF1C1B1F),
            ),
            headlineMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              color: Color(0xFF1C1B1F),
            ),
            titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
              color: Color(0xFF1C1B1F),
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
              color: Color(0xFF1C1B1F),
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
              color: Color(0xFF49454F),
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.25,
              color: Color(0xFF49454F),
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.4,
              color: Color(0xFF49454F),
            ),
          ),
        ),
        home: const NewsHomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
