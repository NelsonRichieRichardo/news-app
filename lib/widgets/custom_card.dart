import 'package:flutter/material.dart';

/// Custom card widget with various styles and configurations
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;
  final Color? shadowColor;
  final ShapeBorder? shape;
  final VoidCallback? onTap;
  final bool isClickable;
  final bool showRipple;
  final BorderRadius? borderRadius;
  final Border? border;
  final Clip clipBehavior;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.shadowColor,
    this.shape,
    this.onTap,
    this.isClickable = false,
    this.showRipple = true,
    this.borderRadius,
    this.border,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Card with default styling
  factory CustomCard.defaultStyle({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return CustomCard(
      key: key,
      child: child,
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      isClickable: onTap != null,
    );
  }

  /// Card with elevated styling
  factory CustomCard.elevated({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return CustomCard(
      key: key,
      child: child,
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin ?? const EdgeInsets.all(16),
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      isClickable: onTap != null,
    );
  }

  /// Card with outlined styling
  factory CustomCard.outlined({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? borderColor,
  }) {
    return CustomCard(
      key: key,
      child: child,
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      border: Border.all(color: borderColor ?? Colors.grey[300]!),
      borderRadius: BorderRadius.circular(12),
      isClickable: onTap != null,
    );
  }

  /// Card with gradient background
  factory CustomCard.gradient({
    Key? key,
    required Widget child,
    required Gradient gradient,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return CustomCard(
      key: key,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin ?? const EdgeInsets.all(16),
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      isClickable: onTap != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: border,
        boxShadow: _getBoxShadow(),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (isClickable && onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          splashFactory: showRipple ? InkRipple.splashFactory : NoSplash.splashFactory,
          child: card,
        ),
      );
    }

    return card;
  }

  /// Generate box shadow based on elevation
  List<BoxShadow>? _getBoxShadow() {
    final elevation = this.elevation ?? 2;
    final shadowColor = this.shadowColor ?? Colors.black.withOpacity(0.1);

    if (elevation == 0) return null;

    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: elevation * 2,
        spreadRadius: elevation * 0.5,
        offset: Offset(0, elevation),
      ),
    ];
  }
}

/// Custom card for news articles
class NewsCustomCard extends StatelessWidget {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? source;
  final String? date;
  final VoidCallback? onTap;
  final bool showImage;
  final bool showSource;
  final bool showDate;
  final double? imageHeight;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final TextStyle? sourceStyle;
  final TextStyle? dateStyle;

  const NewsCustomCard({
    super.key,
    this.title,
    this.description,
    this.imageUrl,
    this.source,
    this.date,
    this.onTap,
    this.showImage = true,
    this.showSource = true,
    this.showDate = true,
    this.imageHeight = 200,
    this.titleStyle,
    this.descriptionStyle,
    this.sourceStyle,
    this.dateStyle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard.defaultStyle(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          if (showImage && imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl!,
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Title section
          if (title != null) ...[
            Text(
              title!,
              style: titleStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          
          // Description section
          if (description != null) ...[
            Text(
              description!,
              style: descriptionStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          
          // Metadata section
          if (showSource || showDate)
            Row(
              children: [
                if (showSource && source != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      source!,
                      style: sourceStyle ?? TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (showDate && date != null)
                  Expanded(
                    child: Text(
                      date!,
                      style: dateStyle ?? TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Custom card for statistics/metrics
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).primaryColor;
    
    return CustomCard.elevated(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: cardColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cardColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
