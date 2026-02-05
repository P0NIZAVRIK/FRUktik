import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../design_system/colors.dart';
import '../../design_system/spacing.dart';
import '../../design_system/animations.dart';

/// Skeleton loader for food item cards
class FoodItemSkeleton extends StatelessWidget {
  const FoodItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceVariant,
      period: AppAnimations.shimmerDuration,
      child: Container(
        padding: AppSpacing.allMD,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.radiusLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppSpacing.radiusSM,
              ),
            ),
            AppSpacing.verticalSpaceSM,
            // Subtitle
            Container(
              width: 120,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppSpacing.radiusSM,
              ),
            ),
            AppSpacing.verticalSpaceMD,
            // Nutrition info
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.radiusSM,
                    ),
                  ),
                ),
                AppSpacing.horizontalSpaceSM,
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.radiusSM,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for diary entries
class DiaryEntrySkeleton extends StatelessWidget {
  const DiaryEntrySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceVariant,
      period: AppAnimations.shimmerDuration,
      child: Container(
        padding: AppSpacing.allMD,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.radiusLG,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppSpacing.radiusFull,
              ),
            ),
            AppSpacing.horizontalSpaceMD,
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.radiusSM,
                    ),
                  ),
                  AppSpacing.verticalSpaceXS,
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.radiusSM,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.horizontalSpaceMD,
            // Action button
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppSpacing.radiusFull,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic skeleton for lists
class SkeletonListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  const SkeletonListView({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppSpacing.allMD,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
