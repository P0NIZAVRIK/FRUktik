import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import '../../providers/diary_provider.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';

class WeeklyChartWidget extends StatelessWidget {
  const WeeklyChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.allLG,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.radiusLG,
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Активность (7 дней)',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.verticalSpaceLG,
          
          SizedBox(
            height: 150,
            child: Consumer<DiaryProvider>(
              builder: (context, provider, child) {
                final data = provider.getLast7DaysCalories();
                final sortedKeys = data.keys.toList()..sort();
                final target = provider.goals.calories;
                
                // Find max for scaling (at least target)
                double maxVal = target;
                for (var val in data.values) {
                  if (val > maxVal) maxVal = val;
                }
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: sortedKeys.map((date) {
                    final value = data[date] ?? 0;
                    final ratio = (value / maxVal).clamp(0.0, 1.0);
                    final isToday = _isToday(date);
                    final isOver = value > target * 1.1;
                    final isTarget = value >= target * 0.9 && value <= target * 1.1;
                    
                    Color barColor = AppColors.primary;
                    if (isTarget) barColor = AppColors.success;
                    if (isOver) barColor = AppColors.warning;
                    if (value == 0) barColor = AppColors.surfaceVariant;
                    
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Value Label (only if significant)
                          if (value > 0)
                            Text(
                              value.toInt().toString(),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 9,
                              ),
                            ),
                          AppSpacing.verticalSpaceXS,
                          
                          // Bar
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: ratio),
                            duration: const Duration(seconds: 1),
                            curve: Curves.elasticOut,
                            builder: (context, val, child) {
                              return Container(
                                height: 100 * val,
                                width: 12,
                                decoration: BoxDecoration(
                                  color: barColor.withValues(alpha: isToday ? 1.0 : 0.7),
                                  borderRadius: AppSpacing.radiusSM,
                                  boxShadow: isToday && value > 0
                                      ? [
                                          BoxShadow(
                                            color: barColor.withValues(alpha: 0.5),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          )
                                        ]
                                      : null,
                                  gradient: value > 0 ? LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      barColor.withValues(alpha: 0.5),
                                      barColor,
                                    ],
                                  ) : null,
                                ),
                              );
                            },
                          ),
                          AppSpacing.verticalSpaceSM,
                          
                          // Weekday Label
                          Text(
                            DateFormat('E', 'ru').format(date).toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: isToday ? AppColors.textPrimary : AppColors.textTertiary,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
