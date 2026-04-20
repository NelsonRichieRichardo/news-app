import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Custom loading widget with shimmer effect
class CustomLoading extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;
  final double strokeWidth;
  final bool showShimmer;
  final ShimmerDirection shimmerDirection;
  final Color? shimmerBaseColor;
  final Color? shimmerHighlightColor;

  const CustomLoading({
    super.key,
    this.message,
    this.size = 50.0,
    this.color,
    this.strokeWidth = 3.0,
    this.showShimmer = false,
    this.shimmerDirection = ShimmerDirection.ltr,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
  });

  /// Centered loading widget
  factory CustomLoading.centered({
    Key? key,
    String? message,
    double? size,
    Color? color,
    bool showShimmer = false,
  }) {
    return CustomLoading(
      key: key,
      message: message,
      size: size,
      color: color,
      showShimmer: showShimmer,
    );
  }

  /// Small inline loading widget
  factory CustomLoading.small({
    Key? key,
    Color? color,
    double size = 24.0,
    bool showShimmer = false,
  }) {
    return CustomLoading(
      key: key,
      size: size,
      color: color,
      strokeWidth: 2.0,
      showShimmer: showShimmer,
    );
  }

  /// Full screen loading with overlay
  factory CustomLoading.fullScreen({
    Key? key,
    String? message,
    Color? color,
    bool showShimmer = true,
  }) {
    return CustomLoading(
      key: key,
      message: message,
      size: 60.0,
      color: color,
      strokeWidth: 4.0,
      showShimmer: showShimmer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingWidget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            _buildMessage(context),
          ],
        ],
      ),
    );

    if (showShimmer) {
      return Shimmer.fromColors(
        baseColor: shimmerBaseColor ?? Colors.grey[300]!,
        highlightColor: shimmerHighlightColor ?? Colors.grey[100]!,
        direction: shimmerDirection,
        child: loadingWidget,
      );
    }

    return loadingWidget;
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.blue,
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Text(
      message!,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Shimmer placeholder for content
class ShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final ShimmerDirection direction;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.direction = ShimmerDirection.ltr,
    this.baseColor,
    this.highlightColor,
  });

  /// Rectangular placeholder
  factory ShimmerPlaceholder.rectangular({
    Key? key,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return ShimmerPlaceholder(
      key: key,
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }

  /// Circular placeholder
  factory ShimmerPlaceholder.circular({
    Key? key,
    double? size,
  }) {
    return ShimmerPlaceholder(
      key: key,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(1000),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      direction: direction,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Shimmer card placeholder for news articles
class NewsCardShimmer extends StatelessWidget {
  final double? imageHeight;
  final bool showImage;
  final EdgeInsetsGeometry? margin;

  const NewsCardShimmer({
    super.key,
    this.imageHeight = 200,
    this.showImage = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          if (showImage)
            ShimmerPlaceholder.rectangular(
              height: imageHeight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          
          // Content placeholder
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source placeholder
                ShimmerPlaceholder.rectangular(
                  width: 80,
                  height: 20,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 8),
                
                // Title placeholder
                ShimmerPlaceholder.rectangular(
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                ShimmerPlaceholder.rectangular(
                  width: double.infinity * 0.8,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                
                // Description placeholder
                ShimmerPlaceholder.rectangular(
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                ShimmerPlaceholder.rectangular(
                  width: double.infinity * 0.9,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                ShimmerPlaceholder.rectangular(
                  width: double.infinity * 0.7,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                
                // Date placeholder
                ShimmerPlaceholder.rectangular(
                  width: 60,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer list placeholder
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry? padding;

  const ShimmerList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// Shimmer grid placeholder
class ShimmerGrid extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final int itemCount;
  final EdgeInsetsGeometry? padding;

  const ShimmerGrid({
    super.key,
    required this.crossAxisCount,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    required this.itemCount,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return ShimmerPlaceholder.rectangular(
            borderRadius: BorderRadius.circular(8),
          );
        },
      ),
    );
  }
}

/// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final Color? overlayColor;
  final bool showShimmer;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.overlayColor,
    this.showShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor ?? Colors.black.withOpacity(0.3),
            child: CustomLoading.fullScreen(
              message: loadingMessage,
              showShimmer: showShimmer,
            ),
          ),
      ],
    );
  }
}

/// Skeleton loading for different content types
class SkeletonLoader {
  /// News article skeleton
  static Widget newsArticle({EdgeInsetsGeometry? margin}) {
    return NewsCardShimmer(margin: margin);
  }

  /// Profile skeleton
  static Widget profile() {
    return Column(
      children: [
        ShimmerPlaceholder.circular(size: 80),
        const SizedBox(height: 16),
        ShimmerPlaceholder.rectangular(width: 120, height: 20),
        const SizedBox(height: 8),
        ShimmerPlaceholder.rectangular(width: 200, height: 16),
      ],
    );
  }

  /// Stats skeleton
  static Widget stats() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              ShimmerPlaceholder.rectangular(width: 60, height: 24),
              const SizedBox(height: 4),
              ShimmerPlaceholder.rectangular(width: 40, height: 16),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              ShimmerPlaceholder.rectangular(width: 60, height: 24),
              const SizedBox(height: 4),
              ShimmerPlaceholder.rectangular(width: 40, height: 16),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              ShimmerPlaceholder.rectangular(width: 60, height: 24),
              const SizedBox(height: 4),
              ShimmerPlaceholder.rectangular(width: 40, height: 16),
            ],
          ),
        ),
      ],
    );
  }

  /// List skeleton
  static Widget list({
    required int itemCount,
    EdgeInsetsGeometry? padding,
  }) {
    return ShimmerList(
      itemCount: itemCount,
      padding: padding,
      itemBuilder: (context, index) => newsArticle(),
    );
  }

  /// Grid skeleton
  static Widget grid({
    required int crossAxisCount,
    required int itemCount,
    EdgeInsetsGeometry? padding,
  }) {
    return ShimmerGrid(
      crossAxisCount: crossAxisCount,
      itemCount: itemCount,
      padding: padding,
    );
  }
}
