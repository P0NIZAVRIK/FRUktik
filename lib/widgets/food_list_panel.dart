import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../data/mock_data.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/spacing.dart';
import '../design_system/animations.dart';
import '../core/haptics/haptic_manager.dart';
import '../models/food_item.dart';
import 'food_item_card.dart';
import 'diary/drag_target_sphere.dart';

class FoodListPanel extends StatefulWidget {
  const FoodListPanel({super.key});

  @override
  State<FoodListPanel> createState() => _FoodListPanelState();
}

class _FoodListPanelState extends State<FoodListPanel> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundPrimary,
            AppColors.backgroundSecondary,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          right: BorderSide(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with search
          Container(
            padding: AppSpacing.allLG,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.glassBorder,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: AppSpacing.allSM,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppSpacing.radiusSM,
                        boxShadow: AppColors.getNeonGlow(AppColors.primary),
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    AppSpacing.horizontalSpaceMD,
                    Text(
                      'Продукты',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSpaceMD,
                
                // Search field with floating animation
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск продуктов...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.radiusMD,
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    contentPadding: AppSpacing.allMD,
                  ),
                  style: AppTypography.bodyMedium,
                  onChanged: (value) {
                    HapticManager.selection();
                    context.read<DiaryProvider>().setSearchQuery(value);
                  },
                )
                    .animate()
                    .fadeIn(duration: AppAnimations.normal)
                    .slideY(begin: -0.2, duration: AppAnimations.medium),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: AppAnimations.normal),
          
          // Food list
          Expanded(
            child: Stack(
              children: [
                Consumer<DiaryProvider>(
                  builder: (context, provider, child) {
                    final query = provider.searchQuery.toLowerCase();
                    final filteredItems = query.isEmpty
                        ? mockFoodItems
                        : mockFoodItems
                            .where((item) =>
                                item.name.toLowerCase().contains(query))
                            .toList();

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                            AppSpacing.verticalSpaceMD,
                            Text(
                              'Продукты не найдены',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate(onPlay: (c) => c.forward())
                          .fadeIn()
                          .scale(begin: const Offset(0.9, 0.9));
                    }

                    return ListView.builder(
                      padding: AppSpacing.allMD,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          key: ValueKey(filteredItems[index].name),
                          padding: EdgeInsets.only(bottom: AppSpacing.md),
                          child: DraggableFoodItem(
                            foodItem: filteredItems[index],
                            onDragStarted: () {
                              setState(() => _isDragging = true);
                            },
                            onDragEnd: () {
                              setState(() => _isDragging = false);
                            },
                            child: FoodItemCard(foodItem: filteredItems[index]),
                          ),
                        );
                      },
                    );
                  },
                ),
                
                // Drag target sphere (appears when dragging)
                if (_isDragging)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DragTargetSphere(
                        size: 120,
                        onFoodAdded: (food, weight) {
                          context.read<DiaryProvider>().addEntry(food, weight);
                          HapticManager.success();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: AppColors.success),
                                  AppSpacing.horizontalSpaceMD,
                                  Expanded(
                                    child: Text(
                                      '${food.name} добавлен!',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.successContainer,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.radiusMD,
                              ),
                            ),
                          );
                        },
                      )
                          .animate()
                          .fadeIn(duration: AppAnimations.fast)
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            duration: AppAnimations.medium,
                            curve: AppAnimations.spring,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Bottom hint
          Container(
            padding: AppSpacing.allMD,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.glassBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                AppSpacing.horizontalSpaceSM,
                Text(
                  'Удерживайте для перетаскивания',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: AppAnimations.slow, delay: AppAnimations.slow),
        ],
      ),
    );
  }
}
