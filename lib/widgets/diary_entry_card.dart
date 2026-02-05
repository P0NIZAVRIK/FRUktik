import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/diary_entry.dart';
import '../providers/diary_provider.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/spacing.dart';
import '../design_system/animations.dart';
import '../core/haptics/haptic_manager.dart';
import 'animated/animated_components.dart';

class DiaryEntryCard extends StatefulWidget {
  final DiaryEntry entry;

  const DiaryEntryCard({super.key, required this.entry});

  @override
  State<DiaryEntryCard> createState() => _DiaryEntryCardState();
}

class _DiaryEntryCardState extends State<DiaryEntryCard> {
  final TextEditingController _weightController = TextEditingController();
  bool _isEditing = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _weightController.text = widget.entry.weight.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    HapticManager.light();
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _updateWeight();
      }
    });
  }

  void _updateWeight() {
    final weight = double.tryParse(_weightController.text);
    if (weight != null && weight > 0) {
      HapticManager.medium();
      context.read<DiaryProvider>().updateEntryWeight(widget.entry.id, weight);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              AppSpacing.horizontalSpaceMD,
              Text(
                'Вес обновлен',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.successContainer,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _weightController.text = widget.entry.weight.toStringAsFixed(0);
    }
  }

  void _confirmDelete() {
    HapticManager.light();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusXL,
        ),
        title: Text(
          'Удалить запись?',
          style: AppTypography.headlineSmall,
        ),
        content: Text(
          'Вы уверены, что хотите удалить "${widget.entry.foodItem.name}" из дневника?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticManager.heavy();
              context.read<DiaryProvider>().removeEntry(widget.entry.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text('Удалить', style: AppTypography.labelLarge),
          ),
        ],
      )
          .animate()
          .fadeIn(duration: AppAnimations.fast)
          .scale(duration: AppAnimations.medium, curve: AppAnimations.spring),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SpringCard(
        borderRadius: AppSpacing.radiusLG,
        backgroundColor: AppColors.surface,
        padding: AppSpacing.allLG,
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : AppColors.softShadow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Food Icon with gradient
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _getNutritionGradient(),
                    borderRadius: AppSpacing.radiusMD,
                    boxShadow: AppColors.getNeonGlow(_getPrimaryNutrientColor()),
                  ),
                  child: Icon(
                    _getFoodIcon(),
                    color: AppColors.textPrimary,
                    size: 28,
                  ),
                ),
                AppSpacing.horizontalSpaceMD,
                
                // Food Name & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.foodItem.name,
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.verticalSpaceXS,
                      Text(
                        _formatTime(widget.entry.date),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.check_circle : Icons.edit,
                    color: _isEditing ? AppColors.success : AppColors.primary,
                  ),
                  onPressed: _toggleEdit,
                  tooltip: _isEditing ? 'Сохранить' : 'Редактировать',
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: _confirmDelete,
                  tooltip: 'Удалить',
                ),
              ],
            ),
            AppSpacing.verticalSpaceMD,
            
            // Divider
            Container(
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
            AppSpacing.verticalSpaceMD,
            
            // Weight and Nutrition Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weight section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вес',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    AppSpacing.verticalSpaceXS,
                    if (_isEditing)
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _weightController,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: AppSpacing.allSM,
                            suffix: Text(
                              'г',
                              style: AppTypography.labelSmall,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppSpacing.radiusSM,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onSubmitted: (_) => _toggleEdit(),
                          style: AppTypography.titleMedium,
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.2),
                              AppColors.primary.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: AppSpacing.radiusSM,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${widget.entry.weight.toStringAsFixed(0)} г',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.horizontalSpaceXL,
                
                // Nutrition grid
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _buildNutritionBadge(
                        'К',
                        widget.entry.calories,
                        'ккал',
                        AppColors.caloriesNeon,
                      ),
                      _buildNutritionBadge(
                        'Б',
                        widget.entry.proteins,
                        'г',
                        AppColors.proteinNeon,
                      ),
                      _buildNutritionBadge(
                        'Ж',
                        widget.entry.fats,
                        'г',
                        AppColors.fatsNeon,
                      ),
                      _buildNutritionBadge(
                        'У',
                        widget.entry.carbohydrates,
                        'г',
                        AppColors.carbsNeon,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: AppAnimations.normal, curve: AppAnimations.easeOut)
          .slideX(
            begin: 0.1,
            end: 0,
            duration: AppAnimations.medium,
            curve: AppAnimations.spring,
          ),
    );
  }

  Widget _buildNutritionBadge(
    String label,
    double value,
    String unit,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.radiusSM,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.horizontalSpaceXS,
          AnimatedCounter(
            value: value,
            decimals: 1,
            textStyle: AppTypography.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          Text(
            unit,
            style: AppTypography.labelSmall.copyWith(
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getNutritionGradient() {
    final protein = widget.entry.proteins;
    final fats = widget.entry.fats;
    final carbs = widget.entry.carbohydrates;

    if (protein > fats && protein > carbs) {
      return AppColors.proteinGradient;
    } else if (fats > protein && fats > carbs) {
      return AppColors.fatsGradient;
    } else if (carbs > protein && carbs > fats) {
      return AppColors.carbsGradient;
    }
    return AppColors.caloriesGradient;
  }

  Color _getPrimaryNutrientColor() {
    final protein = widget.entry.proteins;
    final fats = widget.entry.fats;
    final carbs = widget.entry.carbohydrates;

    if (protein > fats && protein > carbs) return AppColors.proteinNeon;
    if (fats > protein && fats > carbs) return AppColors.fatsNeon;
    if (carbs > protein && carbs > fats) return AppColors.carbsNeon;
    return AppColors.caloriesNeon;
  }

  IconData _getFoodIcon() {
    final protein = widget.entry.proteins;
    final carbs = widget.entry.carbohydrates;

    if (protein > 10) return Icons.fitness_center;
    if (carbs > 20) return Icons.grain;
    return Icons.local_dining;
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
