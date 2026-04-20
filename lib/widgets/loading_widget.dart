import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'custom_loading.dart';

/// Custom loading indicator widget (now using CustomLoading)
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final bool showShimmer;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 50.0,
    this.showShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showShimmer)
              Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.surfaceVariant,
                highlightColor: Theme.of(context).colorScheme.surface,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(size! / 2),
                  ),
                ),
              )
            else
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(size! / 2),
                ),
                child: Center(
                  child: Container(
                    width: size! * 0.8,
                    height: size! * 0.8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular((size! * 0.8) / 2),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (message != null) ...[
              Text(
                message!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait a moment...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small loading indicator for inline use (now using CustomLoading)
class SmallLoadingWidget extends StatelessWidget {
  final Color? color;
  final bool showShimmer;

  const SmallLoadingWidget({
    super.key,
    this.color,
    this.showShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomLoading.small(
      color: color,
      showShimmer: showShimmer,
    );
  }
}

/// Loading indicator with shimmer effect (now using CustomLoading)
class ShimmerLoadingWidget extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoadingWidget({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: Opacity(
        opacity: 0.6,
        child: child,
      ),
    );
  }
}
