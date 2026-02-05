import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/spacing.dart';
import '../design_system/animations.dart';
import 'animated/animated_components.dart';
import 'liquid/liquid_sphere.dart';

class NutritionSummaryPanel extends StatelessWidget {
  const NutritionSummaryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.allLG,
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
          bottom: BorderSide(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
      ),
      child: Consumer<DiaryProvider>(
        builder: (context, provider, child) {
          // Daily targets (TODO: make these configurable)
          const double targetCalories = 2000.0;
          const double targetProteins = 150.0;
          const double targetFats = 65.0;
          const double targetCarbohydrates = 250.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: AppSpacing.allMD,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppSpacing.radiusMD,
                      boxShadow: AppColors.getNeonGlow(AppColors.primary),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  AppSpacing.horizontalSpaceMD,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Статистика дня',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getTodayDate(),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Daily completion badge
                  _buildCompletionBadge(
                    provider.totalCalories / targetCalories,
                  ),
                ],
              ),
              AppSpacing.verticalSpaceLG,
              
              // Nutrition Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  
                  final cards = [
                    _buildNutritionCard(
                      context,
                      'Калории',
                      provider.totalCalories,
                      targetCalories,
                      'ккал',
                      AppColors.caloriesNeon,
                      Icons.local_fire_department,
                      AppColors.caloriesGradient,
                    ),
                    _buildNutritionCard(
                      context,
                      'Белки',
                      provider.totalProteins,
                      targetProteins,
                      'г',
                      AppColors.proteinNeon,
                      Icons.fitness_center,
                      AppColors.proteinGradient,
                    ),
                    _buildNutritionCard(
                      context,
                      'Жиры',
                      provider.totalFats,
                      targetFats,
                      'г',
                      AppColors.fatsNeon,
                      Icons.water_drop,
                      AppColors.fatsGradient,
                    ),
                    _buildNutritionCard(
                      context,
                      'Углеводы',
                      provider.totalCarbohydrates,
                      targetCarbohydrates,
                      'г',
                      AppColors.carbsNeon,
                      Icons.energy_savings_leaf,
                      AppColors.carbsGradient,
                    ),
                  ];

                  if (isMobile) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: cards[0]),
                            AppSpacing.horizontalSpaceMD,
                            Expanded(child: cards[1]),
                          ],
                        ),
                        AppSpacing.verticalSpaceMD,
                        Row(
                          children: [
                            Expanded(child: cards[2]),
                            AppSpacing.horizontalSpaceMD,
                            Expanded(child: cards[3]),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(child: cards[0]),
                        AppSpacing.horizontalSpaceMD,
                        Expanded(child: cards[1]),
                        AppSpacing.horizontalSpaceMD,
                        Expanded(child: cards[2]),
                        AppSpacing.horizontalSpaceMD,
                        Expanded(child: cards[3]),
                      ],
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompletionBadge(double ratio) {
    final percentage = (ratio * 100).clamp(0, 200).toInt();
    final isComplete = ratio >= 0.9 && ratio <= 1.1;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: isComplete
            ? LinearGradient(
                colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
              )
            : LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
        borderRadius: AppSpacing.radiusFull,
        border: Border.all(
          color: isComplete ? AppColors.success : AppColors.primary,
          width: 2,
        ),
        boxShadow: isComplete
            ? AppColors.getNeonGlow(AppColors.success)
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isComplete)
            Icon(
              Icons.check_circle,
              color: AppColors.textPrimary,
              size: 16,
            ),
          if (isComplete) AppSpacing.horizontalSpaceXS,
          Text(
            '$percentage%',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(
    BuildContext context,
    String label,
    double current,
    double target,
    String unit,
    Color color,
    IconData icon,
    LinearGradient gradient,
  ) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.5) : 0.0;
    final percentageText = (percentage * 100).toStringAsFixed(0);
    final isOverLimit = percentage > 1.1;
    final isOnTrack = percentage >= 0.8 && percentage <= 1.1;

    return Container(
      padding: AppSpacing.allMD,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.radiusLG,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon and Label
          Row(
            children: [
              Container(
                padding: AppSpacing.allSM,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: AppSpacing.radiusSM,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.textPrimary, size: 20),
              ),
              AppSpacing.horizontalSpaceSM,
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpaceMD,
          
          // Current Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedCounter(
                value: current,
                decimals: 1,
                textStyle: AppTypography.numberMedium.copyWith(
                  color: color,
                  shadows: [
                    Shadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              AppSpacing.horizontalSpaceXS,
              Text(
                unit,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          AppSpacing.verticalSpaceXS,
          
          // Target
          Text(
            'из ${target.toStringAsFixed(0)} $unit',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          AppSpacing.verticalSpaceMD,
          
          // Progress Bar
          Stack(
            children: [
              // Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: AppSpacing.radiusFull,
                ),
              ),
              // Filled Progress
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percentage.clamp(0, 1)),
                duration: AppAnimations.slow,
                curve: AppAnimations.easeOut,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: AppSpacing.radiusFull,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          AppSpacing.verticalSpaceSM,
          
          // Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percentageText%',
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isOnTrack)
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 16,
                )
              else if (isOverLimit)
                Icon(
                  Icons.warning,
                  color: AppColors.warning,
                  size: 16,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTodayDate() {
    final now = DateTime.now();
    final months = [
      'Января',
      'Февраля',
      'Марта',
      'Апреля',
      'Мая',
      'Июня',
      'Июля',
      'Августа',
      'Сентября',
      'Октября',
      'Ноября',
      'Декабря',
    ];
    final weekdays = [
      '',
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    
    return '${weekdays[now.weekday]}, ${now.day} ${months[now.month - 1]}';
  }
}
