import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/spacing.dart';
import '../design_system/animations.dart';
import '../core/haptics/haptic_manager.dart';
import 'diary_entry_card.dart';
import 'liquid/liquid_sphere.dart';
import 'diary/drag_target_sphere.dart';

class DiaryPanel extends StatelessWidget {
  const DiaryPanel({super.key});

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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Header
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
            child: Row(
              children: [
                Container(
                  padding: AppSpacing.allSM,
                  decoration: BoxDecoration(
                    gradient: AppColors.caloriesGradient,
                    borderRadius: AppSpacing.radiusSM,
                    boxShadow: AppColors.getNeonGlow(AppColors.caloriesNeon),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                AppSpacing.horizontalSpaceMD,
                Text(
                  'Дневник питания',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: AppSpacing.radiusFull,
                    border: Border.all(
                      color: AppColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    _getTodayDate(),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: AppAnimations.normal),
          
          // Diary entries list
          Expanded(
            child: Consumer<DiaryProvider>(
              builder: (context, provider, child) {
                final entries = provider.todayEntries;
                
                if (entries.isEmpty) {
                  return _buildEmptyState(context, provider);
                }
                
                return Column(
                  children: [
                    // Liquid Sphere showing daily progress
                    Padding(
                      padding: AppSpacing.allLG,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Calories sphere
                          Column(
                            children: [
                              LiquidSphere(
                                currentValue: provider.totalCalories,
                                targetValue: 2000,
                                size: 120,
                              ),
                              AppSpacing.verticalSpaceSM,
                              Text(
                                'Калории',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(duration: AppAnimations.medium)
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                curve: AppAnimations.spring,
                              ),
                        ],
                      ),
                    ),
                    
                    // Divider
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.glassBorder,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    
                    // Entries list header
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Text(
                            'Сегодня съедено',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: AppSpacing.radiusFull,
                            ),
                            child: Text(
                              '${entries.length} записей',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Entries list
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        physics: const BouncingScrollPhysics(),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            key: ValueKey(entries[index].id),
                            padding: EdgeInsets.only(bottom: AppSpacing.md),
                            child: DiaryEntryCard(entry: entries[index]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context, DiaryProvider provider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: AppSpacing.allLG,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppSpacing.verticalSpaceXL,
            
            // Drag target sphere as empty state
            DragTargetSphere(
              size: 140,
              onFoodAdded: (food, weight) {
                provider.addEntry(food, weight);
                HapticManager.success();
              },
            )
                .animate()
                .fadeIn(duration: AppAnimations.medium)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: AppAnimations.slow,
                  curve: AppAnimations.spring,
                ),
            
            AppSpacing.verticalSpaceLG,
            
            Text(
              'Дневник пуст',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.verticalSpaceSM,
            
            Text(
              'Перетащите продукты в тарелку',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            AppSpacing.verticalSpaceXS,
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swipe,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                AppSpacing.horizontalSpaceSM,
                Text(
                  'или нажмите на продукт',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceXL,
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: AppAnimations.slow);
  }

  String _getTodayDate() {
    final now = DateTime.now();
    final months = [
      'Января', 'Февраля', 'Марта', 'Апреля', 'Мая', 'Июня',
      'Июля', 'Августа', 'Сентября', 'Октября', 'Ноября', 'Декабря',
    ];
    return '${now.day} ${months[now.month - 1]}';
  }
}
