import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';

class StreakIndicator extends StatelessWidget {
  final int streak;
  final bool compact;

  const StreakIndicator({
    super.key,
    required this.streak,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();

    final color = streak >= 7 
        ? AppColors.caloriesNeon 
        : streak >= 3 
            ? Colors.orange 
            : AppColors.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: streak >= 3 ? [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: color,
            size: compact ? 16 : 20,
          )
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .scale(
            duration: 1.seconds,
            begin: const Offset(1.0, 1.0),
            end: streak >= 3 ? const Offset(1.2, 1.2) : const Offset(1.0, 1.0),
          )
          .then(delay: 500.ms), // Pause between pulses
          
          SizedBox(width: compact ? 4 : 8),
          
          Text(
            '$streak',
            style: compact 
                ? AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  )
                : AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
          ),
        ],
      ),
    );
  }
}
