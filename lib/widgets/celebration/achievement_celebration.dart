import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../core/haptics/haptic_manager.dart';
import '../../providers/diary_provider.dart';

/// Overlay widget for goal achievement celebrations
class AchievementCelebration extends StatefulWidget {
  final Widget child;
  final DiaryProvider provider;
  
  const AchievementCelebration({
    super.key,
    required this.child,
    required this.provider,
  });

  @override
  State<AchievementCelebration> createState() => _AchievementCelebrationState();
}

class _AchievementCelebrationState extends State<AchievementCelebration> {
  late ConfettiController _confettiController;
  String? _currentMessage;
  bool _showBanner = false;
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    
    // Listen for achievements
    widget.provider.onAchievement = _onAchievement;
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    widget.provider.onAchievement = null;
    super.dispose();
  }
  
  void _onAchievement(AchievementType achievement) {
    String message;
    Color color;
    
    switch (achievement) {
      case AchievementType.caloriesGoal:
        message = '🔥 Цель калорий достигнута!';
        color = AppColors.caloriesNeon;
        break;
      case AchievementType.proteinsGoal:
        message = '💪 Цель белков достигнута!';
        color = AppColors.proteinNeon;
        break;
      case AchievementType.fatsGoal:
        message = '🥑 Цель жиров достигнута!';
        color = AppColors.fatsNeon;
        break;
      case AchievementType.carbohydratesGoal:
        message = '🍞 Цель углеводов достигнута!';
        color = AppColors.carbsNeon;
        break;
      case AchievementType.perfectDay:
        message = '🎉 ИДЕАЛЬНЫЙ ДЕНЬ!';
        color = AppColors.primary;
        break;
    }
    
    // Trigger haptic success pattern
    HapticManager.success();
    
    // Show celebration
    setState(() {
      _currentMessage = message;
      _showBanner = true;
    });
    
    // Play confetti
    _confettiController.play();
    
    // Hide after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showBanner = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Confetti from top center
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: 3.14 / 2, // Down
            maxBlastForce: 20,
            minBlastForce: 10,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.2,
            colors: [
              AppColors.proteinNeon,
              AppColors.fatsNeon,
              AppColors.carbsNeon,
              AppColors.caloriesNeon,
              AppColors.primary,
              AppColors.success,
            ],
          ),
        ),
        
        // Achievement banner
        if (_showBanner && _currentMessage != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Container(
              padding: AppSpacing.allLG,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppSpacing.radiusLG,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentMessage!,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 200))
                .slideY(begin: -1, duration: const Duration(milliseconds: 300))
                .then()
                .shimmer(
                  duration: const Duration(milliseconds: 1000),
                  color: Colors.white.withOpacity(0.5),
                ),
          ),
      ],
    );
  }
}
