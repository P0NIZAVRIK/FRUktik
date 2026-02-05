import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/food_item.dart';
import '../../design_system/colors.dart';
import '../../design_system/spacing.dart';

/// Premium food image widget with shimmer loading and OLED optimization
class FoodImage extends StatelessWidget {
  final FoodItem foodItem;
  final double size;
  final BorderRadius? borderRadius;
  
  const FoodImage({
    super.key,
    required this.foodItem,
    this.size = 56,
    this.borderRadius,
  });
  
  /// Get category-specific gradient for fallback
  static Gradient getCategoryGradient(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return AppColors.carbsGradient;
      case 'vegetables':
        return AppColors.proteinGradient;
      case 'meat':
      case 'protein':
        return LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'dairy':
        return LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'grains':
        return LinearGradient(
          colors: [Color(0xFF8D6E63), Color(0xFFA1887F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppColors.primaryGradient;
    }
  }
  
  /// Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return Icons.apple;
      case 'vegetables':
        return Icons.eco;
      case 'meat':
      case 'protein':
        return Icons.restaurant;
      case 'dairy':
        return Icons.water_drop;
      case 'grains':
        return Icons.grain;
      case 'sweets':
        return Icons.cake;
      case 'drinks':
        return Icons.local_drink;
      default:
        return Icons.restaurant_menu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSpacing.radiusMD;
    
    if (foodItem.imageUrl != null && foodItem.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: foodItem.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildShimmerPlaceholder(radius),
          errorWidget: (context, url, error) => _buildFallbackIcon(radius),
          fadeInDuration: const Duration(milliseconds: 300),
          fadeOutDuration: const Duration(milliseconds: 100),
        ),
      );
    }
    
    return _buildFallbackIcon(radius);
  }
  
  Widget _buildShimmerPlaceholder(BorderRadius radius) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceVariant,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
        ),
      ),
    );
  }
  
  Widget _buildFallbackIcon(BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: getCategoryGradient(foodItem.category),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        getCategoryIcon(foodItem.category),
        color: Colors.white.withOpacity(0.9),
        size: size * 0.5,
      ),
    );
  }
}

/// Compact food image for list items
class FoodImageSmall extends StatelessWidget {
  final FoodItem foodItem;
  
  const FoodImageSmall({super.key, required this.foodItem});

  @override
  Widget build(BuildContext context) {
    return FoodImage(
      foodItem: foodItem,
      size: 48,
      borderRadius: AppSpacing.radiusSM,
    );
  }
}

/// Large food image for details/dialogs
class FoodImageLarge extends StatelessWidget {
  final FoodItem foodItem;
  
  const FoodImageLarge({super.key, required this.foodItem});

  @override
  Widget build(BuildContext context) {
    return FoodImage(
      foodItem: foodItem,
      size: 120,
      borderRadius: AppSpacing.radiusLG,
    );
  }
}
