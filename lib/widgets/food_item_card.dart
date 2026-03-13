import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../providers/diary_provider.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/spacing.dart';
import '../design_system/animations.dart';
import '../core/haptics/haptic_manager.dart';
import 'food/food_image.dart';

class FoodItemCard extends StatefulWidget {
  final FoodItem foodItem;

  const FoodItemCard({super.key, required this.foodItem});

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  final TextEditingController _weightController = TextEditingController();
  bool _isHovered = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    HapticManager.light();
    _weightController.text = '100';
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.surface,
                AppColors.surfaceVariant,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppSpacing.radiusXL,
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          padding: AppSpacing.allLG,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                    AppSpacing.horizontalSpaceMD,
                    Expanded(
                      child: Text(
                        widget.foodItem.name,
                        style: AppTypography.headlineSmall,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSpaceLG,
                
                // Nutrition Info
                Container(
                  padding: AppSpacing.allMD,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: AppSpacing.radiusMD,
                    border: Border.all(
                      color: AppColors.glassBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutritionInfo(
                        'Ккал',
                        widget.foodItem.calories.toStringAsFixed(1),
                        AppColors.caloriesNeon,
                      ),
                      _buildNutrientDivider(),
                      _buildNutritionInfo(
                        'Б',
                        widget.foodItem.proteins.toStringAsFixed(1),
                        AppColors.proteinNeon,
                      ),
                      _buildNutrientDivider(),
                      _buildNutritionInfo(
                        'Ж',
                        widget.foodItem.fats.toStringAsFixed(1),
                        AppColors.fatsNeon,
                      ),
                      _buildNutrientDivider(),
                      _buildNutritionInfo(
                        'У',
                        widget.foodItem.carbohydrates.toStringAsFixed(1),
                        AppColors.carbsNeon,
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalSpaceMD,
                
                Text(
                  'На 100 грамм',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                AppSpacing.verticalSpaceMD,
                
                // Weight Input
                TextField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: 'Вес (граммы)',
                    labelStyle: AppTypography.bodyMedium,
                    border: const OutlineInputBorder(
                      borderRadius: AppSpacing.radiusMD,
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: AppSpacing.radiusMD,
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: AppSpacing.radiusMD,
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    prefixIcon: const Icon(Icons.scale),
                  ),
                  keyboardType: TextInputType.number,
                  style: AppTypography.bodyLarge,
                ),
                AppSpacing.verticalSpaceXL,
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      child: Text('Отмена', style: AppTypography.labelLarge),
                    ),
                    AppSpacing.horizontalSpaceMD,
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppSpacing.radiusMD,
                        boxShadow: AppColors.getNeonGlow(AppColors.primary),
                      ),
                      child: ElevatedButton(
                        onPressed: _addToDiary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppSpacing.radiusMD,
                          ),
                        ),
                        child: Text('Добавить', style: AppTypography.labelLarge),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.easeOut)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: AppAnimations.medium,
              curve: AppAnimations.spring,
            ),
      ),
    );
  }

  void _addToDiary() {
    final weight = double.tryParse(_weightController.text);
    if (weight != null && weight > 0) {
      HapticManager.medium();
      context.read<DiaryProvider>().addEntry(widget.foodItem, weight);
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              AppSpacing.horizontalSpaceMD,
              Expanded(
                child: Text(
                  '${widget.foodItem.name} добавлен в дневник',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.successContainer,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.radiusMD,
          ),
        ),
      );
    } else {
      HapticManager.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Введите корректный вес',
            style: AppTypography.bodyMedium,
          ),
          backgroundColor: AppColors.errorContainer,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildNutritionInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        AppSpacing.verticalSpaceXS,
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.glassBorder,
    );
  }

  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: AppAnimations.pressDuration,
          curve: AppAnimations.spring,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.radiusLG,
              boxShadow: _isHovered 
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : AppColors.softShadow,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: AppSpacing.radiusLG,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  // Delay slightly to show ripple
                  Future.delayed(const Duration(milliseconds: 100), () {
                     setState(() => _isPressed = false);
                  });
                  HapticManager.light();
                  _showAddDialog();
                },
                splashColor: AppColors.primary.withValues(alpha: 0.2),
                highlightColor: AppColors.primary.withValues(alpha: 0.1),
                child: Padding(
                  padding: AppSpacing.allMD,
                  child: Row(
                    children: [
                      // Food Image
                      FoodImage(
                        foodItem: widget.foodItem,
                        size: 48,
                        borderRadius: AppSpacing.radiusMD,
                      ),
                      AppSpacing.horizontalSpaceMD,
                      
                      // Food Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.foodItem.name,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.verticalSpaceXS,
                            Row(
                              children: [
                                _buildCompactChip(
                                  '${widget.foodItem.calories.toStringAsFixed(0)} ккал',
                                  AppColors.caloriesNeon,
                                ),
                                AppSpacing.horizontalSpaceXS,
                                _buildCompactChip(
                                  'Б: ${widget.foodItem.proteins.toStringAsFixed(1)}',
                                  AppColors.proteinNeon,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Add Button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.radiusFull,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.radiusSM,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
